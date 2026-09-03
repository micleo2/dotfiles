pragma Singleton

import QtQuick
import Quickshell

// Readline's editing keys for a TextInput. A view calls handle() from its
// own Keys.onPressed after its own bindings, so the app's keys win where
// they collide; anything not taken here falls through to the TextInput,
// which already knows Ctrl+Left/Right, Ctrl+Backspace/Delete and Home/End.
//
// Ctrl+A/E, Ctrl+B/F, Alt+B/F move; Ctrl+H/D, Ctrl+U/K, Ctrl+W,
// Alt+Backspace, Alt+D kill; Ctrl+Y yanks the last kill.
Singleton {
    id: root

    property string killed: ""

    // Readline's Ctrl+W (unix-word-rubout) stops at whitespace; its Alt+B/F
    // and Alt+Backspace/Alt+D stop at alphanumeric runs. That is why both
    // kinds exist: in `2*sin(x)+1`, Ctrl+W kills the whole expression and
    // Alt+Backspace kills only the `1`.
    function wordStart(text, pos, unix) {
        var word = unix ? /\S/ : /[A-Za-z0-9]/;
        var i = pos;
        while (i > 0 && !word.test(text.charAt(i - 1)))
            i--;
        while (i > 0 && word.test(text.charAt(i - 1)))
            i--;
        return i;
    }

    function wordEnd(text, pos) {
        var word = /[A-Za-z0-9]/;
        var i = pos;
        while (i < text.length && !word.test(text.charAt(i)))
            i++;
        while (i < text.length && word.test(text.charAt(i)))
            i++;
        return i;
    }

    function kill(input, a, b) {
        if (a >= b)
            return;
        root.killed = input.text.slice(a, b);
        input.remove(a, b);
        input.cursorPosition = a;
    }

    function handle(input, event) {
        var ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        var alt = (event.modifiers & Qt.AltModifier) !== 0;
        if (ctrl === alt)
            return false;
        var text = input.text;
        var pos = input.cursorPosition;
        var key = event.key;
        if (ctrl) {
            switch (key) {
            case Qt.Key_A:
                input.cursorPosition = 0;
                break;
            case Qt.Key_E:
                input.cursorPosition = text.length;
                break;
            case Qt.Key_B:
                input.cursorPosition = Math.max(0, pos - 1);
                break;
            case Qt.Key_F:
                input.cursorPosition = Math.min(text.length, pos + 1);
                break;
            case Qt.Key_H:
                if (pos > 0)
                    input.remove(pos - 1, pos);
                break;
            case Qt.Key_D:
                if (pos < text.length)
                    input.remove(pos, pos + 1);
                break;
            case Qt.Key_U:
                root.kill(input, 0, pos);
                break;
            case Qt.Key_K:
                root.kill(input, pos, text.length);
                break;
            case Qt.Key_W:
                root.kill(input, root.wordStart(text, pos, true), pos);
                break;
            case Qt.Key_Y:
                if (root.killed.length > 0) {
                    input.insert(pos, root.killed);
                    input.cursorPosition = pos + root.killed.length;
                }
                break;
            default:
                return false;
            }
        } else {
            switch (key) {
            case Qt.Key_B:
                input.cursorPosition = root.wordStart(text, pos, false);
                break;
            case Qt.Key_F:
                input.cursorPosition = root.wordEnd(text, pos);
                break;
            case Qt.Key_Backspace:
                root.kill(input, root.wordStart(text, pos, false), pos);
                break;
            case Qt.Key_D:
                root.kill(input, pos, root.wordEnd(text, pos));
                break;
            default:
                return false;
            }
        }
        return true;
    }
}

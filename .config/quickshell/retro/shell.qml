//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// NOTE: CHANGE THESE IF YOU WANT TO USE A DIFFERENT ICON THEME:
//@ pragma IconTheme RetroismIcons
//@ pragma Env QS_ICON_THEME=RetroismIcons

import QtQuick
import Quickshell
import "taskbar" as Taskbar
import "osd" as Osd
import "submap" as Submap
import "notifications" as Notifications_
import "lock" as Lock_
import "calc" as Calc
import "launcher" as Launcher_
import "keymap" as Keymap_
import "background" as Background_

Scope {
    id: root

    Background_.Background {}

    Taskbar.Bar {}

    Osd.LcdOsd {}

    Submap.SubmapOverlay {}

    Notifications_.Toasts {}

    // A singleton loads on first reference, and the only other reader of
    // Ntfy is the bell, which can be switched off; the stream runs regardless.
    readonly property bool ntfy: Notifications_.Ntfy.configured

    Lock_.LockScreen {}

    Calc.CalcOverlay {}

    Launcher_.LauncherOverlay {}

    Keymap_.KeymapOverlay {}
}

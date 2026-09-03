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

Scope {
    id: root

    FontLoader {
        id: fontCharcoal

        source: "fonts/Charcoal.ttf"
    }

    Taskbar.Bar {}

    Osd.LcdOsd {}

    Submap.SubmapOverlay {}

    Notifications_.Toasts {}

    Lock_.LockScreen {}

    Calc.CalcOverlay {}
}

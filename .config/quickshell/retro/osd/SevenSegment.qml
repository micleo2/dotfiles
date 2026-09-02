import QtQuick
import ".."

// One seven-segment LCD digit built from rectangles. -1 blanks it; every
// segment is still drawn as a ghost, which is what an LCD does.
//
//      a
//    f   b
//      g
//    e   c
//      d
Item {
    id: root

    property int digit: -1
    property real ghost: 0.12
    property int thickness: 5

    readonly property var table: [[1, 1, 1, 1, 1, 1, 0], [0, 1, 1, 0, 0, 0, 0], [1, 1, 0, 1, 1, 0, 1], [1, 1, 1, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 1], [1, 0, 1, 1, 0, 1, 1], [1, 0, 1, 1, 1, 1, 1], [1, 1, 1, 0, 0, 0, 0], [1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 0, 1, 1]]

    readonly property real t: root.thickness
    readonly property real half: (root.height - root.t) / 2

    implicitWidth: 22
    implicitHeight: 40

    function lit(segment) {
        if (root.digit < 0 || root.digit > 9)
            return root.ghost;
        return root.table[root.digit][segment] === 1 ? 1 : root.ghost;
    }

    Rectangle { // a
        x: root.t
        y: 0
        width: root.width - 2 * root.t
        height: root.t
        color: Config.colors.text
        opacity: root.lit(0)
    }

    Rectangle { // b
        x: root.width - root.t
        y: root.t
        width: root.t
        height: root.half - root.t
        color: Config.colors.text
        opacity: root.lit(1)
    }

    Rectangle { // c
        x: root.width - root.t
        y: root.half + root.t
        width: root.t
        height: root.half - root.t
        color: Config.colors.text
        opacity: root.lit(2)
    }

    Rectangle { // d
        x: root.t
        y: root.height - root.t
        width: root.width - 2 * root.t
        height: root.t
        color: Config.colors.text
        opacity: root.lit(3)
    }

    Rectangle { // e
        x: 0
        y: root.half + root.t
        width: root.t
        height: root.half - root.t
        color: Config.colors.text
        opacity: root.lit(4)
    }

    Rectangle { // f
        x: 0
        y: root.t
        width: root.t
        height: root.half - root.t
        color: Config.colors.text
        opacity: root.lit(5)
    }

    Rectangle { // g
        x: root.t
        y: root.half
        width: root.width - 2 * root.t
        height: root.t
        color: Config.colors.text
        opacity: root.lit(6)
    }
}

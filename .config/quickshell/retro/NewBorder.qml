import QtQuick

Rectangle {

    property bool commonBorder: true

    property int lBorderwidth: 1
    property int rBorderwidth: 1
    property int tBorderwidth: 1
    property int bBorderwidth: 1

    property int commonBorderWidth: 1
    property int zValue: -1

    z: zValue

    property string borderColor: "white"
    property Gradient borderGradient

    color: "transparent"
    border.color: borderColor
    border.width: commonBorderWidth

    gradient: borderGradient != null ? borderGradient : null

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        bottom: parent.bottom

        topMargin: commonBorder ? -commonBorderWidth : -tBorderwidth
        bottomMargin: commonBorder ? -commonBorderWidth : -bBorderwidth
        leftMargin: commonBorder ? -commonBorderWidth : -lBorderwidth
        rightMargin: commonBorder ? -commonBorderWidth : -rBorderwidth
    }
}

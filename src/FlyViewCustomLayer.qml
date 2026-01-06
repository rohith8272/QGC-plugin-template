/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import Custom.Widgets

Item {
    id: customOverlayRoot
    property var parentToolInsets                       // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _totalToolInsets    // The insets updated for the custom overlay additions
    property var mapControl

    readonly property string noGPS:         qsTr("NO GPS")
    readonly property real   indicatorValueWidth:   ScreenTools.defaultFontPixelWidth * 7

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   _indicatorDiameter:     ScreenTools.defaultFontPixelWidth * 18
    property real   _indicatorsHeight:      ScreenTools.defaultFontPixelHeight
    property var    _sepColor:              qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(0,0,0,0.5) : Qt.rgba(1,1,1,0.5)
    property color  _indicatorsColor:       qgcPal.text
    property bool   _isVehicleGps:          _activeVehicle ? _activeVehicle.gps.count.rawValue > 1 && _activeVehicle.gps.hdop.rawValue < 1.4 : false
    property string _altitude:              _activeVehicle ? (isNaN(_activeVehicle.altitudeRelative.value) ? "0.0" : _activeVehicle.altitudeRelative.value.toFixed(1)) + ' ' + _activeVehicle.altitudeRelative.units : "0.0"
    property string _distanceStr:           isNaN(_distance) ? "0" : _distance.toFixed(0) + ' ' + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property real   _distance:              _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property string _messageTitle:          ""
    property string _messageText:           ""
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75

    function secondsToHHMMSS(timeS) {
        var sec_num = parseInt(timeS, 10);
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
        var seconds = sec_num - (hours * 3600) - (minutes * 60);
        if (hours   < 10) {hours   = "0"+hours;}
        if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        return hours+':'+minutes+':'+seconds;
    }

QGCToolInsets {
    id: _totalToolInsets

    leftEdgeTopInset: parentToolInsets.leftEdgeTopInset

    leftEdgeCenterInset: Math.max(
        parentToolInsets.leftEdgeCenterInset,
        mapMarkerWidget.visible      ? mapMarkerWidget.x + mapMarkerWidget.width : 0,
        paramWidget.visible          ? paramWidget.x + paramWidget.width : 0,
        dataWidget.visible           ? dataWidget.x + dataWidget.width : 0
    )

    leftEdgeBottomInset: parentToolInsets.bottomEdgeLeftInset

    rightEdgeTopInset:    parentToolInsets.rightEdgeTopInset
    rightEdgeCenterInset: parentToolInsets.rightEdgeCenterInset
    rightEdgeBottomInset: parent.width - compassBackground.x

    topEdgeLeftInset:   parentToolInsets.topEdgeLeftInset
    topEdgeCenterInset: compassArrowIndicator.y + compassArrowIndicator.height
    topEdgeRightInset:  parentToolInsets.topEdgeRightInset

    bottomEdgeLeftInset:   parentToolInsets.bottomEdgeLeftInset
    bottomEdgeCenterInset: parentToolInsets.bottomEdgeCenterInset
    bottomEdgeRightInset:  parent.height - attitudeIndicator.y
}

    // This is an example of how you can use parent tool insets to position an element on the custom fly view layer
    // - we use parent topEdgeLeftInset to position the widget below the toolstrip
    // - we use parent bottomEdgeLeftInset to dodge the virtual joystick if enabled
    // - we use the parent leftEdgeTopInset to size our element to the same width as the ToolStripAction
    // - we export the width of this element as the leftEdgeCenterInset so that the map will recenter if the vehicle flys behind this element
    Rectangle {
        id: exampleRectangle
        visible: false // to see this example, set this to true. To view insets, enable the insets viewer FlyView.qml
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: parentToolInsets.topEdgeLeftInset + _toolsMargin
        anchors.bottomMargin: parentToolInsets.bottomEdgeLeftInset + 4*_toolsMargin
        anchors.leftMargin: _toolsMargin
        width: parentToolInsets.leftEdgeTopInset +100 //- _toolsMargin
        color: 'red'

        property real leftEdgeCenterInset: visible ? x + width : 0
    }

    Rectangle { // Changed Rectangle2 to Rectangle, assuming it's a standard QML Rectangle
        id: exampleRectangle2
        visible: false // to see this example, set this to true. To view insets, enable the insets viewer FlyView.qml
        anchors.left: exampleRectangle.right // Anchor to the right of exampleRectangle
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: parentToolInsets.topEdgeLeftInset + _toolsMargin
        anchors.bottomMargin: parentToolInsets.bottomEdgeLeftInset + 4*_toolsMargin
        anchors.leftMargin: _toolsMargin // This will add spacing between exampleRectangle and exampleRectangle2
        width: parentToolInsets.leftEdgeTopInset + 100
        color: 'blue' // Changed color to distinguish it

        // If exampleRectangle2 also defines an inset, its calculation needs to consider its position.
        // This assumes exampleRectangle2 is also contributing to the left-center inset of the *overall* view.
        property real leftEdgeCenterInset: visible ? x + width : 0
}

    

    // -- GeoFence Toggle Switch 
    // ---------------------------------------------------------
    /*
    Rectangle {
        id:                 fencePanel
        visible:            false 
        
        // 1. POSITIONING: Fix anchors for BOTTOM LEFT
        anchors.left:       parent.left
        anchors.bottom:     parent.bottom
        // Use bottomEdgeLeftInset to dodge the virtual joystick/toolbar
        anchors.bottomMargin: parentToolInsets.bottomEdgeLeftInset + _toolsMargin
        anchors.leftMargin:   _toolsMargin
        
        // Size and Style
        width:              100
        height:             60
        color:              qgcPal.windowShade
        radius:             4
        border.color:       qgcPal.text
        border.width:       1

        // 2. LOGIC: Define the parameter property HERE (not inside onClicked)
        // Note: Change "FENCE_ENABLE" to "GF_ACTION" if using PX4
        property var fenceParam: _activeVehicle ? _activeVehicle.parameterManager.getParameter(-1, "GF_ACTION") : null

        ColumnLayout {
            anchors.centerIn: parent
            spacing:          2

            QGCLabel {
                text:               "FENCE"
                font.pointSize:     ScreenTools.smallFontPointSize
                Layout.alignment:   Qt.AlignHCenter
                color:              qgcPal.text
            }

            Switch {
                id:                 fenceSwitch
                Layout.alignment:   Qt.AlignHCenter
                
                // 3. BINDING: Connect switch state to the parameter
                // If the param exists and equals 1, switch is ON.
                checked:            parent.fenceParam ? parent.fenceParam.value === 1 : false

                onClicked: {
                    if (parent.fenceParam) {
                        // Toggle logic: If currently 1, set to 0. Else set to 1.
                        parent.fenceParam.value = (checked ? 1 : 0)
                        console.log("Fence set to:", parent.fenceParam.value)
                    } else {
                        console.log("Error: Fence parameter not found")
                        // Reset switch if param is missing
                        checked = false 
                    }
                }
            }
        }

        // Layout Helper: Update this to use 'bottomEdge' properties since we moved it
        property real bottomEdgeLeftInset: visible ? y : parent.height
    }
*/

    //-------------------------------------------------------------------------
    //-- Heading Indicator
    Rectangle {
        id:                         compassBar
        height:                     ScreenTools.defaultFontPixelHeight * 1.5
        width:                      ScreenTools.defaultFontPixelWidth  * 50
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       _toolsMargin
        color:                      "#DEDEDE"
        radius:                     2
        clip:                       true
        anchors.horizontalCenter:   parent.horizontalCenter
        Repeater {
            model: 720
            QGCLabel {
                function _normalize(degrees) {
                    var a = degrees % 360
                    if (a < 0) a += 360
                    return a
                }
                property int _startAngle: modelData + 180 + _heading
                property int _angle: _normalize(_startAngle)
                anchors.verticalCenter: parent.verticalCenter
                x:              visible ? ((modelData * (compassBar.width / 360)) - (width * 0.5)) : 0
                visible:        _angle % 45 == 0
                color:          "#75505565"
                font.pointSize: ScreenTools.smallFontPointSize
                text: {
                    switch(_angle) {
                    case 0:     return "N"
                    case 45:    return "NE"
                    case 90:    return "E"
                    case 135:   return "SE"
                    case 180:   return "S"
                    case 225:   return "SW"
                    case 270:   return "W"
                    case 315:   return "NW"
                    }
                    return ""
                }
            }
        }
    }
    Rectangle {
        id:                         headingIndicator
        height:                     ScreenTools.defaultFontPixelHeight
        width:                      ScreenTools.defaultFontPixelWidth * 4
        color:                      qgcPal.windowShadeDark
        anchors.top:                compassBar.top
        anchors.topMargin:          -headingIndicator.height / 2
        anchors.horizontalCenter:   parent.horizontalCenter
        QGCLabel {
            text:                   _heading
            color:                  qgcPal.text
            font.pointSize:         ScreenTools.smallFontPointSize
            anchors.centerIn:       parent
        }
    }
    Image {
        id:                         compassArrowIndicator
        height:                     _indicatorsHeight
        width:                      height
        source:                     "/custom/img/compass_pointer.svg"
        fillMode:                   Image.PreserveAspectFit
        sourceSize.height:          height
        anchors.top:                compassBar.bottom
        anchors.topMargin:          -height / 2
        anchors.horizontalCenter:   parent.horizontalCenter
    }

    Rectangle {
        id:                     compassBackground
        anchors.bottom:         attitudeIndicator.bottom
        anchors.right:          attitudeIndicator.left
        anchors.rightMargin:    -attitudeIndicator.width / 2
        width:                  -anchors.rightMargin + compassBezel.width + (_toolsMargin * 2)
        height:                 attitudeIndicator.height * 0.75
        radius:                 2
        color:                  qgcPal.window

        Rectangle {
            id:                     compassBezel
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:     _toolsMargin
            anchors.left:           parent.left
            width:                  height
            height:                 parent.height - (northLabelBackground.height / 2) - (headingLabelBackground.height / 2)
            radius:                 height / 2
            border.color:           qgcPal.text
            border.width:           1
            color:                  Qt.rgba(0,0,0,0)
        }

        Rectangle {
            id:                         northLabelBackground
            anchors.top:                compassBezel.top
            anchors.topMargin:          -height / 2
            anchors.horizontalCenter:   compassBezel.horizontalCenter
            width:                      northLabel.contentWidth * 1.5
            height:                     northLabel.contentHeight * 1.5
            radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
            color:                      qgcPal.windowShade

            QGCLabel {
                id:                 northLabel
                anchors.centerIn:   parent
                text:               "N"
                color:              qgcPal.text
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }

        Image {
            id:                 headingNeedle
            anchors.centerIn:   compassBezel
            height:             compassBezel.height * 0.75
            width:              height
            source:             "/custom/img/compass_needle.svg"
            fillMode:           Image.PreserveAspectFit
            sourceSize.height:  height
            transform: [
                Rotation {
                    origin.x:   headingNeedle.width  / 2
                    origin.y:   headingNeedle.height / 2
                    angle:      _heading
                }]
        }

        Rectangle {
            id:                         headingLabelBackground
            anchors.top:                compassBezel.bottom
            anchors.topMargin:          -height / 2
            anchors.horizontalCenter:   compassBezel.horizontalCenter
            width:                      headingLabel.contentWidth * 1.5
            height:                     headingLabel.contentHeight * 1.5
            radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
            color:                      qgcPal.windowShade

            QGCLabel {
                id:                 headingLabel
                anchors.centerIn:   parent
                text:               _heading
                color:              qgcPal.text
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }
    //-------------------------------------------------------------------------
    //attitudeIndicator
    Rectangle {
        id:                     attitudeIndicator
        anchors.bottomMargin:   _toolsMargin + parentToolInsets.bottomEdgeRightInset
        anchors.rightMargin:    _toolsMargin
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        height:                 ScreenTools.defaultFontPixelHeight * 6
        width:                  height
        radius:                 height * 0.5
        color:                  qgcPal.windowShade

        CustomAttitudeWidget {
            size:               parent.height * 0.95
            vehicle:            _activeVehicle
            showHeading:        false
            anchors.centerIn:   parent
        }
    }



/*CesiumWidget {
    id: cesiumWidget

    anchors.left: parent.left
    anchors.top: parent.top

    anchors.leftMargin: _toolsMargin
    anchors.topMargin: parentToolInsets.topEdgeLeftInset + _toolsMargin

    width: 280
    height: 300
    visible: true

    // Export insets
    property real leftEdgeCenterInset: visible ? x + width : 0
    property real bottomStackY: visible ? y + height : parentToolInsets.topEdgeLeftInset
}*/



// 1. Map Marker Widget 
MapMarkerWidget {
    id: mapMarkerWidget
    mapControl: customOverlayRoot.mapControl

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: _toolsMargin
    anchors.topMargin: parentToolInsets.topEdgeLeftInset + _toolsMargin

    visible: true
    property real leftEdgeCenterInset: visible ? x + width : 0
}

// 2. Parameter Widget 
CustomParameterWidget {
    id: paramWidget
    visible: true

    anchors.left: parent.left
    anchors.top: mapMarkerWidget.bottom

    anchors.leftMargin: _toolsMargin
    anchors.topMargin: 2*parentToolInsets.topEdgeLeftInset 


    property real leftEdgeCenterInset: visible ? x + width : 0
}

// 3. Data widget
SimpleVehicleDataWidget {
    id: dataWidget
    visible: true

    anchors.right:parent.right
    anchors.top: parent.top
    
    anchors.rightMargin: 2*parentToolInsets.topEdgeRightInset +5*_toolsMargin
    anchors.topMargin:  _toolsMargin

    //property real leftEdgeCenterInset: visible ? x + width : 0
}
   
}

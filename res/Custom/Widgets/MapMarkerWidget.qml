import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning
import QtLocation

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    // FlyViewMap must be passed in
    property var mapControl
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var markers: []

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    Rectangle {
        id: container
        width: 240
        implicitHeight: layout.implicitHeight + ScreenTools.defaultFontPixelWidth
        color: qgcPal.window
        radius: ScreenTools.defaultFontPixelWidth / 2
        border.color: qgcPal.text
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth / 2
            spacing: 6

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: ScreenTools.defaultFontPixelHeight * 1.6
                color: qgcPal.windowShade
                radius: 4

                QGCLabel {
                    anchors.centerIn: parent
                    text: "Map Markers"
                    font.bold: true
                }
            }

            // Inputs
            GridLayout {
                columns: 2
                columnSpacing: 6
                rowSpacing: 6
                Layout.fillWidth: true

                QGCLabel { text: "Lat:" }
                QGCTextField {
                    id: latField
                    Layout.fillWidth: true
                    placeholderText: "0.000000"
                }

                QGCLabel { text: "Lon:" }
                QGCTextField {
                    id: lonField
                    Layout.fillWidth: true
                    placeholderText: "0.000000"
                }

                QGCLabel { text: "Label:" }
                QGCTextField {
                    id: labelField
                    Layout.fillWidth: true
                    placeholderText: "Point 1"
                }
            }

            // Primary actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                QGCButton {
                    text: "Add Pin"
                    Layout.fillWidth: true
                    primary: true
                    onClicked: addMarkerToMap()
                }

                QGCButton {
                    text: "Clear"
                    Layout.fillWidth: true
                    onClicked: clearAllMarkers()
                }
            }

            // Utility actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                QGCButton {
                    text: "Use Vehicle"
                    Layout.fillWidth: true
                    enabled: _activeVehicle
                    onClicked: addCurrentPosition()
                }

                QGCButton {
                    text: "Center"
                    Layout.fillWidth: true
                    onClicked: centerMapOnMarker()
                }
            }
        }
    }

    // ---------------- Logic ----------------

    function addMarkerToMap() {
        if (!mapControl) {
            console.warn("MarkerWidget: mapControl not set")
            return
        }

        var lat = parseFloat(latField.text)
        var lon = parseFloat(lonField.text)
        var label = labelField.text || "Marker"

        if (isNaN(lat) || isNaN(lon)) {
            console.warn("MarkerWidget: Invalid coordinates")
            return
        }

        var markerQml = `
            import QtQuick
            import QtLocation
            import QtPositioning

            MapQuickItem {
                coordinate: QtPositioning.coordinate(${lat}, ${lon})
                anchorPoint.x: sourceItem.width / 2
                anchorPoint.y: sourceItem.height

                sourceItem: Column {
                    spacing: 2

                    Rectangle {
                        width: 60
                        height: 20
                        color: "#CC000000"
                        radius: 3
                        visible: labelText.text !== ""
                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: "${label}"
                            color: "white"
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: "red"
                        border.color: "white"
                        border.width: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        width: 2
                        height: 8
                        color: "white"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        `

        var marker = Qt.createQmlObject(markerQml, mapControl, "dynamicMarker")
        if (marker) {
            mapControl.addMapItem(marker)
            markers.push(marker)
        }
    }

    function clearAllMarkers() {
        if (!mapControl)
            return

        for (var i = 0; i < markers.length; i++) {
            mapControl.removeMapItem(markers[i])
            markers[i].destroy()
        }
        markers = []
    }

    function addCurrentPosition() {
        if (_activeVehicle && _activeVehicle.coordinate.isValid) {
            latField.text = _activeVehicle.coordinate.latitude.toFixed(6)
            lonField.text = _activeVehicle.coordinate.longitude.toFixed(6)
            labelField.text = "Vehicle"
        }
    }

    function centerMapOnMarker() {
        if (!mapControl)
            return

        var lat = parseFloat(latField.text)
        var lon = parseFloat(lonField.text)

        if (!isNaN(lat) && !isNaN(lon)) {
            mapControl.center = QtPositioning.coordinate(lat, lon)
        } else if (_activeVehicle) {
            mapControl.center = _activeVehicle.coordinate
        }
    }

    Component.onDestruction: clearAllMarkers()
}

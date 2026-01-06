import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Item {
    id: root

    property var factPanelController: FactPanelController { }
    property var vehicle: factPanelController.vehicle
    property var parameterManager: vehicle ? vehicle.parameterManager : null

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    Rectangle {
        id: container
        width: 260
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
                    text: "Parameter Logger"
                    font.bold: true
                }
            }

            // Status bar
            Rectangle {
                Layout.fillWidth: true
                height: ScreenTools.defaultFontPixelHeight * 1.4
                radius: 4
                color: {
                    if (!vehicle || !parameterManager)
                        return qgcPal.brandingRed
                    return parameterManager.parametersReady
                           ? qgcPal.windowShadeLight
                           : qgcPal.warningText
                }

                QGCLabel {
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                    text: {
                        if (!vehicle)
                            return "No vehicle connected"
                        if (!parameterManager)
                            return "Parameter manager unavailable"
                        if (!parameterManager.parametersReady)
                            return "Loading parameters… " +
                                   Math.round(parameterManager.loadProgress * 100) + "%"
                        return "✓ Parameters ready"
                    }
                }
            }


            // Custom parameter
            QGCLabel {
                text: "Specific parameter"
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                QGCTextField {
                    id: customParamInput
                    Layout.fillWidth: true
                    placeholderText: "e.g. MIS_TAKEOFF_ALT"
                }

                QGCButton {
                    text: "Log"
                    enabled: customParamInput.text &&
                             parameterManager &&
                             parameterManager.parametersReady

                    onClicked: logSingleParameter(customParamInput.text.trim())
                }
            }

            
        }
    }

    // ---------------- Logic ----------------


    function listComponentIds() {
        var compIds = parameterManager.componentIds()
        console.log("====== Component IDs ======")
        for (var i = 0; i < compIds.length; i++) {
            console.log("Component ID:", compIds[i])
        }
        console.log("===========================")
    }

    function logSingleParameter2(paramName) {
        var fact = null
        var foundComponent = -1

        // Try default component
        if (factPanelController.parameterExists(-1, paramName)) {
            fact = factPanelController.getParameterFact(-1, paramName, false)
            foundComponent = -1
        } else {
            var compIds = parameterManager.componentIds()
            for (var i = 0; i < compIds.length; i++) {
                if (factPanelController.parameterExists(compIds[i], paramName)) {
                    fact = factPanelController.getParameterFact(compIds[i], paramName, false)
                    foundComponent = compIds[i]
                    break
                }
            }
        }

        if (!fact) {
            console.log("✗", paramName, "not found")
            return
        }

        console.log("✓", paramName, "(component", foundComponent + ")")
        console.log("raw",fact)
        console.log("  Value:", fact.value)
        console.log("  Min:", fact.min, "Max:", fact.max)
        console.log("  Units:", fact.units)
        console.log("  Type:", fact.type)
        console.log("  Description:", fact.shortDescription)
    }

    function logSingleParameter(paramName) {
    var fact = null
    var foundComponent = -1

    // Try default component
    if (factPanelController.parameterExists(-1, paramName)) {
            fact = factPanelController.getParameterFact(-1, paramName, false)
            foundComponent = -1
        } else {
            var compIds = parameterManager.componentIds()
            for (var i = 0; i < compIds.length; i++) {
                if (factPanelController.parameterExists(compIds[i], paramName)) {
                    fact = factPanelController.getParameterFact(compIds[i], paramName, false)
                    foundComponent = compIds[i]
                    break
                }
            }
        }

        if (!fact) {
            console.log("✗", paramName, "not found")
            return
        }

        console.log("✓", paramName, "(component", foundComponent + ")")
        console.log("raw", fact)
        console.log("  Name:", fact.name) // Explicitly log name for clarity
        console.log("  Short Description:", fact.shortDescription)
        console.log("  Long Description:", fact.longDescription) // Add long description for more detail
        console.log("  Category:", fact.category)
        console.log("  Group:", fact.group)

        console.log("  Type:", fact.type)
        console.log("  Raw Value:", fact.rawValue, "(Full Precision:", fact.rawValueStringFullPrecision + ")") // Show raw and full precision string
        console.log("  Cooked Value:", fact.value, "(String:", fact.cookedValueString + ")")

        if (fact.enumStrings.length > 0) {
            console.log("  Enum Value (String):", fact.enumStringValue)
            console.log("  Enum Strings:", fact.enumStrings)
            console.log("  Enum Values:", fact.enumValues)
        } else if (fact.bitmaskStrings.length > 0) {
            console.log("  Selected Bitmask Strings:", fact.selectedBitmaskStrings)
            console.log("  Bitmask Strings:", fact.bitmaskStrings)
            console.log("  Bitmask Values:", fact.bitmaskValues)
        }

        console.log("  Min:", fact.min, "(String:", fact.cookedMinString + ")")
        console.log("  Max:", fact.max, "(String:", fact.cookedMaxString + ")")
        console.log("  User Min:", fact.userMin, "(String:", fact.cookedUserMinString + ")")
        console.log("  User Max:", fact.userMax, "(String:", fact.cookedUserMaxString + ")")
        console.log("  Units:", fact.units)
        console.log("  Decimal Places:", fact.decimalPlaces)
        console.log("  Increment:", fact.increment)

        console.log("  Default Value Available:", fact.defaultValueAvailable)
        if (fact.defaultValueAvailable) {
            console.log("  Default Value:", fact.defaultValue, "(String:", fact.defaultValueString + ")")
            console.log("  Value Equals Default:", fact.valueEqualsDefault)
        }

        console.log("  Read Only:", fact.readOnly)
        console.log("  Write Only:", fact.writeOnly)
        console.log("  Volatile Value:", fact.volatileValue)
        console.log("  Has Control:", fact.hasControl)

        console.log("  Vehicle Reboot Required:", fact.vehicleRebootRequired)
        console.log("  QGC Reboot Required:", fact.qgcRebootRequired)
}
}

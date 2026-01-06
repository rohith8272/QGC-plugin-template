import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    QGCPalette { 
        id: qgcPal
        colorGroupEnabled: true 
    }

    FontMetrics {
        id: fontMetrics
        font.family: Qt.application.font.family
    }

    // Sizing helpers
    property real defaultMargin: fontMetrics.height * 0.5
    property real rowHeight: fontMetrics.height * 1.6
    property real smallFontSize: fontMetrics.font.pointSize * 0.8

    // --- 2. CONFIGURATION ---

    property var _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property int updateInterval:    100
    property real widgetWidth:      600
    property real widgetHeight:     450
    property int maxDataPoints:     300
    property var _seriesColors:     ["#00E04B","#DE8500","#F32836","#BFBFBF","#536DFF","#EECC44"]
    
    // State
    property var selectedParameters: [] 
    property double timeCounter: 0.0
    property var activeSeriesMap: ({}) 

    // --- 3. UI LAYOUT ---

    Rectangle {
    id: container
    width: widgetWidth
    height: widgetHeight
    color: qgcPal.window
    radius: 4
    border.color: qgcPal.text
    border.width: 1
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: defaultMargin
        spacing: 0

        // Header with Title and Tabs
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: rowHeight * 1.5
            color: qgcPal.windowShade
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.margins: defaultMargin * 0.75
                spacing: defaultMargin
                
                QGCLabel {
                    text: "Data Monitor"
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.1
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                TabBar {
                    id: tabBar
                    Layout.preferredHeight: rowHeight * 1.2
                    Layout.preferredWidth: 180
                    
                    TabButton { 
                        text: "Values"
                        width: implicitWidth
                    }
                    TabButton { 
                        text: "Live Plot"
                        width: implicitWidth
                    }
                }
            }
        }

        // Main Content Area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: defaultMargin
            currentIndex: tabBar.currentIndex

            // ============================================
            // TAB 1: PARAMETER VALUES VIEW
            // ============================================
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: defaultMargin
                    
                    // Parameter Selection Section
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: rowHeight * 1.5
                        color: qgcPal.windowShade
                        radius: 3
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: defaultMargin * 0.75
                            spacing: defaultMargin
                            
                            QGCLabel {
                                text: "Add Parameter:"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            
                            QGCComboBox {
                                id: paramSelector
                                Layout.fillWidth: true
                                Layout.preferredHeight: rowHeight
                                model: parameterList
                                textRole: "display"
                            }
                            
                            QGCButton {
                                text: "Add"
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: rowHeight
                                onClicked: addParameter(parameterList[paramSelector.currentIndex])
                            }
                        }
                    }

                    // Parameters List Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: defaultMargin * 0.5
                        
                        // Column Headers
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: rowHeight * 0.9
                            color: qgcPal.windowShade
                            radius: 2
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: defaultMargin
                                anchors.rightMargin: defaultMargin
                                spacing: defaultMargin
                                
                                QGCLabel { 
                                    text: "Parameter"
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                
                                QGCLabel { 
                                    text: "Value"
                                    font.bold: true
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignRight
                                }
                                
                                Item { 
                                    Layout.preferredWidth: 35
                                }
                            }
                        }
                        
                        // Scrollable Parameter List
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: qgcPal.windowShade
                            radius: 3
                            border.color: Qt.rgba(0, 0, 0, 0.2)
                            border.width: 1
                            
                            ListView {
                                id: paramView
                                anchors.fill: parent
                                anchors.margins: 2
                                clip: true
                                model: selectedParameters
                                spacing: 1
                                
                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: rowHeight * 1.1
                                    color: index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
                                    radius: 2
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: defaultMargin
                                        anchors.rightMargin: defaultMargin * 0.5
                                        spacing: defaultMargin
                                        
                                        // Color indicator (shown when chart tab is active)
                                        Rectangle {
                                            Layout.preferredWidth: 4
                                            Layout.preferredHeight: parent.height * 0.6
                                            Layout.alignment: Qt.AlignVCenter
                                            color: _seriesColors[index % _seriesColors.length]
                                            radius: 2
                                            visible: selectedParameters.length > 0
                                        }

                                        QGCLabel { 
                                            text: modelData.name
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            elide: Text.ElideRight
                                        }
                                        
                                        QGCLabel { 
                                            text: getCurrentValue(modelData) + (modelData.unit ? " " + modelData.unit : "")
                                            Layout.preferredWidth: 100
                                            Layout.alignment: Qt.AlignVCenter
                                            horizontalAlignment: Text.AlignRight
                                            font.family: "monospace"
                                        }
                                        
                                        QGCButton {
                                            text: "×"
                                            Layout.preferredWidth: 30
                                            Layout.preferredHeight: rowHeight * 0.7
                                            Layout.alignment: Qt.AlignVCenter
                                            onClicked: removeParameter(index)
                                        }
                                    }
                                }
                                
                                // Empty state message
                                Label {
                                    anchors.centerIn: parent
                                    text: "No parameters added.\nSelect a parameter above and click 'Add'."
                                    color: qgcPal.text
                                    opacity: 0.5
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: paramView.count === 0
                                }
                            }
                        }
                        
                        // Action Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: defaultMargin
                            
                            Item { Layout.fillWidth: true }
                            
                            QGCButton {
                                text: "Clear All"
                                Layout.preferredHeight: rowHeight
                                enabled: selectedParameters.length > 0
                                onClicked: {
                                    removeAllSeries()
                                    selectedParameters = []
                                }
                            }
                        }
                    }
                }
            }

            // ============================================
            // TAB 2: LIVE PLOT VIEW
            // ============================================
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: defaultMargin
                    
                    // Chart Controls and Legend
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: rowHeight * 1.8
                        color: qgcPal.windowShade
                        radius: 3
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: defaultMargin * 0.75
                            spacing: defaultMargin * 0.5
                            
                            // Controls Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: defaultMargin * 1.5
                                
                                QGCLabel { 
                                    text: "Time Range:"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                
                                QGCComboBox {
                                    id: rangeSelector
                                    model: ["10s", "30s", "60s"]
                                    currentIndex: 1
                                    Layout.preferredHeight: rowHeight
                                    Layout.preferredWidth: 70
                                    onActivated: (index) => {
                                        if (index === 0) maxDataPoints = 100
                                        else if (index === 1) maxDataPoints = 300
                                        else if (index === 2) maxDataPoints = 600
                                    }
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: rowHeight * 0.6
                                    color: Qt.rgba(1, 1, 1, 0.2)
                                }
                                
                                QGCButton {
                                    text: "Auto Scale Y"
                                    Layout.preferredHeight: rowHeight
                                    onClicked: autoScaleY()
                                }
                                
                                Item { Layout.fillWidth: true }
                            }
                            
                            // Legend Row
                            Flow {
                                Layout.fillWidth: true
                                Layout.preferredHeight: rowHeight
                                spacing: defaultMargin * 1.5
                                
                                Repeater {
                                    model: selectedParameters
                                    
                                    RowLayout {
                                        spacing: defaultMargin * 0.5
                                        
                                        Rectangle {
                                            Layout.preferredWidth: 12
                                            Layout.preferredHeight: 12
                                            radius: 6
                                            color: _seriesColors[index % _seriesColors.length]
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                        
                                        QGCLabel {
                                            text: modelData.name
                                            font.pointSize: smallFontSize
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Chart Area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(0, 0, 0, 0.3)
                        radius: 3
                        border.color: Qt.rgba(0, 0, 0, 0.2)
                        border.width: 1
                        
                        ChartView {
                            id: chartView
                            anchors.fill: parent
                            anchors.margins: 1
                            
                            theme: ChartView.ChartThemeDark
                            antialiasing: true
                            animationOptions: ChartView.NoAnimation
                            legend.visible: false
                            backgroundColor: "transparent"
                            backgroundRoundness: 0
                            
                            margins.top: defaultMargin
                            margins.bottom: defaultMargin
                            margins.left: defaultMargin
                            margins.right: defaultMargin
                            
                            ValueAxis {
                                id: axisX
                                min: 0
                                max: maxDataPoints / 10
                                titleText: "Time (s)"
                                labelsFont.pointSize: smallFontSize
                                labelsColor: qgcPal.text
                                gridLineColor: Qt.rgba(1, 1, 1, 0.1)
                                minorGridLineColor: Qt.rgba(1, 1, 1, 0.05)
                            }

                            ValueAxis {
                                id: axisY
                                min: 0
                                max: 100
                                titleText: "Value"
                                labelsFont.pointSize: smallFontSize
                                labelsColor: qgcPal.text
                                gridLineColor: Qt.rgba(1, 1, 1, 0.1)
                                minorGridLineColor: Qt.rgba(1, 1, 1, 0.05)
                            }
                        }
                        
                        // Empty state message for chart
                        Label {
                            anchors.centerIn: parent
                            text: "No parameters to plot.\nAdd parameters in the 'Values' tab."
                            color: qgcPal.text
                            opacity: 0.4
                            font.pointSize: ScreenTools.defaultFontPointSize * 1.1
                            horizontalAlignment: Text.AlignHCenter
                            visible: selectedParameters.length === 0
                        }
                    }
                }
            }
        }
    }
}

    // --- 4. LOGIC ---

    Timer {
        id: updateTimer
        interval: updateInterval
        running: true
        repeat: true
        onTriggered: {
            timeCounter += (interval / 1000.0);
            
            // Force list refresh for numeric values
            if(tabBar.currentIndex === 0) {
                 paramView.forceLayout()
            }

            // Update Plots
            updateSeriesData();
        }
    }

    function addParameter(paramData) {
        if (!paramData) return;
        
        // Check duplicates
        for (var i = 0; i < selectedParameters.length; i++) {
            if (selectedParameters[i].name === paramData.display) return;
        }

        var newParam = {
            name: paramData.display,
            unit: paramData.unit,
            getValue: paramData.getValue
        };

        // Add to model
        selectedParameters.push(newParam);
        selectedParameters = selectedParameters.slice(); // Force update
        
        // Create Chart Series
        createSeriesForParam(newParam, selectedParameters.length - 1);
    }

    function removeParameter(index) {
        var param = selectedParameters[index];
        
        // Remove Series
        if(activeSeriesMap[param.name]) {
            chartView.removeSeries(activeSeriesMap[param.name]);
            delete activeSeriesMap[param.name];
        }

        selectedParameters.splice(index, 1);
        selectedParameters = selectedParameters.slice();
        recolorSeries();
    }

    function removeAllSeries() {
        chartView.removeAllSeries();
        activeSeriesMap = {};
    }

    function createSeriesForParam(param, index) {
        var color = _seriesColors[index % _seriesColors.length];
        var series = chartView.createSeries(ChartView.SeriesTypeLine, param.name, axisX, axisY);
        
        series.useOpenGL = true;
        series.color = color;
        series.width = 2;
        
        activeSeriesMap[param.name] = series;
    }

    function recolorSeries() {
        for(var i=0; i<selectedParameters.length; i++) {
            var pName = selectedParameters[i].name;
            if(activeSeriesMap[pName]) {
                activeSeriesMap[pName].color = _seriesColors[i % _seriesColors.length];
            }
        }
    }

    function updateSeriesData() {
        var currentT = timeCounter;
        var minX = Math.max(0, currentT - (maxDataPoints * (updateInterval/1000.0)));
        axisX.min = minX;
        axisX.max = currentT;

        for (var i = 0; i < selectedParameters.length; i++) {
            var param = selectedParameters[i];
            var val = getCurrentValueRaw(param);
            
            if (val !== null && typeof val === 'number') {
                var series = activeSeriesMap[param.name];
                if (series) {
                    series.append(currentT, val);
                    if (series.count > maxDataPoints) {
                        series.remove(0); 
                    }
                }
            }
        }
    }

    function autoScaleY() {
        var minVal = 999999;
        var maxVal = -999999;
        var hasData = false;

        for(var key in activeSeriesMap) {
            var param = selectedParameters.find(p => p.name === key);
            if(param) {
                var val = getCurrentValueRaw(param);
                if(val !== null && typeof val === 'number') {
                    if(val < minVal) minVal = val;
                    if(val > maxVal) maxVal = val;
                    hasData = true;
                }
            }
        }

        if(hasData) {
            var range = maxVal - minVal;
            if (range === 0) range = 10;
            axisY.min = minVal - (range * 0.5);
            axisY.max = maxVal + (range * 0.5);
        } else {
            axisY.min = 0;
            axisY.max = 100;
        }
    }

    function getCurrentValue(param) {
        var v = getCurrentValueRaw(param);
        if (v === null || v === undefined) return "N/A";
        return typeof v === 'number' ? v.toFixed(2) : v.toString();
    }

    function getCurrentValueRaw(param) {
        if (param.getValue) return param.getValue();
        return null;
    }

    // --- 5. DATA SOURCES ---
    property var parameterList: [
        { display: "Altitude (Rel)", unit: "m", getValue: function() { return _activeVehicle ? _activeVehicle.altitudeRelative.value : 0 } },
        { display: "Altitude (AMSL)", unit: "m", getValue: function() { return _activeVehicle ? _activeVehicle.altitudeAMSL.value : 0 } },
        { display: "Ground Speed", unit: "m/s", getValue: function() { return _activeVehicle ? _activeVehicle.groundSpeed.value : 0 } },
        { display: "Air Speed", unit: "m/s", getValue: function() { return _activeVehicle ? _activeVehicle.airSpeed.value : 0 } },
        { display: "Climb Rate", unit: "m/s", getValue: function() { return _activeVehicle ? _activeVehicle.climbRate.value : 0 } },
        { display: "Heading", unit: "deg", getValue: function() { return _activeVehicle ? _activeVehicle.heading.value : 0 } },
        { display: "Distance to Home", unit: "m", getValue: function() { return _activeVehicle ? _activeVehicle.distanceToHome.value : 0 } },
        { display: "Battery", unit: "%", getValue: function() { return _activeVehicle ? _activeVehicle.battery.percentRemaining.value : 0 } },
        { display: "Sats", unit: "", getValue: function() { return _activeVehicle ? _activeVehicle.gps.count.value : 0 } },
        { display: "Roll", unit: "deg", getValue: function() { return _activeVehicle ? _activeVehicle.roll.value : 0 } },
        { display: "Pitch", unit: "deg", getValue: function() { return _activeVehicle ? _activeVehicle.pitch.value : 0 } }
    ]
}
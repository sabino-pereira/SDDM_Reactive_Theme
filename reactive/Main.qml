import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import QtQuick.Effects
import SddmComponents
import "."

Item {
    id: root

    ////////////////////////////////////////////
    // THEMING
    ////////////////////////////////////////////
    
    // Load the matugen file
    Matugen {
        id: matugenTheme
    }

    // Global Properties
    readonly property string backgroundImageSource: "assets/background"
    readonly property real backgroundImageBlur:     0.5
    

    readonly property color secondaryMonitorBgColor: Qt.rgba(0, 0, 0, 1)
    readonly property string secondaryMonitorQuote:  "Multiple Monitors?\nIn this economy???"


    readonly property string timeFormat: "hh:mm"
    readonly property string dateFormat: "dddd, d MMM"

    readonly property int fontSizeTime:  Screen.height * 0.11
    readonly property int fontSizeDate:  fontSizeTime / 2
    
    readonly property int fontSizeBase:  Screen.height * 0.015
    readonly property int fontSizeLarge: fontSizeBase * 2
    readonly property int fontSizeHuge:  fontSizeBase * 3
    
    FontLoader {
        id: pixelifySansBold
        source: "assets/PixelifySans-Bold.ttf"
    }
    FontLoader {
        id: bungee
        source: "assets/Bungee.ttf"
    }
    FontLoader {
        id: jetBrainsMono
        source: "assets/JetBrainsMono.ttf"
    }
    readonly property string fontFamilyBase:  jetBrainsMono.name
    readonly property string fontFamilyAlt:   bungee.name
    readonly property string fontFamilyFancy: pixelifySansBold.name


    readonly property color fontColorBase:   matugenTheme.primary || "yellow"
    readonly property color fontColorHover:  matugenTheme.on_primary || "green"
    readonly property color fontColorSplash: matugenTheme.inverse_primary || "yellow"
    
    readonly property color backgroundBase:     matugenTheme.inverse_primary || "yellow"
    readonly property color passwordInputColor: matugenTheme.inverse_on_surface || "blue"
    readonly property color borderBase:         matugenTheme.primary || "yellow"
    readonly property color shadowBase:         matugenTheme.shadow || "black"


    readonly property int borderWidthBase: 1
    readonly property int radiusBase:      8
    

    readonly property real componentHeight:  0.05  //Percent of height/widh of screen
    readonly property real componentWidth:   0.15
    readonly property real topBorderMargin:  0.03
    readonly property real leftBorderMargin: 0.03


    readonly property int shadowBlur:   10
    readonly property int shadowOffset: 5




    ////////////////////////////////////////////
    // LOGICS
    ////////////////////////////////////////////

    property int currentUserIndex:    0
    property int currentSessionIndex: 0
    property bool userPopupOpen:      false
    property bool sessionPopupOpen:   false
    property bool powerMenuOpen:      false 

    focus: true

    // Watch for login failures
    Connections {
        target: sddm
        function onLoginFailed() { 
            passwordInput.text = ""; 
            shakeAnimation.restart();
        }
    }

    // Hidden user selection menu (Custom component is used instead)
    QQC2.ComboBox {
        id: userSelector

        visible:      false
        model:        userModel
        textRole:     "name"
        currentIndex: root.currentUserIndex
    }

    // Hidden session selection menu (Custom component is use instead)
    QQC2.ComboBox {
        id: sessionSelector

        visible:      false
        model:        sessionModel
        textRole:     "name"
        currentIndex: root.currentSessionIndex
    }
    
    function attemptLogin() {
        if (userModel.count === 0) return;
        const selectedUser = userSelector.currentIndex;
        const selectedSession = sessionSelector.currentIndex;
        
        if (selectedUser < 0 || selectedSession < 0) return;
        
        const username = (typeof userModel.get === "function") ? userModel.get(selectedUser).name : userSelector.currentText;
        sddm.login(username, passwordInput.text, selectedSession);
    }
    
    Component.onCompleted: {
        const lastSessionIndex = sessionModel.lastIndex;
        currentSessionIndex = (lastSessionIndex && lastSessionIndex < sessionModel.count) ? lastSessionIndex : 0

        const lastUserIndex = userModel.lastIndex;
        currentUserIndex = (lastUserIndex && lastUserIndex < userModel.count) ? lastUserIndex : 0

        // Force focus on password input
        passwordInput.forceActiveFocus();
    }



    ////////////////////////////////////////////
    // VISUAL
    ////////////////////////////////////////////

    // PRIMARY MONITOR //
    // Background Image
    Image {
        id: backgroundImage

        anchors.fill: parent

        z: 0

        fillMode: Image.PreserveAspectCrop
        source:   backgroundImageSource
        visible:  primaryScreen

        // Blue
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax:     64
            blur:        backgroundImageBlur
        }
    }

    // Dimiss open menus and unfocus password on clicking outside
    MouseArea {
        anchors.fill: parent
        
        onClicked: {
            root.sessionPopupOpen = false;
            root.userPopupOpen    = false;
            root.powerMenuOpen   = false;
            
            // Natively drops focus from the passwordInput
            root.forceActiveFocus();
        }
    }

    // Clock Widget (Top Center)
    Column {
        id: clockContainer

        visible: primaryScreen

        anchors.top:              parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin:        Screen.height * topBorderMargin

        spacing: 8 

        property date currentTime: new Date()

        Timer {
            interval: 1000 
            running:  true
            repeat:   true
            onTriggered: clockContainer.currentTime = new Date()
        }

        Text {
            text: Qt.formatDateTime(clockContainer.currentTime, timeFormat)

            anchors.horizontalCenter: parent.horizontalCenter
            
            color:          fontColorBase
            font.pixelSize: fontSizeTime
            font.bold:      true
            font.family:    fontFamilyAlt 

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true

                shadowBlur:  shadowBlur
                shadowColor: shadowBase

                shadowHorizontalOffset: shadowOffset
                shadowVerticalOffset:   shadowOffset
            }
        }

        Text {
            text: Qt.formatDateTime(clockContainer.currentTime, dateFormat)

            anchors.horizontalCenter: parent.horizontalCenter

            color:          fontColorBase
            font.pixelSize: fontSizeDate 
            font.weight:    Font.Medium
            font.family:    fontFamilyAlt

            opacity:        0.8

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true

                shadowBlur:  shadowBlur
                shadowColor: shadowBase

                shadowHorizontalOffset: shadowOffset
                shadowVerticalOffset:   shadowOffset
            }
        }
    }

    // Minecraft style splash text - Center Piece
    Text {
        id: splashText

        visible: primaryScreen
        
        anchors.centerIn:             parent
        anchors.verticalCenterOffset: -Screen.height * 0.05 
        
        rotation: -10 
        scale:    splashMouseArea.containsMouse ? 1.25 : 1.0
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        property var quotes: [
            "I use Arch btw.",
            "sudo pacman --Help-I-Cannot-Stop-Ricing",
            "Name a salad after me, brutus!",
            "Now with 100% more bugs",
            "Needs more RGB.",
            "Yeah! Science!",
            "Time to be productive...LOL JK",
            "Does this rice make my RAM look big?",
            "To login, or not to login?"
        ]

        Component.onCompleted: {
            text = quotes[Math.floor(Math.random() * quotes.length)]
        }

        color:          fontColorSplash
        font.pixelSize: fontSizeHuge
        font.family:    fontFamilyFancy
        
        // style:      Text.Raised
        // styleColor: "#3F3F15" 

        // Change on click
        MouseArea {
            id: splashMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            
            onClicked: parent.text = parent.quotes[Math.floor(Math.random() * parent.quotes.length)]
        }
    }

    // Session Selection (Top Left)
    Rectangle {
        id: sessionContainer

        visible: primaryScreen

        anchors.top:  parent.top
        anchors.left: parent.left

        anchors.topMargin: Screen.height * topBorderMargin
        anchors.leftMargin: Screen.width * leftBorderMargin

        width:  Screen.width * componentWidth
        height: Screen.height * componentHeight
        radius: radiusBase

        z: 10

        color:        backgroundBase
        border.color: borderBase
        border.width: borderWidthBase

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true

            shadowBlur:  shadowBlur
            shadowColor: shadowBase

            shadowHorizontalOffset: shadowOffset
            shadowVerticalOffset:   shadowOffset
        }

        MouseArea {
            id: sessionMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor

            onClicked: {
                root.sessionPopupOpen = !root.sessionPopupOpen;
                root.userPopupOpen = false; 
                root.powerMenuOpen = false;
            }
        }

        Rectangle {
            anchors.fill: parent

            radius: radiusBase
            color: "#ffffff"
            opacity: sessionMouseArea.containsMouse ? 0.08 : 0.0

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            id: sessionRow

            anchors.centerIn: parent

            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36

                color: "transparent"

                Text {
                    anchors.centerIn: parent

                    text: ""

                    font.pixelSize: fontSizeBase
                    font.family:    fontFamilyBase
                    color:          fontColorBase
                }
            }

            Text {
                text: sessionSelector.currentText === "Hyprland (uwsm-managed)" ? "Hyprland (uwsm)" : sessionSelector.currentText

                color:          fontColorBase
                font.pixelSize: fontSizeBase
                font.weight:    Font.Medium
                font.family:    fontFamilyBase

                elide: Text.ElideRight
            }

            Text {
                text: ""

                color:          fontColorBase
                font.pixelSize: fontSizeBase
                font.family:    fontFamilyBase

                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Session Pop UP
    Rectangle {
        id: sessionPopup

        width:  sessionContainer.width
        height: Math.min( (Screen.height * componentHeight * sessionModel.count) + 10 , Screen.height * 0.8)

        color:        backgroundBase
        border.color: borderBase
        border.width: borderWidthBase

        radius: radiusBase

        z: 100

        anchors.top:       sessionContainer.bottom
        anchors.left:      sessionContainer.left
        anchors.topMargin: root.sessionPopupOpen ? 15 : 0

        opacity: root.sessionPopupOpen ? 1.0 : 0.0

        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } } 
        Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        ListView {
            model: sessionModel

            anchors.fill:    parent
            anchors.margins: 4

            clip: true
            
            delegate: Rectangle {
                id: sessionDelegate

                required property int index
                required property string name
                
                width:  ListView.view.width
                height: Screen.height * componentHeight
                color:  "transparent"
                radius: radiusBase
                
                Rectangle { 
                    anchors.fill: parent

                    color:  "#ffffff"
                    radius: radiusBase
                    opacity: sessionEntryMouse.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } } 
                }
                
                Text { 
                    anchors.centerIn: parent

                    text: sessionDelegate.name === "Hyprland (uwsm-managed)" ? "Hyprland (uwsm)" : sessionDelegate.name
                    
                    color:          fontColorBase
                    font.pixelSize: fontSizeBase
                    font.family:    fontFamilyBase
                }
                
                MouseArea { 
                    id: sessionEntryMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor

                    onClicked: { 
                        root.currentSessionIndex = sessionDelegate.index; 
                        root.sessionPopupOpen = false; 
                    } 
                }
            }
        }
    }

    // Power Menu (Top Right)
    Rectangle {
        id: powerControlsPill

        visible: primaryScreen

        anchors.top:   parent.top
        anchors.right: parent.right
        
        anchors.topMargin:   Screen.height * topBorderMargin
        anchors.rightMargin: Screen.width * leftBorderMargin

        width:  root.powerMenuOpen ? ( powerButtonsRow.implicitWidth + powerOptionsButton.width + 40 ) : 56
        height: 56
        radius: radiusBase

        color:        backgroundBase
        border.color: borderBase
        border.width: borderWidthBase

        clip:         true 

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true

            shadowBlur:  shadowBlur
            shadowColor: shadowBase

            shadowHorizontalOffset: shadowOffset
            shadowVerticalOffset:   shadowOffset
        }

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        Item {
            anchors.fill: parent

            RowLayout {
                id: powerButtonsRow

                anchors.right:          powerOptionsButton.left
                anchors.rightMargin:    16
                anchors.verticalCenter: parent.verticalCenter

                spacing: 30

                opacity: root.powerMenuOpen ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                component PowerButton: MouseArea {
                    id: powerButtonMouse

                    property string icon:       ""
                    property string tooltip:    ""
                    property string hoverColor: ""

                    width:  24
                    height: 24

                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor

                    QQC2.ToolTip.text:    tooltip
                    QQC2.ToolTip.visible: containsMouse
                    QQC2.ToolTip.delay:   400

                    Layout.alignment: Qt.AlignVCenter
                    
                    Text { 
                        anchors.centerIn: parent
                        text: icon
                        font.pixelSize: fontSizeLarge
                        font.family:    fontFamilyBase
                        color: powerButtonMouse.containsMouse ? hoverColor : fontColorBase
                        scale: powerButtonMouse.containsPress ? 0.8 : (powerButtonMouse.containsMouse ? 1.15 : 1.0)
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    }
                
                }

                PowerButton {
                    icon:       "⚙"
                    tooltip:    "Reboot to BIOS"
                    hoverColor: "green"
                    onClicked:  sddm.rebootToFirmwareSetup()
                }
                PowerButton {
                    icon:       "󰤄"
                    tooltip:    "Suspend PC"
                    hoverColor: "lightblue"
                    onClicked:  sddm.suspend()
                }
                PowerButton {
                    icon:       "󰜉"
                    tooltip:    "Restart"
                    hoverColor: "orange"
                    onClicked:  sddm.reboot()
                }
                PowerButton {
                    icon:       "󰐥"
                    tooltip:    "Power Off"
                    hoverColor: "red"
                    onClicked:  sddm.powerOff()
                }
            }

            Rectangle {
                id: powerOptionsButton

                width:  56
                height: 56
                radius: radiusBase
                
                anchors.right: parent.right
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: radiusBase
                    color: "#ffffff"
                    opacity: mainPowerMouse.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "" 
                    font.pixelSize: fontSizeLarge
                    font.family:    fontFamilyBase
                    color: root.powerMenuOpen || mainPowerMouse.containsMouse ? fontColorHover : fontColorBase
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: mainPowerMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor

                    QQC2.ToolTip.text:    "Power Options"
                    QQC2.ToolTip.visible: containsMouse
                    QQC2.ToolTip.delay:   400
                    
                    onClicked: {
                        root.powerMenuOpen = !root.powerMenuOpen;
                        root.sessionPopupOpen = false;
                        root.userPopupOpen = false;
                    }
                }
            }
        }
    }


    // User Selection
    Rectangle {
        id: userContainer

        visible: primaryScreen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           passwordContainer.top
        anchors.bottomMargin:     Screen.height * topBorderMargin / 2

        width:  Screen.width * componentWidth
        height: Screen.height * componentHeight
        radius: radiusBase

        z: 10

        color:        backgroundBase
        border.color: borderBase
        border.width: borderWidthBase

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true

            shadowBlur:  shadowBlur
            shadowColor: shadowBase

            shadowHorizontalOffset: shadowOffset
            shadowVerticalOffset:   shadowOffset
        }

        MouseArea {
            id: userMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor

            onClicked: { 
                root.userPopupOpen = !root.userPopupOpen; 
                root.sessionPopupOpen = false; 
                root.powerMenuOpen = false; 
            }
        }

        Rectangle {
            anchors.fill: parent

            radius: radiusBase
            color: "#ffffff"
            opacity: userMouseArea.containsMouse ? 0.08 : 0.0

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Row {            
            anchors.centerIn: parent

            spacing: 12

            Text { 
                text: ""

                font.pixelSize: fontSizeBase
                font.family:    fontFamilyBase
                color:          fontColorBase

                anchors.verticalCenter: parent.verticalCenter
            }

            Text { 
                text: userSelector.currentText ? (userSelector.currentText.charAt(0).toUpperCase() + userSelector.currentText.slice(1)) : "Select User"

                color:          fontColorBase
                font.pixelSize: fontSizeBase
                font.weight:    Font.Medium
                font.family:    fontFamilyBase

                elide:          Text.ElideRight 

                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text { 
            text: ""
            color:          fontColorBase
            font.pixelSize: fontSizeBase
            font.family:    fontFamilyBase
            
            anchors.right:       parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // User Pop UP
    Rectangle {
        id: userPopup

        width:  sessionContainer.width
        height: Math.min( (Screen.height * componentHeight * userModel.count) + 10 , Screen.height * 0.8)

        color:        backgroundBase
        border.color: borderBase
        border.width: borderWidthBase

        radius: radiusBase

        z: 100

        anchors.bottom:           userContainer.top
        anchors.horizontalCenter: userContainer.horizontalCenter
        anchors.bottomMargin:     root.userPopupOpen ? 15 : 0

        opacity: root.userPopupOpen ? 1.0 : 0.0

        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } } 
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        ListView {
            model: userModel

            anchors.fill:    parent
            anchors.margins: 4

            clip: true
            
            delegate: Rectangle {
                id: userDelegate

                required property int index
                required property string name
                
                width:  ListView.view.width
                height: Screen.height * componentHeight
                color:  "transparent"
                radius: radiusBase
                
                Rectangle { 
                    anchors.fill: parent

                    color:  "#ffffff"
                    radius: radiusBase
                    opacity: userEntryMouse.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } } 
                }
                
                Text { 
                    anchors.centerIn: parent

                    text: userDelegate.name ? (userDelegate.name.charAt(0).toUpperCase() + userDelegate.name.slice(1)) : ""
                    
                    color:          fontColorBase
                    font.pixelSize: fontSizeBase
                    font.family:    fontFamilyBase
                }
                
                MouseArea { 
                    id: userEntryMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor

                    onClicked: { 
                        root.currentUserIndex = userDelegate.index; 
                        root.userPopupOpen = false; 
                    } 
                }
            }
        }
    }

    
    // Password Input
    Rectangle {
        id: passwordContainer

        visible: primaryScreen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           submitButton.top
        anchors.bottomMargin:     Screen.height * topBorderMargin / 2

        width:  Screen.width * componentWidth
        height: Screen.height * componentHeight
        radius: radiusBase

        color:        passwordInputColor
        border.width: borderWidthBase
        
        property color errorBorderColor: borderBase
        border.color: errorBorderColor

        // The Shake & Flash Animation
        SequentialAnimation {
            id: shakeAnimation

            PropertyAction { 
                target:   passwordContainer
                property: "errorBorderColor"
                value:    "red" 
            }

            NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; from: 0; to: -12; duration: 100 }
            NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; from: -12; to: 12; duration: 100 }
            NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; from: 12; to: -12; duration: 100 }
            NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; from: -12; to: 12; duration: 100 }
            NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; from: 12; to: 0; duration: 100 }

            ColorAnimation { 
                target:   passwordContainer
                property: "errorBorderColor"
                to:       borderBase
                duration: 500
            }
        }

        TextInput {
            id: passwordInput

            anchors.fill:        parent
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment:   TextInput.AlignVCenter

            leftPadding:  16
            rightPadding: 16
            selectByMouse: true

            echoMode: TextInput.Password

            color:          fontColorBase
            font.pixelSize: fontSizeBase
            font.family:    fontFamilyBase

            focus: true
            
            Keys.onReturnPressed: attemptLogin()
            Keys.onEnterPressed:  attemptLogin()

            Keys.onTabPressed: function(event) {
                if (userModel.count > 0) {
                    root.currentUserIndex = (root.currentUserIndex + 1) % userModel.count;
                }
                event.accepted = true;
            }
            
            Keys.onBacktabPressed: function(event) {
                if (sessionModel.count > 0) {
                    root.currentSessionIndex = (root.currentSessionIndex + 1) % sessionModel.count;
                }
                event.accepted = true;
            }
        }

        Text {
            anchors.centerIn: parent

            text: qsTr("Enter your password...")

            color:          fontColorBase
            font.pixelSize: fontSizeBase
            font.family:    fontFamilyBase

            visible: !passwordInput.activeFocus && passwordInput.text.length === 0
        }
    }


    // Submit button
    Rectangle {
        id: submitButton
        
        visible: primaryScreen
        
        width:  Screen.width * componentWidth
        height: Screen.height * componentHeight
        radius: radiusBase

        border.color: borderBase
        border.width: borderWidthBase

        color:  backgroundBase
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     Screen.height * topBorderMargin
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true

            shadowBlur:  shadowBlur
            shadowColor: shadowBase

            shadowHorizontalOffset: shadowOffset
            shadowVerticalOffset:   shadowOffset
        }
        
        Rectangle { 
            anchors.fill: parent
            
            radius: radiusBase
            color:  "#ffffff"
            opacity: submitMouse.containsPress ? 0.15 : (submitMouse.containsMouse ? 0.12 : 0.0)
            
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } } 
            Behavior on color { ColorAnimation { duration: 150 } } 
        }
        
        Text { 
            anchors.centerIn: parent
            text: "󰍂"
            
            color:          fontColorBase
            font.pixelSize: fontSizeBase
            font.family:    fontFamilyBase

            font.bold: true 
        }
        
        MouseArea { 
            id: submitMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor

            onClicked: attemptLogin() 
        }
        
        scale: submitMouse.containsPress ? 0.95 : (submitMouse.containsMouse ? 1.02 : 1.0)
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }




    // SECONDARY MONITOR (s) //
    Rectangle {
        anchors.fill: parent
        color:        secondaryMonitorBgColor
        visible:      !primaryScreen
        
        Text {
            text: secondaryMonitorQuote

            anchors.centerIn: parent
            font.pixelSize:   Screen.height * 0.1
            font.family:      fontFamilyBase
            color:            fontColorBase
        }
    }
}
import QtQuick 2.12
import QtQuick.Controls 2.12 as QCC
import QtMultimedia 5.12
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import QtWebEngine 1.9
import AudioWriter 1.0


MainView {
    id: root
    applicationName: "signalut.pparent"
    width: units.gu(45)
    height: units.gu(80)
    property bool pushed: false
    
    Component.onCompleted: {
        config.micState=0
    }
    visible: Qt.application.active
    
    onVisibleChanged: {
        if ( Qt.application.active == false && pushed == true)
        {
        Qt.quit()  
        }
    }


    AudioWriter {
    id:w
    }

    Timer {
        id: myTimer
        interval: 1000       // 1000 ms = 1 seconde
        repeat: true          // répète indéfiniment
        running: false         // démarre automatiquement

        onTriggered: {
           if (w.recordingDuration() > 500 )
           {
               pushed=true;
               button1.visible=false;
               overlayText.text="Signal is starting..."
               config.micState=4
           }
        }
    }
    
    Settings {
        id: config
        category: "MicState"
        property int micState: 0
    }
    
        
        
    Page {
        id: permissionPage
        anchors.fill: parent
        title: "Signal UT"
                

        Rectangle {
            anchors.fill: parent
            color: "#3640fd"

            Column {
                id: content
                spacing: units.gu(4)
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: units.gu(6)
                }

                // --- Logo app ---
                Image {
                    id: appLogo
                    source: "icon.png"
                    width: units.gu(20)
                    height: units.gu(20)
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // --- Titre ---
                Label {
                    text: "Welcome to Signal UT!"
                    fontSize: "large"
                    font.bold: true
                    color: "white"
                    font.pixelSize: units.gu(3.5)
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // --- Icône Micro ---
                Image {
                    id: micIcon
                    source: "mic.png"
                    width: units.gu(7)
                    height: units.gu(7)
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // --- Question ---
                Label {
                    id: textMic
                    text: "Before anything, would you like to allow the application to access microphone?"
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.pixelSize: units.gu(2.5)
                    wrapMode: Text.WordWrap
                    width: units.gu(35)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // --- Boutons ---
                Column {
                    spacing: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter

                    // ALLOW NOW
                    QCC.Button {
                        id: button1
                        text: "Allow now"
                        width: units.gu(25)
                        height: units.gu(5)
                        font.pixelSize: units.gu(2.2)
                        onClicked: {
                            overlayText.text="Please allow microphone\n If you can't restart app and/or lomiri"
                            w.start("/dev/null");
                            overlayText.visible=true
                            loadingIndicator.visible=true
                            button2.visible=false
                            button3.visible=false
                            micIcon.visible=false
                            textMic.visible=false
                            config.micState=3
                            myTimer.running=true
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // ASK ME NEXT TIME
                    QCC.Button {
                        id: button2
                        text: "Ask me next time"
                        width: units.gu(25)
                        height: units.gu(5)
                        font.pixelSize: units.gu(2.2)
                        onClicked: {
                            config.micState=2
                            overlayText.visible=true
                            loadingIndicator.visible=true
                            pushed=true
                            button1.visible=false
                            button2.visible=false
                            button3.visible=false
                            micIcon.visible=false
                            textMic.visible=false
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // DISALLOW FOREVER
                    QCC.Button {
                        id: button3
                        text: "Disallow forever"
                        width: units.gu(25)
                        height: units.gu(5)
                        font.pixelSize: units.gu(2.2)
                        onClicked: {
                            config.micState=1
                            overlayText.visible=true
                            loadingIndicator.visible=true
                            pushed=true
                            button1.visible=false
                            button2.visible=false
                            button3.visible=false   
                            micIcon.visible=false
                            textMic.visible=false
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                            // 2°) Indicateur circulaire
                    QCC.BusyIndicator {
                    id: loadingIndicator
                    visible: false
                    anchors.horizontalCenter: parent.horizontalCenter

                    contentItem: Item {
                        implicitWidth: units.gu(7)
                        implicitHeight: units.gu(7)

                        Item {
                            id: item
                            x: parent.width / 2 - units.gu(3.5)
                            y: parent.height / 2 - units.gu(3.5)
                            width: units.gu(7)
                            height: units.gu(7)
                            opacity: loadingIndicator.running ? 1 : 0

                            Behavior on opacity {
                                OpacityAnimator {
                                    duration: 250
                                }
                            }

                            RotationAnimator {
                                target: item
                                running: loadingIndicator.visible && loadingIndicator.running
                                from: 0
                                to: 360
                                loops: Animation.Infinite
                                duration: 1250
                            }

                            Repeater {
                                id: repeater
                                model: 6

                                Rectangle {
                                    x: item.width / 2 - width / 2
                                    y: item.height / 2 - height / 2
                                    implicitWidth: units.gu(1.2)
                                    implicitHeight: units.gu(1.2)
                                    radius: units.gu(0.6)
                                    color: "white"
                                    transform: [
                                        Translate {
                                            y: -Math.min(item.width, item.height) * 0.5 + 5
                                        },
                                        Rotation {
                                            angle: index / repeater.count * 360
                                            origin.x: units.gu(0.6)
                                            origin.y: units.gu(0.6)
                                        }
                                    ]
                                }                            }
                        }
                    }
                }

                    // 3°) Texte sur deux lignes
                    Text {
                        id: overlayText
                        visible: false
                        text: "Signal is starting..."
                        color: "white"
                        font.pixelSize: units.gu(2.5)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }


    }
}

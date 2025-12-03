/*
 * Copyright (C) 2016 Stefano Verzegnassi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License 3 as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see http://www.gnu.org/licenses/.
 */

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3
import Pparent.DownloadHelper 1.0
import Ubuntu.Components.Themes.SuruDark 1.1

MainView {
    property var appID: "signalut.pparent";
    property var hook: "signalut";  
    
Page{
    
    theme.name: "Ubuntu.Components.Themes.SuruDark"
    
    id: picker
    property var activeTransfer
    property var handler
    property var contentType

    signal cancel()
    signal imported(string fileUrl)

    StyleHints {
        colorScheme: UbuntuColorScheme.Dark
    }
    DownloadHelper {
        id: downloadHelper
        blob_path: "/home/phablet/.cache/signalut.pparent/downloads/"
    }  
    
  Timer {
        id: timerquit
        interval: 2000      // 2 secondes
        running: false
        repeat: false
        onTriggered: Qt.quit()
    }
    header:PageHeader {
        title: i18n.tr("Export file")
        // on remplace le bouton back par une action custom
        leadingActionBar.actions: [
                Action {
                        iconName: "back"
                        text: "Back"
                        onTriggered: {
                           Qt.quit()
                        }
                }
        ]
        
    }
    ContentPeerPicker {
        anchors {
            fill: parent
            topMargin: picker.header.height
        }

        visible: parent.visible
        showTitle: false
        contentType: ContentType.All
        handler: ContentHandler.Destination

        onPeerSelected: {
            picker.activeTransfer = peer.request()
            picker.activeTransfer.stateChanged.connect(function() {
                if (picker.activeTransfer.state === ContentTransfer.InProgress) {
                    console.log("Export: In progress");
                    let output = downloadHelper.getLastDownloaded()
                    let url = Qt.resolvedUrl("file://"+output)
                    console.log("Exportintg:"+url);
                    picker.activeTransfer.items = [ resultComponent.createObject(parent, {"url": url}) ];
                    picker.activeTransfer.state = ContentTransfer.Charged;
                    timerquit.running = true
                }
            })
        }

        onCancelPressed: {
            pageStack.pop()
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: picker.activeTransfer
    }

    Component {
        id: resultComponent
        ContentItem {}
    }
    }
}

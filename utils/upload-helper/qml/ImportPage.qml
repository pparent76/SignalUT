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
import Pparent.UploadHelper 1.0
import Ubuntu.Components.Themes.SuruDark 1.1

MainView {
    property var appID: "signalut.pparent";
    property var hook: "signalut";
    
    UploadHelper {
        id: uploadHelper
        blob_path: "/home/phablet/.cache/signalut.pparent/downloads/"
    }  
    Timer {
        id: timerquit
        interval: 1000      // 2 secondes
        running: false
        repeat: false
        onTriggered: Qt.quit()
    }
Page {
    id: picker
    theme.name: "Ubuntu.Components.Themes.SuruDark"
	property var activeTransfer

	property var url
	property var handler: ContentHandler.Source
	property var contentType: ContentType.All

    signal cancel()
    signal imported(string fileUrl)

    header: PageHeader {
        title: i18n.tr("Choose")
        }

    
  
    
    ContentPeerPicker {
        anchors { fill: parent; topMargin: picker.header.height }
        visible: parent.visible
        showTitle: false
        contentType: picker.contentType
        handler: picker.handler //ContentHandler.Source

        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single
            picker.activeTransfer = peer.request()
            picker.activeTransfer.stateChanged.connect(function() {
                //TODO uploadHelper
                if (picker.activeTransfer.state === ContentTransfer.Charged) {
                    console.log("Charged");
                    var res=String(picker.activeTransfer.items[0].url);
                    console.log(res.replace("file://", "").trim());
                    uploadHelper.uploadFile(res.replace("file://", "").trim());
                    timerquit.running=true;
                   // picker.activeTransfer = null;
                }
            })
        }


        onCancelPressed: {
            console.log("Cancelled")
            //TODO handle cancel
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

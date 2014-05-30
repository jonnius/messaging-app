/*
 * Copyright 2012-2013 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0

ListItem.Empty {
    id: delegate
    property bool groupChat: participants.length > 1
    property string searchTerm
    property string groupChatLabel: {
        var firstRecipient
        if (unknownContact) {
            firstRecipient = delegateHelper.phoneNumber
        } else {
            firstRecipient = delegateHelper.alias
        }

        if (participants.length > 1)
            return firstRecipient + " +" + String(participants.length-1)
        return firstRecipient
    }
    property bool unknownContact: delegateHelper.isUnknown
    property bool selectionMode: false
    anchors.left: parent.left
    anchors.right: parent.right
    height: units.gu(10)
    showDivider: false
    // WORKAROUND: history-service can't filter by contact names
    onSearchTermChanged: {
        var found = false
        var searchTermLowerCase = searchTerm.toLowerCase()
        if (searchTerm !== "") {
            if ((delegateHelper.phoneNumber.toLowerCase().search(searchTermLowerCase) !== -1)
            || (!unknownContact && delegateHelper.alias.toLowerCase().search(searchTermLowerCase) !== -1)) {
                found = true
            }
        } else {
            found = true
        }
   
        height = found ? units.gu(10) : 0
    }

    // FIXME: the selected state should be handled by the UITK
    Item {
        id: selection

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: visible ? units.gu(6) : 0
        opacity: selectionMode ? 1.0 : 0.0
        visible: opacity > 0.0

        Behavior on width {
            UbuntuNumberAnimation { }
        }

        Behavior on opacity {
            UbuntuNumberAnimation { }
        }

        Rectangle {
            id: selectionIndicator
            anchors.fill: parent
            color: "black"
            opacity: 0.2
        }

        Icon {
            anchors.centerIn: selectionIndicator
            name: "select"
            height: units.gu(3)
            width: units.gu(3)
            color: selected ? "white" : "grey"

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }
    }

    UbuntuShape {
        id: avatar
        property bool defaultAvatar: delegateHelper.avatar === "" && !unknownContact
        height: units.gu(6)
        width: units.gu(6)
        radius: "medium"
        color: Theme.palette.normal.overlay
        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
        image: Image {
            id: avatarImage
            visible: delegateHelper.avatar !== ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: delegateHelper.avatar
            asynchronous: true
            sourceSize.width: width * 1.5
            sourceSize.height: height * 1.5
        }

        Label {
            property string avatarLabel: {
                if (unknownContact) {
                    return ""
                }

                var nameArray = delegateHelper.alias.split(" ")
                var finalName = ""
                if (nameArray.length === 1) {
                    finalName = nameArray[0][0]
                } else if (nameArray.length > 1) {
                    finalName = nameArray[0][0] + nameArray[1][0]
                }
                return finalName
            }
            visible: avatar.defaultAvatar
            color: "#752571"
            anchors.centerIn: parent
            fontSize: "medium"
            text: avatarLabel
            font.weight: Font.Light
            font.capitalization: Font.AllUppercase
        }
    }

    Label {
        id: contactName
        anchors {
            top: avatar.top
            topMargin: units.gu(0.5)
            left: avatar.right
            leftMargin: units.gu(1)
        }
        font.weight: Font.Light
        fontSize: "medium"
        color: "#752571"
        text: groupChat ? groupChatLabel : unknownContact ? delegateHelper.phoneNumber : delegateHelper.alias
    }

    Label {
        id: time
        anchors {
            verticalCenter: contactName.verticalCenter
            right: selection.left
            rightMargin: units.gu(2)
        }
        fontSize: "x-small"
        color: "#5d5d5d"
        text: Qt.formatDateTime(eventTimestamp,"h:mm ap")
    }

//    Label {
//        id: phoneType
//        anchors {
//            top: contactName.bottom
//            left: contactName.left
//        }
//        text: delegateHelper.phoneNumberSubTypeLabel
//        color: "gray"
//        fontSize: "x-small"
//    }

    Label {
        id: latestMessage
        height: units.gu(3)
        anchors {
            top: contactName.bottom
            topMargin: units.gu(0.5)
            left: contactName.left
            right: time.left
            rightMargin: units.gu(3)
        }
        elide: Text.ElideRight
        maximumLineCount: 2
        fontSize: "x-small"
        wrapMode: Text.WordWrap
        text: eventTextMessage == undefined ? "" : eventTextMessage
        font.weight: Font.Light
        //opacity: 0.2
    }
    onItemRemoved: {
        threadModel.removeThread(accountId, threadId, type)
    }

    Item {
        id: delegateHelper
        property alias phoneNumber: watcherInternal.phoneNumber
        property alias alias: watcherInternal.alias
        property alias avatar: watcherInternal.avatar
        property alias contactId: watcherInternal.contactId
        property alias subTypes: phoneDetail.subTypes
        property alias contexts: phoneDetail.contexts
        property alias isUnknown: watcherInternal.isUnknown
        property string phoneNumberSubTypeLabel: ""

        function updateSubTypeLabel() {
            phoneNumberSubTypeLabel = isUnknown ? "" : phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label
        }

        onSubTypesChanged: updateSubTypeLabel();
        onContextsChanged: updateSubTypeLabel();
        onIsUnknownChanged: updateSubTypeLabel();

        ContactWatcher {
            id: watcherInternal
            phoneNumber: participants[0]
        }

        PhoneNumber {
            id: phoneDetail
            contexts: watcherInternal.phoneNumberContexts
            subTypes: watcherInternal.phoneNumberSubTypes
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
        }
    }
}

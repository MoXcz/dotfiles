import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Content of one lock surface. Purely presentational: every piece of state
// is read from `lock` (the Lock root) so all screens stay in sync.
Item {
  id: root

  required property var lock

  readonly property bool hasImage: String(Config.lock.background || "").length > 0

  function focusInput() { input.forceActiveFocus() }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Image {
    anchors.fill: parent
    visible: root.hasImage
    source: root.hasImage ? Util.fileUrl(Config.lock.background) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: root.width
    sourceSize.height: root.height
  }

  // Cheap stand-in for blur: a tinted veil keeps the card legible on any image.
  Rectangle {
    anchors.fill: parent
    color: root.hasImage
      ? Util.alpha(Theme.background, Config.lock.blurBackground ? 0.6 : 0.3)
      : Theme.background
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.focusInput()
  }

  Card {
    id: card
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: shake.offset
    width: 360
    height: column.implicitHeight + Theme.spaceXl * 2
    color: Util.alpha(Theme.surface, root.hasImage ? 0.92 : 1)

    Column {
      id: column
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - Theme.spaceXl * 2
      spacing: Theme.space

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, Config.lock.clockFormat)
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontDisplay
        font.bold: true
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, Config.lock.dateFormat)
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontTitle
      }

      Item { width: 1; height: Theme.spaceLg }

      Rectangle {
        width: parent.width
        height: 40
        radius: Theme.cornerRadius
        color: Theme.surfaceAlt
        border.width: Theme.borderWidth
        border.color: root.lock.failed ? Theme.urgent
                    : input.activeFocus ? Theme.accent
                    : Theme.border

        TextInput {
          id: input
          anchors.fill: parent
          anchors.leftMargin: Theme.spaceLg
          anchors.rightMargin: Theme.spaceLg
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          echoMode: TextInput.Password
          passwordCharacter: "•"
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontTitle
          selectByMouse: false
          activeFocusOnPress: true
          focus: true
          readOnly: root.lock.authenticating
          clip: true

          // Mirror the shared password without creating a binding loop:
          // edits flow up through onTextEdited, resets flow down here.
          Connections {
            target: root.lock
            function onPasswordChanged() {
              if (input.text !== root.lock.password) input.text = root.lock.password
            }
          }

          onTextEdited: root.lock.password = text
          onAccepted: root.lock.submit()

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              root.lock.password = ""
              root.lock.failed = false
              event.accepted = true
            }
          }

          Text {
            anchors.centerIn: parent
            visible: input.text.length === 0 && !root.lock.authenticating
            text: root.lock.userName ? root.lock.userName + "'s password" : "Password"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
        }
      }

      Text {
        width: parent.width
        height: Theme.fontBody * 1.6
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.lock.status
        color: root.lock.failed ? Theme.urgent : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
      }
    }
  }

  // Horizontal jolt on a rejected password.
  Item {
    id: shake
    property real offset: 0
    SequentialAnimation {
      id: shakeAnim
      loops: 3
      NumberAnimation { target: shake; property: "offset"; to: -8; duration: 40 }
      NumberAnimation { target: shake; property: "offset"; to: 8; duration: 80 }
      NumberAnimation { target: shake; property: "offset"; to: 0; duration: 40 }
    }
  }

  Connections {
    target: root.lock
    function onFailure() {
      shakeAnim.restart()
      root.focusInput()
    }
  }

  // Surfaces are created when the lock engages, so grabbing focus here
  // means the first keystroke after locking already lands in the field.
  Component.onCompleted: Qt.callLater(root.focusInput)
}

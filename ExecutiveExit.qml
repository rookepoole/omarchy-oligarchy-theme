import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property bool opened: false
  property int selectedIndex: 0
  property int pendingIndex: -1
  property string lastAction: "NONE // MARKETS REMAIN OPEN"

  readonly property var actions: [
    { id: "lock", code: "01", title: "LOCK ESTATE", detail: "Secure the perimeter; retain all positions.", command: ["omarchy-system-lock"], disruptive: false, urgent: false },
    { id: "suspend", code: "02", title: "SUSPEND LABOR", detail: "Pause operations until capital reawakens.", command: ["systemctl", "suspend"], disruptive: true, urgent: false },
    { id: "logout", code: "03", title: "EXIT MARKET", detail: "Close the current executive session.", command: ["omarchy-system-logout"], disruptive: true, urgent: false },
    { id: "reboot", code: "04", title: "RESTRUCTURE", detail: "Reorganize the machine from first principles.", command: ["omarchy-system-reboot"], disruptive: true, urgent: true },
    { id: "shutdown", code: "05", title: "LIQUIDATE PORTFOLIO", detail: "Power off every remaining subsidiary.", command: ["omarchy-system-shutdown"], disruptive: true, urgent: true },
    { id: "return", code: "06", title: "RETURN TO MARKETS", detail: "Adjourn without changing beneficial ownership.", command: [], disruptive: false, urgent: false }
  ]

  function boundedIndex(value) {
    var count = actions.length
    return ((Math.floor(Number(value) || 0) % count) + count) % count
  }

  function actionIndexById(id) {
    for (var i = 0; i < actions.length; i++)
      if (actions[i].id === String(id || "")) return i
    return 0
  }

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }
    selectedIndex = actionIndexById(payload.action)
    pendingIndex = -1
    confirmDialog.opened = false
    opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    confirmDialog.opened = false
    pendingIndex = -1
    opened = false
  }

  function dismiss() {
    close()
  }

  function toggle() {
    if (opened) dismiss()
    else open("{}")
  }

  function moveSelection(delta) {
    selectedIndex = boundedIndex(selectedIndex + delta)
  }

  function confirmationMessage(action) {
    return "MOTION // " + action.title + "\n\n" + action.detail +
      "\n\nThis changes the active system session. A quorum of one is legally sufficient."
  }

  function requestAction(index) {
    var bounded = boundedIndex(index)
    var action = actions[bounded]
    selectedIndex = bounded

    if (action.id === "return") {
      lastAction = "MEETING ADJOURNED // NO VALUE DESTROYED"
      dismiss()
      return
    }

    if (!action.disruptive) {
      executeAction(bounded)
      return
    }

    pendingIndex = bounded
    confirmDialog.message = confirmationMessage(action)
    confirmDialog.cancelText = "TABLE"
    confirmDialog.confirmText = "PASS MOTION"
    confirmDialog.selectedIndex = 0
    confirmDialog.opened = true
  }

  function cancelPending() {
    confirmDialog.opened = false
    pendingIndex = -1
    lastAction = "MOTION TABLED // MARKETS REMAIN OPEN"
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function executePending() {
    var index = pendingIndex
    confirmDialog.opened = false
    pendingIndex = -1
    if (index >= 0) executeAction(index)
  }

  function executeAction(index) {
    var action = actions[boundedIndex(index)]
    if (!action.command || action.command.length === 0) {
      dismiss()
      return
    }
    lastAction = "MOTION CARRIED // " + action.title
    dismiss()
    Quickshell.execDetached(action.command)
  }

  function statusJson() {
    return JSON.stringify({
      opened: opened,
      selected: actions[selectedIndex].id,
      pending: pendingIndex >= 0 ? actions[pendingIndex].id : "",
      confirming: confirmDialog.opened,
      lastAction: lastAction
    })
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "oligarchy-executive-exit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Util.alpha(Color.background, 0.94)
    }

    Item {
      anchors.fill: parent
      opacity: 0.24

      Repeater {
        model: Math.ceil(panel.width / Style.space(80)) + 1
        Rectangle {
          required property int index
          x: index * Style.space(80)
          width: 1
          height: panel.height
          color: Color.accent
        }
      }

      Repeater {
        model: Math.ceil(panel.height / Style.space(80)) + 1
        Rectangle {
          required property int index
          y: index * Style.space(80)
          width: panel.width
          height: 1
          color: Color.accent
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: Math.min(panel.width - Style.space(48), Style.space(760))
      height: Math.min(panel.height - Style.space(48), content.implicitHeight + Style.space(48))
      anchors.centerIn: parent
      color: Color.background
      borderSpec: Border.flat(Color.accent, Math.max(1, Style.normalBorderWidth))
      radius: 0

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (confirmDialog.opened) {
            event.accepted = confirmDialog.handleKey(event)
            return
          }

          if (event.key === Qt.Key_Escape) {
            root.dismiss()
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.moveSelection(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            root.moveSelection(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Backtab) {
            root.moveSelection(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.moveSelection(-2)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.moveSelection(2)
            event.accepted = true
          } else if (event.key === Qt.Key_Home) {
            root.selectedIndex = 0
            event.accepted = true
          } else if (event.key === Qt.Key_End) {
            root.selectedIndex = root.actions.length - 1
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.requestAction(root.selectedIndex)
            event.accepted = true
          } else if (/^[1-6]$/.test(event.text || "")) {
            root.requestAction(Number(event.text) - 1)
            event.accepted = true
          }
        }
      }

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Style.space(24)
        spacing: Style.space(16)

        Row {
          width: parent.width
          spacing: Style.space(13)

          Rectangle {
            width: Style.space(8)
            height: heading.implicitHeight
            color: Color.accent
          }

          Column {
            id: heading
            width: parent.width - Style.space(132)
            spacing: Style.space(3)

            Text {
              width: parent.width
              text: "EXECUTIVE EXIT COMMITTEE"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.bold: true
              font.letterSpacing: 1
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: "SPECIAL SESSION // A QUORUM OF ONE IS PRESENT"
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
              elide: Text.ElideRight
            }
          }

          BorderSurface {
            width: Style.space(108)
            height: Style.space(38)
            color: "transparent"
            borderSpec: Border.flat("#D4B35A", Math.max(1, Style.normalBorderWidth))
            radius: 0
            Text {
              anchors.centerIn: parent
              text: "MARKETS OPEN"
              color: "#D4B35A"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }
        }

        PanelSeparator { width: parent.width; foreground: Color.foreground }

        Text {
          width: parent.width
          text: "Select the disposition of the current executive session. Disruptive motions require a second vote."
          color: Color.foreground
          opacity: 0.76
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        Grid {
          width: parent.width
          columns: 2
          spacing: Style.space(8)

          Repeater {
            model: root.actions

            BorderSurface {
              required property var modelData
              required property int index
              readonly property bool selected: root.selectedIndex === index
              readonly property color actionColor: modelData.urgent ? Color.urgent : Color.accent

              width: (parent.width - parent.spacing) / 2
              height: Style.space(76)
              color: selected ? Util.alpha(actionColor, 0.13) : Util.alpha(Color.foreground, 0.025)
              borderSpec: Border.flat(selected ? actionColor : Util.alpha(Color.foreground, 0.25), selected ? Math.max(2, Style.normalBorderWidth) : Math.max(1, Style.normalBorderWidth))
              radius: 0

              Row {
                anchors.fill: parent
                anchors.margins: Style.space(11)
                spacing: Style.space(12)

                Text {
                  width: Style.space(32)
                  text: modelData.code
                  color: actionColor
                  font.family: Style.font.family
                  font.pixelSize: Style.font.title
                  font.bold: true
                }

                Column {
                  width: parent.width - Style.space(44)
                  spacing: Style.space(3)

                  Text {
                    width: parent.width
                    text: modelData.title
                    color: selected ? actionColor : Color.foreground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: true
                    elide: Text.ElideRight
                  }
                  Text {
                    width: parent.width
                    text: modelData.detail
                    color: Color.foreground
                    opacity: 0.58
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIndex = index
                onClicked: root.requestAction(index)
              }
            }
          }
        }

        Row {
          width: parent.width

          Text {
            width: parent.width * 0.62
            text: "ARROWS / TAB MOVE  //  ENTER PASSES  //  ESC ADJOURNS"
            color: Qt.darker(Color.foreground, 1.8)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width * 0.38
            text: root.lastAction
            color: "#D4B35A"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
          }
        }
      }
    }

    ConfirmDialog {
      id: confirmDialog
      anchors.fill: parent
      background: Color.background
      foreground: Color.foreground
      selectedText: Color.accent
      cornerRadius: 0
      onCanceled: root.cancelPending()
      onConfirmed: root.executePending()
    }
  }
}

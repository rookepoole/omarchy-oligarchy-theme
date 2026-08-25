import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "TaxModel.js" as TaxModel

Panel {
  id: root
  moduleName: "rookepoole.oligarchy-tax-department"
  ipcTarget: moduleName

  readonly property string wallet: TaxModel.WALLET
  readonly property string explorerUrl: "https://basescan.org/address/" + wallet
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property color contentUrgent: bar ? bar.urgent : Color.urgent
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  property int serial: 1040
  property var currentAssessment: TaxModel.assessment(serial)
  property int actionIndex: 0
  property bool cursorActive: false
  property string receipt: "PUBLIC COLLECTION ADDRESS"

  function reassess() {
    serial = (serial * 48271 + 17) % 1000000
    currentAssessment = TaxModel.assessment(serial)
    receipt = "ASSESSMENT " + currentAssessment.filing + " ISSUED"
  }

  function copyAddress() {
    Quickshell.execDetached([
      "bash", "-c",
      "printf %s " + Util.shellQuote(wallet) +
        " | wl-copy && omarchy-notification-send 'Treasury address copied // Base 8453' -t 1800"
    ])
    receipt = "ADDRESS COPIED // COMPLIANCE NOTED"
  }

  function openExplorer() {
    Quickshell.execDetached(["xdg-open", explorerUrl])
    receipt = "PUBLIC LEDGER OPENED"
  }

  function activateAction() {
    if (actionIndex === 0) copyAddress()
    else if (actionIndex === 1) openExplorer()
    else reassess()
  }

  function moveAction(delta) {
    cursorActive = true
    actionIndex = (actionIndex + delta + 3) % 3
  }

  onOpenedChanged: if (opened) {
    cursorActive = false
    receipt = "PUBLIC COLLECTION ADDRESS"
  }

  implicitWidth: taxButton.implicitWidth
  implicitHeight: taxButton.implicitHeight

  WidgetButton {
    id: taxButton
    anchors.fill: parent
    bar: root.bar
    text: "TAX"
    fontSize: Style.font.caption
    active: root.opened
    tooltipText: "Department of Oligarch Revenue"
    onPressed: function(button) {
      if (button === Qt.RightButton) root.copyAddress()
      else if (button === Qt.MiddleButton) root.reassess()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: taxButton
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(500))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        var delta = dx !== 0 ? dx : dy
        root.moveAction(delta)
      }
      onActivateRequested: root.activateAction()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        var key = String(text).toLowerCase()
        if (key === "c") root.copyAddress()
        else if (key === "o") root.openExplorer()
        else if (key === "r") root.reassess()
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(deptMark.implicitHeight, heading.implicitHeight, networkBadge.implicitHeight)

          Rectangle {
            id: deptMark
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(7)
            height: Style.space(42)
            color: Color.accent
          }

          Column {
            id: heading
            anchors.left: deptMark.right
            anchors.leftMargin: Style.space(12)
            anchors.right: networkBadge.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: "DEPARTMENT OF OLIGARCH REVENUE"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.receipt
              color: Color.accent
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
              elide: Text.ElideRight
            }
          }

          BorderSurface {
            id: networkBadge
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: badgeText.implicitWidth + Style.space(14)
            implicitHeight: badgeText.implicitHeight + Style.space(8)
            color: "transparent"
            borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)
            radius: Style.cornerRadius

            Text {
              id: badgeText
              anchors.centerIn: parent
              text: "BASE // 8453"
              color: Color.accent
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }
        }

        PanelSeparator {
          foreground: root.contentForeground
        }

        Row {
          width: parent.width
          spacing: Style.space(18)

          BorderSurface {
            width: Style.space(188)
            height: width
            color: "#060806"
            borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)
            radius: 0

            Image {
              anchors.fill: parent
              anchors.margins: Style.space(8)
              source: Qt.resolvedUrl("assets/treasury-qr.png")
              fillMode: Image.PreserveAspectFit
              smooth: false
              mipmap: false
              cache: true
            }
          }

          Column {
            width: parent.width - Style.space(206)
            spacing: Style.space(9)

            Text {
              text: "NOTICE OF ASSESSMENT"
              color: "#D4B35A"
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }

            Text {
              width: parent.width
              text: "PAY YOUR TAXES\nTO THE OLIGARCH."
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.heading
              font.bold: true
              lineHeight: 1.05
            }

            Text {
              text: "TREASURY ADDRESS"
              color: Qt.darker(root.contentForeground, 1.7)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              width: parent.width
              text: TaxModel.splitWallet(root.wallet)
              color: Color.accent
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              lineHeight: 1.05
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          StatCell {
            width: (parent.width - parent.spacing * 2) / 3
            label: "ASSESSMENT"
            value: root.currentAssessment.rate + "%"
            valueColor: Color.accent
          }
          StatCell {
            width: (parent.width - parent.spacing * 2) / 3
            label: "AUDIT RISK"
            value: root.currentAssessment.risk
            valueColor: root.currentAssessment.rate >= 90 ? root.contentUrgent : "#D4B35A"
          }
          StatCell {
            width: (parent.width - parent.spacing * 2) / 3
            label: "EXEMPTIONS"
            value: "DENIED"
            valueColor: root.contentUrgent
          }
        }

        Row {
          id: actionRow
          width: parent.width
          spacing: Style.space(7)

          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "COPY ADDRESS"
            bordered: true
            hasCursor: root.cursorActive && root.actionIndex === 0
            foreground: root.contentForeground
            accent: Color.accent
            fontFamily: root.contentFontFamily
            fontSize: Style.font.caption
            onHovered: function(value) { if (value) { root.cursorActive = true; root.actionIndex = 0 } }
            onClicked: root.copyAddress()
          }
          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "PUBLIC LEDGER"
            bordered: true
            hasCursor: root.cursorActive && root.actionIndex === 1
            foreground: root.contentForeground
            accent: Color.accent
            fontFamily: root.contentFontFamily
            fontSize: Style.font.caption
            onHovered: function(value) { if (value) { root.cursorActive = true; root.actionIndex = 1 } }
            onClicked: root.openExplorer()
          }
          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "REASSESS"
            bordered: true
            hasCursor: root.cursorActive && root.actionIndex === 2
            foreground: root.contentForeground
            accent: Color.accent
            fontFamily: root.contentFontFamily
            fontSize: Style.font.caption
            onHovered: function(value) { if (value) { root.cursorActive = true; root.actionIndex = 2 } }
            onClicked: root.reassess()
          }
        }

        Text {
          width: parent.width
          text: "c copy // o ledger // r reassess // compliance is mandatory"
          color: Qt.darker(root.contentForeground, 1.8)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  component StatCell: BorderSurface {
    property string label: ""
    property string value: ""
    property color valueColor: root.contentForeground

    implicitHeight: statColumn.implicitHeight + Style.space(14)
    color: Util.alpha(root.contentForeground, 0.025)
    borderSpec: Border.controlSpec("normal", root.contentForeground, Color.accent)
    radius: 0

    Column {
      id: statColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(9)
      anchors.rightMargin: Style.space(9)
      spacing: Style.space(3)

      Text {
        width: parent.width
        text: label
        color: Qt.darker(root.contentForeground, 1.8)
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: value
        color: valueColor
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
      }
    }
  }
}

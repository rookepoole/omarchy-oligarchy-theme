import QtQuick
import Quickshell
import Quickshell.Io
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
  readonly property var pageNames: ["REVENUE", "HOLDINGS", "PRIVILEGES", "IDLE CAPITAL"]
  readonly property var pageActionCounts: [3, 1, 4, 4]
  readonly property var pageComponents: [revenuePage, holdingsPage, privilegesPage, screensaverPage]

  property int serial: 1040
  property var currentAssessment: TaxModel.assessment(serial)
  property int pageIndex: 0
  property int actionIndex: 0
  property bool cursorActive: false
  property string receipt: "PUBLIC COLLECTION ADDRESS"
  property var metrics: ({ load: "0.00", memory: 0, disk: 0, uptime: "0H", battery: "PROBING" })

  function reassess() {
    serial = (serial * 48271 + 17) % 1000000
    currentAssessment = TaxModel.assessment(serial)
    receipt = "ASSESSMENT " + currentAssessment.filing + " ISSUED"
  }

  function copyAddress() {
    Quickshell.execDetached([
      "bash", "-c",
      "printf %s " + Util.shellQuote(wallet) +
        " | wl-copy && omarchy-notification-send 'Treasury address copied // Base 8453' 'Voluntary compliance has been noted' -t 1800"
    ])
    receipt = "ADDRESS COPIED // COMPLIANCE NOTED"
  }

  function openExplorer() {
    Quickshell.execDetached(["xdg-open", explorerUrl])
    receipt = "PUBLIC LEDGER OPENED"
  }

  function runSystemAction(command, nextReceipt, closeFirst) {
    receipt = nextReceipt
    if (closeFirst) root.close()
    Quickshell.execDetached(["bash", "-c", command])
  }

  function lockEstate() {
    runSystemAction("omarchy-notification-send 'Estate perimeter secured' 'Re-entry requires proof of beneficial ownership' -t 1400; sleep 0.35; omarchy-system-lock", "ESTATE LOCK REQUESTED", true)
  }

  function toggleSilence() {
    runSystemAction("omarchy-toggle-notification-silencing; omarchy-notification-send 'Staff communications repriced' 'Do Not Disturb toggled by executive order' -t 1800", "STAFF COMMUNICATIONS REPRICED", false)
  }

  function toggleMarkets() {
    runSystemAction("state=$(omarchy-toggle-idle); omarchy-shell -q omarchy.indicators refresh; omarchy-notification-send 'Market hours changed' \"Idle state: $state\" -t 1800", "MARKET HOURS AMENDED", false)
  }

  function captureAsset() {
    runSystemAction("sleep 0.2; omarchy-capture-screenshot fullscreen save", "SCREEN ASSET CAPITALIZED", true)
  }

  function screensaverCall(method, nextReceipt) {
    receipt = nextReceipt
    Quickshell.execDetached(["bash", "-c", "omarchy-shell oligarchy-screensaver " + method + " >/dev/null"])
  }

  function previewScreensaver() {
    root.close()
    screensaverCall("preview", "PRIVATE IDLE CAPITAL PREVIEWED")
  }

  function restoreDefaults() {
    receipt = "PUBLIC MANAGEMENT RESTORED"
    Quickshell.execDetached(["bash", "-c", "omarchy-shell oligarchy-screensaver disable >/dev/null; omarchy-shell oligarchy-screensaver restoreBranding >/dev/null"])
  }

  function refreshMetrics() {
    if (!metricsProcess.running) metricsProcess.running = true
  }

  function setPage(index) {
    pageIndex = ((index % pageNames.length) + pageNames.length) % pageNames.length
    actionIndex = 0
    cursorActive = false
    receipt = pageIndex === 0 ? "PUBLIC COLLECTION ADDRESS"
      : pageIndex === 1 ? "CONSOLIDATED HOLDINGS // LIVE"
      : pageIndex === 2 ? "EXECUTIVE PRIVILEGES // VESTED"
      : "IDLE CAPITAL // FULLY DEPLOYED"
    if (pageIndex === 1) refreshMetrics()
  }

  function moveAction(delta) {
    cursorActive = true
    var count = pageActionCounts[pageIndex]
    actionIndex = (actionIndex + delta + count) % count
  }

  function activateAction() {
    if (pageIndex === 0) {
      if (actionIndex === 0) copyAddress()
      else if (actionIndex === 1) openExplorer()
      else reassess()
    } else if (pageIndex === 1) {
      refreshMetrics()
      receipt = "HOLDINGS MARKED TO MARKET"
    } else if (pageIndex === 2) {
      if (actionIndex === 0) lockEstate()
      else if (actionIndex === 1) toggleSilence()
      else if (actionIndex === 2) toggleMarkets()
      else captureAsset()
    } else {
      if (actionIndex === 0) previewScreensaver()
      else if (actionIndex === 1) screensaverCall("enable", "IDLE CAPITAL PRIVATIZED")
      else if (actionIndex === 2) restoreDefaults()
      else screensaverCall("brand", "INSTITUTIONAL BRANDING INSTALLED")
    }
  }

  function handleTextKey(value) {
    var key = String(value).toLowerCase()
    if (/^[1-4]$/.test(key)) { setPage(Number(key) - 1); return }
    if (key === "[" || key === "q") { setPage(pageIndex - 1); return }
    if (key === "]" || key === "e") { setPage(pageIndex + 1); return }
    if (pageIndex === 0) {
      if (key === "c") copyAddress()
      else if (key === "o") openExplorer()
      else if (key === "r") reassess()
    } else if (pageIndex === 1 && key === "r") {
      refreshMetrics()
    } else if (pageIndex === 2) {
      if (key === "l") lockEstate()
      else if (key === "d") toggleSilence()
      else if (key === "a") toggleMarkets()
      else if (key === "s") captureAsset()
    } else if (pageIndex === 3) {
      if (key === "p") previewScreensaver()
      else if (key === "m") screensaverCall("enable", "IDLE CAPITAL PRIVATIZED")
      else if (key === "x") restoreDefaults()
      else if (key === "b") screensaverCall("brand", "INSTITUTIONAL BRANDING INSTALLED")
    }
  }

  onOpenedChanged: if (opened) {
    cursorActive = false
    receipt = pageIndex === 0 ? "PUBLIC COLLECTION ADDRESS" : receipt
    if (pageIndex === 1) refreshMetrics()
  }

  implicitWidth: taxButton.implicitWidth
  implicitHeight: taxButton.implicitHeight

  WidgetButton {
    id: taxButton
    anchors.fill: parent
    bar: root.bar
    text: "TAX·" + root.currentAssessment.rate
    fontSize: Style.font.caption
    active: root.opened
    tooltipText: "Oligarch Operating System // assessment " + root.currentAssessment.rate + "%"
    onPressed: function(button) {
      if (button === Qt.RightButton) root.copyAddress()
      else if (button === Qt.MiddleButton) root.reassess()
      else root.toggle()
    }
  }

  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: root.reassess()
  }

  Timer {
    interval: 8000
    repeat: true
    running: root.opened && root.pageIndex === 1
    triggeredOnStart: true
    onTriggered: root.refreshMetrics()
  }

  Process {
    id: metricsProcess
    command: [
      "bash", "-c",
      "load=$(awk '{print $1}' /proc/loadavg 2>/dev/null); mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{if(t>0)printf \"%.0f\",(t-a)*100/t;else print 0}' /proc/meminfo 2>/dev/null); disk=$(df -P / 2>/dev/null | awk 'NR==2{gsub(/%/,\"\",$5);print $5}'); up=$(cut -d. -f1 /proc/uptime 2>/dev/null); battery=-1; for f in /sys/class/power_supply/BAT*/capacity; do [[ -f $f ]] || continue; battery=$(<\"$f\"); break; done; printf '%s|%s|%s|%s|%s\\n' \"${load:-0}\" \"${mem:-0}\" \"${disk:-0}\" \"${up:-0}\" \"$battery\""
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.metrics = TaxModel.parseMetrics(text)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: taxButton
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(620))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) { root.moveAction(dx !== 0 ? dx : dy) }
      onActivateRequested: root.activateAction()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.setPage(root.pageIndex + direction) }
      onTextKey: function(text) { root.handleTextKey(text) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(11)

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
              text: "OLIGARCH OPERATING SYSTEM"
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

        Row {
          width: parent.width
          spacing: Style.space(5)
          Repeater {
            model: root.pageNames
            Button {
              required property string modelData
              required property int index
              width: (parent.width - parent.spacing * 3) / 4
              text: (index + 1) + "  " + modelData
              selected: root.pageIndex === index
              bordered: true
              foreground: root.contentForeground
              accent: Color.accent
              fontFamily: root.contentFontFamily
              fontSize: Style.font.caption
              onClicked: root.setPage(index)
            }
          }
        }

        PanelSeparator { foreground: root.contentForeground }

        Loader {
          id: pageLoader
          width: parent.width
          sourceComponent: root.pageComponents[root.pageIndex]
        }

        Text {
          width: parent.width
          text: root.pageIndex === 0 ? "1–4 desks // c copy // o ledger // r reassess"
            : root.pageIndex === 1 ? "real system telemetry // r refresh // no assets were harmed"
            : root.pageIndex === 2 ? "l lock // d silence // a stay awake // s screenshot"
            : "p preview // m make default // x restore // b brand system"
          color: Qt.darker(root.contentForeground, 1.8)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  Component {
    id: revenuePage
    Column {
      width: pageLoader.width
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(16)
        BorderSurface {
          width: Style.space(154)
          height: width
          color: "#060806"
          borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)
          radius: 0
          Image {
            anchors.fill: parent
            anchors.margins: Style.space(7)
            source: Qt.resolvedUrl("assets/treasury-qr.png")
            fillMode: Image.PreserveAspectFit
            smooth: false
            mipmap: false
            cache: true
          }
        }
        Column {
          width: parent.width - Style.space(170)
          spacing: Style.space(7)
          Text { text: "NOTICE OF ASSESSMENT"; color: "#D4B35A"; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
          Text { width: parent.width; text: "PAY YOUR TAXES\nTO THE OLIGARCH."; color: root.contentForeground; font.family: root.contentFontFamily; font.pixelSize: Style.font.heading; font.bold: true; lineHeight: 1.0 }
          Text { text: "TREASURY ADDRESS"; color: Qt.darker(root.contentForeground, 1.7); font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true }
          Text { width: parent.width; text: root.wallet.slice(0, 22) + "\n" + root.wallet.slice(22); color: Color.accent; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; font.bold: true; lineHeight: 1.05 }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(7)
        StatCell { width: (parent.width - parent.spacing * 2) / 3; label: "ASSESSMENT"; value: root.currentAssessment.rate + "%"; valueColor: Color.accent }
        StatCell { width: (parent.width - parent.spacing * 2) / 3; label: "AUDIT RISK"; value: root.currentAssessment.risk; valueColor: root.currentAssessment.rate >= 90 ? root.contentUrgent : "#D4B35A" }
        StatCell { width: (parent.width - parent.spacing * 2) / 3; label: "EXEMPTIONS"; value: "DENIED"; valueColor: root.contentUrgent }
      }

      Row {
        width: parent.width
        spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing * 2) / 3; action: 0; text: "COPY ADDRESS"; onClicked: root.copyAddress() }
        ActionButton { width: (parent.width - parent.spacing * 2) / 3; action: 1; text: "PUBLIC LEDGER"; onClicked: root.openExplorer() }
        ActionButton { width: (parent.width - parent.spacing * 2) / 3; action: 2; text: "REASSESS"; onClicked: root.reassess() }
      }
    }
  }

  Component {
    id: holdingsPage
    Column {
      width: pageLoader.width
      spacing: Style.space(9)
      Text { width: parent.width; text: "CONSOLIDATED HOLDINGS"; color: "#D4B35A"; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { width: parent.width; text: "Your machine, restated as an aggressively managed family office."; color: root.contentForeground; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
      Row {
        width: parent.width; spacing: Style.space(7)
        StatCell { width: (parent.width - parent.spacing * 2) / 3; label: "LABOR LOAD // 1M"; value: root.metrics.load; valueColor: Color.accent }
        StatCell { width: (parent.width - parent.spacing * 2) / 3; label: "LIQUID RESERVES"; value: root.metrics.memory + "% USED"; valueColor: root.metrics.memory > 85 ? root.contentUrgent : "#D4B35A" }
        StatCell { width: (parent.width - parent.spacing * 2) / 3; label: "REAL ESTATE"; value: root.metrics.disk + "% LEASED"; valueColor: root.metrics.disk > 90 ? root.contentUrgent : Color.accent }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        StatCell { width: (parent.width - parent.spacing) / 2; label: "REGULATORY CAPTURE"; value: root.metrics.uptime; valueColor: Color.accent }
        StatCell { width: (parent.width - parent.spacing) / 2; label: "PRIVATE JET FUEL"; value: root.metrics.battery; valueColor: "#D4B35A" }
      }
      BorderSurface {
        width: parent.width
        implicitHeight: marketRow.implicitHeight + Style.space(18)
        color: Util.alpha(root.contentForeground, 0.025)
        borderSpec: Border.controlSpec("normal", root.contentForeground, Color.accent)
        radius: 0
        Row {
          id: marketRow
          anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.space(12); anchors.rightMargin: Style.space(12)
          Text { width: parent.width * 0.20; text: "MARKET"; color: Color.accent; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true }
          Text { width: parent.width * 0.58; text: "SYSTEMIC RISK"; color: root.contentForeground; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; font.bold: true }
          Text { width: parent.width * 0.22; text: "SOCIALIZED"; color: root.contentUrgent; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; horizontalAlignment: Text.AlignRight }
        }
      }
      ActionButton { width: parent.width; action: 0; text: "MARK HOLDINGS TO MARKET"; onClicked: { root.refreshMetrics(); root.receipt = "HOLDINGS MARKED TO MARKET" } }
    }
  }

  Component {
    id: privilegesPage
    Column {
      width: pageLoader.width
      spacing: Style.space(9)
      Text { width: parent.width; text: "EXECUTIVE PRIVILEGES"; color: "#D4B35A"; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { width: parent.width; text: "Useful system controls, renamed after the people most likely to use them."; color: root.contentForeground; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
      Row {
        width: parent.width; spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(48); action: 0; text: "LOCK ESTATE"; onClicked: root.lockEstate() }
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(48); action: 1; text: "SILENCE STAFF"; onClicked: root.toggleSilence() }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(48); action: 2; text: "KEEP MARKETS OPEN"; onClicked: root.toggleMarkets() }
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(48); action: 3; text: "CAPTURE ASSET"; onClicked: root.captureAsset() }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        NoticeCell { width: (parent.width - parent.spacing * 2) / 3; title: "ESTATE"; detail: "SESSION LOCK" }
        NoticeCell { width: (parent.width - parent.spacing * 2) / 3; title: "STAFF"; detail: "DO NOT DISTURB" }
        NoticeCell { width: (parent.width - parent.spacing * 2) / 3; title: "ASSET"; detail: "FULLSCREEN PNG" }
      }
    }
  }

  Component {
    id: screensaverPage
    Column {
      width: pageLoader.width
      spacing: Style.space(9)
      Text { width: parent.width; text: "PRIVATE IDLE CAPITAL"; color: "#D4B35A"; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { width: parent.width; text: "Four native animated scenes rotate every 15 seconds and dismiss on activity. Default integration is opt-in and reversible."; color: root.contentForeground; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
      Row {
        width: parent.width; spacing: Style.space(6)
        Repeater {
          model: TaxModel.SCENES
          NoticeCell {
            required property var modelData
            required property int index
            width: (parent.width - parent.spacing * 3) / 4
            title: "0" + (index + 1)
            detail: modelData.id.replace(/-/g, " ").toUpperCase()
          }
        }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(46); action: 0; text: "PREVIEW SUITE"; onClicked: root.previewScreensaver() }
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(46); action: 1; text: "MAKE IDLE DEFAULT"; onClicked: root.screensaverCall("enable", "IDLE CAPITAL PRIVATIZED") }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(46); action: 2; text: "RESTORE OMARCHY"; onClicked: root.restoreDefaults() }
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(46); action: 3; text: "BRAND THE SYSTEM"; onClicked: root.screensaverCall("brand", "INSTITUTIONAL BRANDING INSTALLED") }
      }
    }
  }

  component ActionButton: Button {
    property int action: 0
    bordered: true
    hasCursor: root.cursorActive && root.actionIndex === action
    foreground: root.contentForeground
    accent: Color.accent
    fontFamily: root.contentFontFamily
    fontSize: Style.font.caption
    onHovered: function(value) { if (value) { root.cursorActive = true; root.actionIndex = action } }
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
      anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(9); anchors.rightMargin: Style.space(9)
      spacing: Style.space(3)
      Text { width: parent.width; text: label; color: Qt.darker(root.contentForeground, 1.8); font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; elide: Text.ElideRight }
      Text { width: parent.width; text: value; color: valueColor; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; font.bold: true; elide: Text.ElideRight }
    }
  }

  component NoticeCell: BorderSurface {
    property string title: ""
    property string detail: ""
    implicitHeight: noticeColumn.implicitHeight + Style.space(14)
    color: "#080B09"
    borderSpec: Border.controlSpec("normal", root.contentForeground, Color.accent)
    radius: 0
    Column {
      id: noticeColumn
      anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(9); anchors.rightMargin: Style.space(9)
      spacing: Style.space(2)
      Text { width: parent.width; text: title; color: Color.accent; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; elide: Text.ElideRight }
      Text { width: parent.width; text: detail; color: root.contentForeground; opacity: 0.7; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; elide: Text.ElideRight }
    }
  }
}

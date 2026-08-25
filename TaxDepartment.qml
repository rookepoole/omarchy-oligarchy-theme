import QtQuick
import Quickshell
import Quickshell.Hyprland
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
  readonly property var pageNames: ["REVENUE", "HOLDINGS", "PRIVILEGES", "IDLE CAPITAL", "ACQUISITIONS", "COMPOUND"]
  readonly property var pageActionCounts: [3, 2, 5, 4, 5, 5]
  readonly property var pageComponents: [revenuePage, holdingsPage, privilegesPage, screensaverPage, acquisitionsPage, compoundPage]

  property int serial: 1040
  property var currentAssessment: TaxModel.assessment(serial)
  property int pageIndex: 0
  property int actionIndex: 0
  property bool cursorActive: false
  property string receipt: "PUBLIC COLLECTION ADDRESS"
  property var metrics: ({ load: "0.00", memory: 0, disk: 0, uptime: "0H", battery: "PROBING" })
  property int focusDuration: 25 * 60
  property int focusRemaining: focusDuration
  property bool focusRunning: false
  property bool focusIsBreak: false
  property string focusMode: "HOSTILE TAKEOVER"
  property int focusSessions: 0
  readonly property string focusClock: TaxModel.formatFocusTime(focusRemaining)
  readonly property real focusProgress: TaxModel.focusProgress(focusRemaining, focusDuration)

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

  function conveneExitCommittee() {
    receipt = "EXECUTIVE EXIT COMMITTEE // CONVENED"
    root.close()
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", moduleName, "{}"])
  }

  function screensaverCall(method, nextReceipt, argument) {
    receipt = nextReceipt
    var command = ["omarchy-shell", "oligarchy-screensaver", String(method)]
    if (argument !== undefined && argument !== null) command.push(String(argument))
    Quickshell.execDetached(command)
  }

  function previewScreensaver() {
    root.close()
    screensaverCall("preview", "PRIVATE IDLE CAPITAL PREVIEWED")
  }

  function previewScreensaverScene(index) {
    root.close()
    screensaverCall("previewScene", "SCENE 0" + (index + 1) + " PREVIEWED", index)
  }

  function restoreDefaults() {
    receipt = "PUBLIC MANAGEMENT RESTORED"
    Quickshell.execDetached(["bash", "-c", "omarchy-shell oligarchy-screensaver disable >/dev/null; omarchy-shell oligarchy-screensaver restoreBranding >/dev/null"])
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function workspaceAssets(id) {
    var workspace = workspaceById(id)
    return workspace && workspace.toplevels ? workspace.toplevels.values.length : 0
  }

  function workspaceFocused(id) {
    return Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === id
  }

  function acquireWorkspace(id) {
    var numericId = Math.max(1, Math.min(5, Math.floor(Number(id) || 1)))
    var company = TaxModel.PORTFOLIOS[numericId - 1]
    receipt = "CONTROLLING INTEREST // " + company.symbol
    root.close()
    Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + numericId + "\" })"])
  }

  function setFocusPreset(seconds, mode, isBreak) {
    focusRunning = false
    focusDuration = TaxModel.focusSeconds(seconds)
    focusRemaining = focusDuration
    focusMode = String(mode)
    focusIsBreak = isBreak === true
    receipt = focusIsBreak ? "BOARD RECESS CAPITALIZED" : focusMode + " TERM SHEET"
  }

  function toggleFocus() {
    if (focusRemaining <= 0) focusRemaining = focusDuration
    focusRunning = !focusRunning
    receipt = focusRunning ? "COMPOUND INTEREST ACCRUING" : "TRADING HALTED // CLOCK PRESERVED"
  }

  function resetFocus() {
    focusRunning = false
    focusRemaining = focusDuration
    receipt = "PERFORMANCE PERIOD RESTATED"
  }

  function finishFocusPhase() {
    focusRunning = false
    if (focusIsBreak) {
      setFocusPreset(25 * 60, "HOSTILE TAKEOVER", false)
      receipt = "BOARD RECESS EXPIRED // LABOR RECALLED"
      Quickshell.execDetached(["omarchy-notification-send", "Board recess expired", "Return to value creation. Your equity remains fictional.", "-t", "5200"])
    } else {
      focusSessions += 1
      setFocusPreset(5 * 60, "BOARD RECESS", true)
      receipt = "QUARTERLY EARNINGS BEAT // RECESS VESTED"
      Quickshell.execDetached(["omarchy-notification-send", "Quarterly earnings beat", "Labor extracted successfully. A five-minute board recess has vested.", "-t", "5200"])
    }
  }

  function refreshMetrics() {
    if (!metricsProcess.running) metricsProcess.running = true
  }

  function openAnnualReport() {
    var reportUrl = Qt.resolvedUrl("annual-report.sh").toString()
    var reportPath = decodeURIComponent(reportUrl.replace(/^file:\/\//, ""))
    receipt = "ANNUAL REPORT FILED // UNAUDITED FOREVER"
    root.close()
    Quickshell.execDetached([
      "omarchy-launch-floating-terminal-with-presentation",
      "bash " + Util.shellQuote(reportPath)
    ])
  }

  function setPage(index) {
    pageIndex = ((index % pageNames.length) + pageNames.length) % pageNames.length
    actionIndex = 0
    cursorActive = false
    receipt = pageIndex === 0 ? "PUBLIC COLLECTION ADDRESS"
      : pageIndex === 1 ? "CONSOLIDATED HOLDINGS // LIVE"
      : pageIndex === 2 ? "EXECUTIVE PRIVILEGES // VESTED"
      : pageIndex === 3 ? "IDLE CAPITAL // FULLY DEPLOYED"
      : pageIndex === 4 ? "PORTFOLIO COMPANIES // CONSOLIDATED"
      : "COMPOUND INTEREST // " + focusClock
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
      if (actionIndex === 0) {
        refreshMetrics()
        receipt = "HOLDINGS MARKED TO MARKET"
      } else {
        openAnnualReport()
      }
    } else if (pageIndex === 2) {
      if (actionIndex === 0) lockEstate()
      else if (actionIndex === 1) toggleSilence()
      else if (actionIndex === 2) toggleMarkets()
      else if (actionIndex === 3) captureAsset()
      else conveneExitCommittee()
    } else if (pageIndex === 3) {
      if (actionIndex === 0) previewScreensaver()
      else if (actionIndex === 1) screensaverCall("enable", "IDLE CAPITAL PRIVATIZED")
      else if (actionIndex === 2) restoreDefaults()
      else screensaverCall("brand", "INSTITUTIONAL BRANDING INSTALLED")
    } else if (pageIndex === 4) {
      acquireWorkspace(actionIndex + 1)
    } else {
      if (actionIndex === 0) toggleFocus()
      else if (actionIndex === 1) resetFocus()
      else if (actionIndex === 2) setFocusPreset(25 * 60, "HOSTILE TAKEOVER", false)
      else if (actionIndex === 3) setFocusPreset(50 * 60, "MEGA MERGER", false)
      else setFocusPreset(5 * 60, "BOARD RECESS", true)
    }
  }

  function handleTextKey(value) {
    var key = String(value).toLowerCase()
    if (/^[1-6]$/.test(key)) { setPage(Number(key) - 1); return }
    if (key === "[" || key === "q") { setPage(pageIndex - 1); return }
    if (key === "]" || key === "e") { setPage(pageIndex + 1); return }
    if (pageIndex === 0) {
      if (key === "c") copyAddress()
      else if (key === "o") openExplorer()
      else if (key === "r") reassess()
    } else if (pageIndex === 1) {
      if (key === "r") refreshMetrics()
      else if (key === "a") openAnnualReport()
    } else if (pageIndex === 2) {
      if (key === "l") lockEstate()
      else if (key === "d") toggleSilence()
      else if (key === "a") toggleMarkets()
      else if (key === "s") captureAsset()
      else if (key === "b") conveneExitCommittee()
    } else if (pageIndex === 3) {
      if (key === "p") previewScreensaver()
      else if (key === "m") screensaverCall("enable", "IDLE CAPITAL PRIVATIZED")
      else if (key === "x") restoreDefaults()
      else if (key === "b") screensaverCall("brand", "INSTITUTIONAL BRANDING INSTALLED")
    } else if (pageIndex === 5) {
      if (key === "s") toggleFocus()
      else if (key === "r") resetFocus()
      else if (key === "f") setFocusPreset(25 * 60, "HOSTILE TAKEOVER", false)
      else if (key === "l") setFocusPreset(50 * 60, "MEGA MERGER", false)
      else if (key === "b") setFocusPreset(5 * 60, "BOARD RECESS", true)
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
    text: root.focusRunning ? "ROI·" + root.focusClock : "TAX·" + root.currentAssessment.rate
    fontSize: Style.font.caption
    active: root.opened
    tooltipText: root.focusRunning
      ? root.focusMode + " // " + root.focusClock + " // compound interest accruing"
      : "Oligarch Operating System // assessment " + root.currentAssessment.rate + "%"
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
    interval: 1000
    repeat: true
    running: root.focusRunning
    onTriggered: {
      root.focusRemaining = Math.max(0, root.focusRemaining - 1)
      if (root.focusRemaining === 0) root.finishFocusPhase()
    }
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

        Grid {
          width: parent.width
          columns: 3
          spacing: Style.space(5)
          Repeater {
            model: root.pageNames
            Button {
              required property string modelData
              required property int index
              width: (parent.width - parent.spacing * 2) / 3
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
          text: root.pageIndex === 0 ? "1–6 desks // c copy // o ledger // r reassess"
            : root.pageIndex === 1 ? "real system telemetry // r refresh // a annual report"
            : root.pageIndex === 2 ? "l lock // d silence // a stay awake // s screenshot // b board"
            : root.pageIndex === 3 ? "p preview // m make default // x restore // b brand system"
            : root.pageIndex === 4 ? "live Hyprland portfolio // arrows select // Enter acquires"
            : "s start/pause // r reset // f 25m // l 50m // b 5m recess"
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
      Row {
        width: parent.width; spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing) / 2; action: 0; text: "MARK TO MARKET"; onClicked: { root.refreshMetrics(); root.receipt = "HOLDINGS MARKED TO MARKET" } }
        ActionButton { width: (parent.width - parent.spacing) / 2; action: 1; text: "OPEN ANNUAL REPORT"; onClicked: root.openAnnualReport() }
      }
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
      ActionButton { width: parent.width; height: Style.space(45); action: 4; text: "CONVENE EXECUTIVE EXIT COMMITTEE"; onClicked: root.conveneExitCommittee() }
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
            interactive: true
            onActivated: root.previewScreensaverScene(index)
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

  Component {
    id: acquisitionsPage
    Column {
      width: pageLoader.width
      spacing: Style.space(9)
      Text { width: parent.width; text: "PORTFOLIO COMPANIES"; color: "#D4B35A"; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { width: parent.width; text: "Five live Hyprland workspaces, restated as wholly owned subsidiaries. Empty companies remain pre-revenue."; color: root.contentForeground; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
      Grid {
        width: parent.width
        columns: 3
        spacing: Style.space(7)
        Repeater {
          model: TaxModel.PORTFOLIOS
          ActionButton {
            required property var modelData
            required property int index
            width: (parent.width - parent.spacing * 2) / 3
            height: Style.space(58)
            action: index
            selected: root.workspaceFocused(modelData.id)
            text: "0" + modelData.id + "  " + modelData.symbol + "\n" +
              (root.workspaceAssets(modelData.id) === 0
                ? "PRE-REVENUE"
                : root.workspaceAssets(modelData.id) + (root.workspaceAssets(modelData.id) === 1 ? " ASSET" : " ASSETS"))
            tooltipText: modelData.name
            onClicked: root.acquireWorkspace(modelData.id)
          }
        }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        StatCell {
          width: (parent.width - parent.spacing * 2) / 3
          label: "CONTROLLING INTEREST"
          value: Hyprland.focusedWorkspace ? "WORKSPACE " + Hyprland.focusedWorkspace.id : "PENDING"
          valueColor: Color.accent
        }
        StatCell {
          width: (parent.width - parent.spacing * 2) / 3
          label: "CONSOLIDATED ASSETS"
          value: (root.workspaceAssets(1) + root.workspaceAssets(2) + root.workspaceAssets(3) + root.workspaceAssets(4) + root.workspaceAssets(5)) + " WINDOWS"
          valueColor: "#D4B35A"
        }
        StatCell { width: (parent.width - parent.spacing * 2) / 3; label: "MINORITY RIGHTS"; value: "DRAG-ALONG"; valueColor: root.contentUrgent }
      }
    }
  }

  Component {
    id: compoundPage
    Column {
      width: pageLoader.width
      spacing: Style.space(9)
      Text { width: parent.width; text: "COMPOUND INTEREST"; color: "#D4B35A"; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { width: parent.width; text: "A real focus clock for extracting concentrated labor. While markets are open, the live countdown replaces TAX·nn in the bar."; color: root.contentForeground; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
      BorderSurface {
        width: parent.width
        implicitHeight: Style.space(112)
        color: Util.alpha(root.contentForeground, 0.025)
        borderSpec: Border.controlSpec("normal", root.contentForeground, Color.accent)
        radius: 0
        Column {
          anchors.fill: parent
          anchors.margins: Style.space(12)
          spacing: Style.space(8)
          Row {
            width: parent.width
            Column {
              width: parent.width - focusClockText.width - Style.space(20)
              spacing: Style.space(4)
              Text { width: parent.width; text: root.focusMode; color: Color.accent; font.family: root.contentFontFamily; font.pixelSize: Style.font.body; font.bold: true; elide: Text.ElideRight }
              Text { width: parent.width; text: root.focusRunning ? "MARKETS OPEN // LABOR COMPOUNDING" : "TRADING HALTED // TERM PRESERVED"; color: root.focusRunning ? "#D4B35A" : Qt.darker(root.contentForeground, 1.7); font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; font.bold: true; elide: Text.ElideRight }
              Text { width: parent.width; text: root.focusSessions + (root.focusSessions === 1 ? " PERFORMANCE PERIOD CLOSED" : " PERFORMANCE PERIODS CLOSED"); color: root.contentForeground; opacity: 0.72; font.family: root.contentFontFamily; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
            }
            Text {
              id: focusClockText
              text: root.focusClock
              color: root.focusRunning ? Color.accent : root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.space(38)
              font.bold: true
            }
          }
          Rectangle {
            width: parent.width
            height: Style.space(5)
            color: Util.alpha(root.contentForeground, 0.12)
            Rectangle {
              width: parent.width * root.focusProgress
              height: parent.height
              color: root.focusIsBreak ? "#5D8CEB" : Color.accent
              Behavior on width { NumberAnimation { duration: 180 } }
            }
          }
        }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(45); action: 0; text: root.focusRunning ? "HALT TRADING" : "START ACCRUAL"; onClicked: root.toggleFocus() }
        ActionButton { width: (parent.width - parent.spacing) / 2; height: Style.space(45); action: 1; text: "RESTATE PERIOD"; onClicked: root.resetFocus() }
      }
      Row {
        width: parent.width; spacing: Style.space(7)
        ActionButton { width: (parent.width - parent.spacing * 2) / 3; action: 2; text: "TAKEOVER // 25M"; selected: root.focusDuration === 25 * 60 && !root.focusIsBreak; onClicked: root.setFocusPreset(25 * 60, "HOSTILE TAKEOVER", false) }
        ActionButton { width: (parent.width - parent.spacing * 2) / 3; action: 3; text: "MERGER // 50M"; selected: root.focusDuration === 50 * 60 && !root.focusIsBreak; onClicked: root.setFocusPreset(50 * 60, "MEGA MERGER", false) }
        ActionButton { width: (parent.width - parent.spacing * 2) / 3; action: 4; text: "RECESS // 5M"; selected: root.focusIsBreak; onClicked: root.setFocusPreset(5 * 60, "BOARD RECESS", true) }
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
    property bool interactive: false
    signal activated()
    implicitHeight: noticeColumn.implicitHeight + Style.space(14)
    color: "#080B09"
    borderSpec: Border.controlSpec("normal", root.contentForeground, Color.accent)
    radius: 0
    MouseArea {
      anchors.fill: parent
      enabled: interactive
      cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: parent.activated()
    }
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

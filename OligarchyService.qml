import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: ""

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateDir: home + "/.local/state/oligarchy"
  readonly property string defaultMarker: stateDir + "/screensaver-managed"
  readonly property int idleSeconds: Math.max(5, Number(shell && shell.shellConfig && shell.shellConfig.idle ? shell.shellConfig.idle.screensaver : 150) || 150)
  readonly property string sourceDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""

  property bool active: false
  property bool manualPreview: false
  property bool customDefaultEnabled: false
  property int sceneIndex: 0
  property int sceneSerial: 0
  property double openedAtMs: 0
  property string lastReason: "service-ready"

  function openScene(requestedScene, reason) {
    lastReason = String(reason || "manual")
    manualPreview = lastReason !== "idle"
    var numericScene = Number(requestedScene)
    if (!isFinite(numericScene)) numericScene = Math.floor(Date.now() / 1000)
    sceneIndex = ((Math.floor(numericScene) % 4) + 4) % 4
    sceneSerial += 1
    openedAtMs = Date.now()
    active = true
    sceneTimer.restart()
    return "ok"
  }

  function openScreensaver(reason) {
    return openScene(Math.floor(Date.now() / 1000), reason)
  }

  function closeScreensaver(reason) {
    if (!active) return "ok"
    lastReason = String(reason || "dismissed")
    active = false
    manualPreview = false
    sceneTimer.stop()
    return "ok"
  }

  function nextScene() {
    sceneIndex = (sceneIndex + 1) % 4
    sceneSerial += 1
    return String(sceneIndex)
  }

  function refreshDefaultState() {
    if (!defaultStateProbe.running) defaultStateProbe.running = true
  }

  function setDefaultEnabled(value) {
    if (defaultManager.running) return "busy"
    if (value) {
      defaultManager.command = [
        "bash", "-c",
        "set -e; state=\"$HOME/.local/state/oligarchy\"; toggles=\"$HOME/.local/state/omarchy/toggles\"; mkdir -p \"$state\" \"$toggles\"; if [[ ! -f \"$state/screensaver-managed\" ]]; then if [[ -f \"$toggles/screensaver-off\" ]]; then printf disabled > \"$state/screensaver-prior\"; else printf enabled > \"$state/screensaver-prior\"; fi; fi; touch \"$state/screensaver-managed\" \"$toggles/screensaver-off\"; omarchy-notification-send 'OLIGARCHY screensaver now manages idle capital' 'Original preference preserved' -t 2400"
      ]
    } else {
      defaultManager.command = [
        "bash", "-c",
        "set -e; state=\"$HOME/.local/state/oligarchy\"; toggle=\"$HOME/.local/state/omarchy/toggles/screensaver-off\"; prior=\"\"; [[ -f \"$state/screensaver-prior\" ]] && prior=$(<\"$state/screensaver-prior\"); if [[ $prior == enabled ]]; then rm -f \"$toggle\"; fi; rm -f \"$state/screensaver-managed\" \"$state/screensaver-prior\"; omarchy-notification-send 'Omarchy screensaver restored' 'Idle capital returned to public management' -t 2400"
      ]
      closeScreensaver("default-disabled")
    }
    defaultManager.running = true
    return "ok"
  }

  function installBranding() {
    if (brandingManager.running || sourceDir === "") return sourceDir === "" ? "missing-source" : "busy"
    brandingManager.command = [
      "bash", "-c",
      "set -e; state=\"$HOME/.local/state/oligarchy/branding\"; dest=\"$HOME/.config/omarchy/branding\"; mkdir -p \"$state\" \"$dest\"; if [[ ! -e \"$state/managed\" ]]; then if [[ -f \"$dest/about.txt\" ]]; then cp -p \"$dest/about.txt\" \"$state/about.txt.backup\"; else touch \"$state/about.absent\"; fi; if [[ -f \"$dest/screensaver.txt\" ]]; then cp -p \"$dest/screensaver.txt\" \"$state/screensaver.txt.backup\"; else touch \"$state/screensaver.absent\"; fi; fi; cp \"$1\" \"$dest/about.txt\"; cp \"$2\" \"$dest/screensaver.txt\"; touch \"$state/managed\"; omarchy-notification-send 'Institutional branding installed' 'About screen and fallback saver are now shareholder-aligned' -t 2600",
      "oligarchy-branding", sourceDir + "/branding/about.txt", sourceDir + "/branding/screensaver.txt"
    ]
    brandingManager.running = true
    return "ok"
  }

  function restoreBranding() {
    if (brandingManager.running) return "busy"
    brandingManager.command = [
      "bash", "-c",
      "set -e; state=\"$HOME/.local/state/oligarchy/branding\"; dest=\"$HOME/.config/omarchy/branding\"; mkdir -p \"$dest\"; if [[ -f \"$state/about.txt.backup\" ]]; then cp -p \"$state/about.txt.backup\" \"$dest/about.txt\"; elif [[ -f \"$state/about.absent\" ]]; then rm -f \"$dest/about.txt\"; fi; if [[ -f \"$state/screensaver.txt.backup\" ]]; then cp -p \"$state/screensaver.txt.backup\" \"$dest/screensaver.txt\"; elif [[ -f \"$state/screensaver.absent\" ]]; then rm -f \"$dest/screensaver.txt\"; fi; rm -f \"$state/managed\" \"$state/about.txt.backup\" \"$state/screensaver.txt.backup\" \"$state/about.absent\" \"$state/screensaver.absent\"; omarchy-notification-send 'Original branding restored' 'The board denies this ever happened' -t 2400"
    ]
    brandingManager.running = true
    return "ok"
  }

  function statusJson() {
    return JSON.stringify({
      active: active,
      manualPreview: manualPreview,
      defaultEnabled: customDefaultEnabled,
      idleSeconds: idleSeconds,
      scene: sceneIndex,
      lastReason: lastReason
    })
  }

  function showWelcomeOnce() {
    if (welcomeProcess.running || !manifest || !manifest.version) return
    var versionKey = String(manifest.version).replace(/[^A-Za-z0-9._-]+/g, "-")
    welcomeProcess.command = [
      "bash", "-c",
      "set -e; state=\"$HOME/.local/state/oligarchy\"; marker=\"$state/welcome-$1\"; mkdir -p \"$state\"; [[ -f $marker ]] && exit 0; touch \"$marker\"; omarchy-notification-send 'CONTROLLING INTEREST ACQUIRED' 'Click TAX·nn for six desks: revenue, holdings, privileges, idle capital, acquisitions, and compound interest' -t 5200",
      "oligarchy-welcome", versionKey
    ]
    welcomeProcess.running = true
  }

  onManifestChanged: if (manifest) welcomeTimer.restart()

  IdleMonitor {
    id: idleMonitor
    enabled: root.customDefaultEnabled
    timeout: root.idleSeconds
    respectInhibitors: true
    onIsIdleChanged: {
      if (isIdle && root.customDefaultEnabled) root.openScreensaver("idle")
      else if (!isIdle && root.active && !root.manualPreview) root.closeScreensaver("activity")
    }
  }

  Timer {
    id: sceneTimer
    interval: 15000
    repeat: true
    running: root.active
    onTriggered: root.nextScene()
  }

  Timer {
    interval: 4000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshDefaultState()
  }

  Process {
    id: defaultStateProbe
    command: ["bash", "-c", "[[ -f $HOME/.local/state/oligarchy/screensaver-managed ]] && printf yes || printf no"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.customDefaultEnabled = String(text || "").trim() === "yes"
    }
  }

  Process {
    id: defaultManager
    onExited: function() { root.refreshDefaultState() }
  }

  Process {
    id: brandingManager
  }

  Process {
    id: welcomeProcess
  }

  Timer {
    id: welcomeTimer
    interval: 450
    repeat: false
    onTriggered: root.showWelcomeOnce()
  }

  IpcHandler {
    target: "oligarchy-screensaver"

    function preview(): string { return root.openScreensaver("manual") }
    function previewScene(scene: string): string { return root.openScene(scene, "manual-scene") }
    function dismiss(): string { return root.closeScreensaver("ipc") }
    function next(): string { return root.nextScene() }
    function enable(): string { return root.setDefaultEnabled(true) }
    function disable(): string { return root.setDefaultEnabled(false) }
    function brand(): string { return root.installBranding() }
    function restoreBranding(): string { return root.restoreBranding() }
    function status(): string { return root.statusJson() }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: saverWindow
      required property var modelData

      screen: modelData
      visible: root.active
      anchors { top: true; right: true; bottom: true; left: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "oligarchy-screensaver"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      OligarchyScreensaver {
        anchors.fill: parent
        sceneIndex: root.sceneIndex
        sceneSerial: root.sceneSerial
      }

      FocusScope {
        anchors.fill: parent
        focus: root.active
        Keys.onPressed: function(event) {
          root.closeScreensaver("keyboard")
          event.accepted = true
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeScreensaver("pointer")
        onPositionChanged: function(mouse) {
          if (root.active && Date.now() - root.openedAtMs > 500)
            root.closeScreensaver("pointer-movement")
        }
      }
    }
  }

  Component.onCompleted: {
    refreshDefaultState()
    welcomeTimer.restart()
  }
  Component.onDestruction: closeScreensaver("service-unloaded")
}

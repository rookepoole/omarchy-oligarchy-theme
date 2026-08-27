import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import "TaxModel.js" as TaxModel

Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: ""

  readonly property string home: Quickshell.env("HOME")
  readonly property int idleSeconds: Math.max(5, Number(shell && shell.shellConfig && shell.shellConfig.idle ? shell.shellConfig.idle.screensaver : 150) || 150)
  readonly property string sourceDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
  readonly property string stateHelper: sourceDir === "" ? "" : sourceDir + "/oligarchy-state"

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
    sceneIndex = ((Math.floor(numericScene) % TaxModel.SCENES.length) + TaxModel.SCENES.length) % TaxModel.SCENES.length
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
    sceneIndex = (sceneIndex + 1) % TaxModel.SCENES.length
    sceneSerial += 1
    return String(sceneIndex)
  }

  function refreshDefaultState() {
    if (stateHelper === "") {
      customDefaultEnabled = false
      return
    }
    if (!defaultStateProbe.running) defaultStateProbe.running = true
  }

  function setDefaultEnabled(value) {
    if (stateHelper === "") return "missing-source"
    if (defaultManager.running) return "busy"
    if (value) {
      defaultManager.command = [stateHelper, "default-enable"]
    } else {
      defaultManager.command = [stateHelper, "default-disable"]
      closeScreensaver("default-disabled")
    }
    defaultManager.running = true
    return "ok"
  }

  function installBranding() {
    if (brandingManager.running || sourceDir === "") return sourceDir === "" ? "missing-source" : "busy"
    brandingManager.command = [
      stateHelper, "branding-install",
      sourceDir + "/branding/about.txt", sourceDir + "/branding/screensaver.txt"
    ]
    brandingManager.running = true
    return "ok"
  }

  function restoreBranding() {
    if (stateHelper === "") return "missing-source"
    if (brandingManager.running) return "busy"
    brandingManager.command = [stateHelper, "branding-restore"]
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
    welcomeProcess.command = [stateHelper, "welcome", versionKey]
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
    command: root.stateHelper === "" ? [] : [root.stateHelper, "default-status"]
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

  IpcHandler {
    target: "oligarchy-executive-exit"

    function open(payloadJson: string): string {
      exitCommittee.open(payloadJson)
      return "ok"
    }
    function close(): string { exitCommittee.close(); return "ok" }
    function toggle(): string { exitCommittee.toggle(); return "ok" }
    function request(actionId: string): string {
      var index = exitCommittee.actionIndexById(actionId)
      if (String(exitCommittee.actions[index].id) !== String(actionId)) return "unknown-action"
      exitCommittee.requestAction(index)
      return "ok"
    }
    function status(): string { return exitCommittee.statusJson() }
  }

  ExecutiveExit {
    id: exitCommittee
    shell: root.shell
    manifest: root.manifest
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

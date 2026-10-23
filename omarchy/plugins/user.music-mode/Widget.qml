import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.music-mode"
  property bool music: false
  property bool available: true

  function refresh() {
    if (!statusProcess.running && !toggleProcess.running) statusProcess.running = true
  }

  function parse(text) {
    try {
      root.music = JSON.parse(text).music === true
      root.available = true
    } catch (error) { root.available = false }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  IpcHandler {
    target: "user.music-mode"
    function refresh(): void { root.refresh() }
    function status(): string { return root.music ? "music" : "stock" }
  }

  Process {
    id: statusProcess
    command: ["@BINDIR@/music-mode", "status"]
    stdout: StdioCollector { onStreamFinished: root.parse(text) }
  }

  Process {
    id: toggleProcess
    command: ["@BINDIR@/music-mode", "toggle"]
    stdout: StdioCollector { onStreamFinished: root.parse(text) }
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    bar: root.bar
    text: "󰋋"
    active: root.music
    dimmed: !root.music
    tooltipText: !root.available ? "Music mode: CoolerControl unavailable"
      : (root.music ? "Music mode ON · quiet fans" : "Music mode OFF · stock fans")
      + "\nClick to toggle"
    onPressed: function(mouseButton) {
      if (toggleProcess.running) return
      root.music = !root.music
      toggleProcess.running = true
    }
  }
}

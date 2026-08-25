import QtQuick

// Tax Department keyboard routing. Omarchy's general PanelKeyCatcher also
// reserves h/j/k/l for Vim navigation and x for delete. Those are useful
// defaults for list panels, but they make labeled desk mnemonics such as
// l = Lock Estate, l = 50m Merger, and x = Restore Omarchy unreachable.
// This panel therefore navigates with arrows and leaves every printable key
// available to the active desk.
Item {
  id: root

  property bool blocked: false

  signal moveRequested(int dx, int dy)
  signal activateRequested()
  signal closeRequested()
  signal tabRequested(int direction)
  signal textKey(string text)

  function routeKey(key, text, modifiers) {
    if (blocked) return false

    if (key === Qt.Key_Escape) {
      closeRequested(); return true
    }
    if (key === Qt.Key_Tab || key === Qt.Key_Backtab) {
      tabRequested((modifiers & Qt.ShiftModifier) || key === Qt.Key_Backtab ? -1 : 1)
      return true
    }
    if (key === Qt.Key_Down) {
      moveRequested(0, 1); return true
    }
    if (key === Qt.Key_Up) {
      moveRequested(0, -1); return true
    }
    if (key === Qt.Key_Right) {
      moveRequested(1, 0); return true
    }
    if (key === Qt.Key_Left) {
      moveRequested(-1, 0); return true
    }
    if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) {
      activateRequested(); return true
    }
    if (text && text.length === 1) {
      textKey(text)
      return true
    }
    return false
  }

  focus: true
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    event.accepted = root.routeKey(event.key, event.text, event.modifiers)
  }
}

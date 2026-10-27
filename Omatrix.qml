// Omatrix — a dial picker for Omarchy themes and backgrounds. One overlay, two
// modes chosen by the summon payload: {"mode":"themes"} (default) lists the
// theme switcher's cached previews (~/.cache/omarchy/theme-selector/previews)
// and applies with `omarchy-theme-set`; {"mode":"backgrounds"} lists the current
// theme's backgrounds plus ~/.config/omarchy/backgrounds/<theme>/ and applies
// with `omarchy-theme-bg-set`. Type to filter, Enter applies, Esc / right-click
// closes.
// Dial design adapted from Omatrix in github.com/dkgamer02ai/omarchy-wallpaper-engine (MIT).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
  id: root

  // Injected by omarchy-shell when the overlay is summoned.
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string mode: "themes"
  property var allItems: []
  property var items: []
  readonly property int count: items.length
  property string query: ""

  // `target` is the integer index being spun to; `pos` eases toward it.
  property real target: 0
  property real pos: target
  Behavior on pos { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

  readonly property real stepDeg: 18
  readonly property color accent: "#38e08b"
  readonly property color frame: "#181b22"
  readonly property color line: "#242833"

  property real cx: panel.width / 2
  property real radius: Math.min(panel.width * 0.27, 430)
  property real cy: panel.height * 0.90 + radius * 0.46
  readonly property real cardW: Math.min(panel.width * 0.11, 168)

  function open(payloadJson) {
    var p = {}
    try { p = JSON.parse(payloadJson) || {} } catch (e) { p = {} }
    root.mode = (p.mode === "backgrounds") ? "backgrounds" : "themes"
    root.allItems = []
    root.items = []
    root.opened = true
    root.query = ""
    loader.running = true
    Qt.callLater(function () { keys.forceActiveFocus() })
  }
  function close() { root.opened = false }
  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "io.github.beyonddreadful.omatrix")
  }
  function toggle() { if (root.opened) dismiss(); else open("{}") }

  // Keeps the themes whose name contains the typed query (case-insensitive).
  function applyFilter() {
    var q = root.query.toLowerCase()
    root.items = root.allItems.filter(function (it) {
      var n = it.name.toLowerCase()
      return n.indexOf(q) !== -1 || n.replace(/-/g, " ").indexOf(q) !== -1
    })
    root.target = 0
  }

  function spin(n) { root.target += n }
  function selectedIndex() {
    return root.count ? (((Math.round(root.pos) % root.count) + root.count) % root.count) : 0
  }
  function selectedItem() { return root.count ? root.items[selectedIndex()] : null }

  function wrapDelta(i) {
    if (!root.count) return 0
    var d = (((i - root.pos) % root.count) + root.count) % root.count
    if (d > root.count / 2) d -= root.count
    return d
  }

  function apply() {
    var it = selectedItem()
    if (!it) return
    if (root.mode === "backgrounds")
      Quickshell.execDetached(["omarchy-theme-bg-set", it.path])
    else
      Quickshell.execDetached(["omarchy-theme-set", it.name])
    root.dismiss()
  }

  // Lists the cards for the current mode, one absolute path per line: theme
  // previews in themes mode, the current theme's backgrounds in backgrounds mode.
  Process {
    id: loader
    command: root.mode === "backgrounds"
      ? ["bash", "-c",
        'theme="$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)"; ' +
        'find -L "$HOME/.local/state/omarchy/current/theme/backgrounds" ' +
        '"$HOME/.config/omarchy/backgrounds/$theme" -maxdepth 1 -type f ' +
        "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
        '2>/dev/null | sort']
      : ["bash", "-c",
        'find -L "$HOME/.cache/omarchy/theme-selector/previews" -maxdepth 1 -type f | sort']
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.split("\n").filter(function (l) { return l.length > 0 })
        root.allItems = lines.map(function (p) {
          var name = p.split("/").pop().replace(/\.[^.]+$/, "")
          return { path: p, name: name, title: name }
        })
        root.applyFilter()
      }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omatrix"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#0b0c11" }
        GradientStop { position: 1.0; color: "#070809" }
      }
    }

    // focused preview (top)
    Rectangle {
      id: preview
      width: Math.min(parent.width * 0.46, 620)
      height: width * 9 / 16
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: parent.height * 0.13
      radius: 16; clip: true
      color: root.frame; border.width: 1; border.color: root.line

      Image {
        anchors.fill: parent
        source: root.selectedItem() ? "file://" + root.selectedItem().path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 56
        gradient: Gradient {
          GradientStop { position: 0.0; color: "#00060709" }
          GradientStop { position: 1.0; color: "#d1060709" }
        }
      }
      Text {
        anchors { left: parent.left; bottom: parent.bottom; margins: 16 }
        width: parent.width - 32
        text: root.selectedItem() ? root.selectedItem().title : ""
        color: "#eceef2"; font.pixelSize: 20; font.weight: Font.DemiBold
        elide: Text.ElideRight
      }
    }

    // the dial
    Item {
      anchors.fill: parent
      Repeater {
        model: root.items
        delegate: Rectangle {
          id: card
          required property var modelData
          required property int index
          readonly property real rel: root.wrapDelta(index)
          readonly property real ang: (90 - rel * root.stepDeg) * Math.PI / 180
          readonly property bool isSel: root.selectedIndex() === index

          width: root.cardW; height: root.cardW * 0.625
          radius: 12; clip: true
          color: root.frame
          border.width: isSel ? 2 : 1
          border.color: isSel ? root.accent : root.line
          antialiasing: true

          x: root.cx + root.radius * Math.cos(ang) - width / 2
          y: root.cy - root.radius * Math.sin(ang) - height / 2
          transformOrigin: Item.Center
          rotation: -(90 - rel * root.stepDeg) * 0.5
          scale: Math.max(0.55, 1.18 - Math.abs(rel) * 0.16)
          z: Math.round(200 - Math.abs(rel) * 10)
          opacity: Math.abs(rel) > 4.2 ? 0 : 1
          visible: opacity > 0

          Rectangle {
            anchors.centerIn: parent
            width: parent.width + 8; height: parent.height + 8; radius: 15
            color: "transparent"; border.width: 2; border.color: root.accent
            opacity: card.isSel ? 0.9 : 0; z: -1
          }

          Image {
            anchors.fill: parent
            source: "file://" + card.modelData.path
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 360
          }
          Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 22
            gradient: Gradient {
              GradientStop { position: 0.0; color: "#00060709" }
              GradientStop { position: 1.0; color: "#d9060709" }
            }
            Text {
              anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
              text: card.modelData.title
              color: "#dfe3ea"; font.pixelSize: 11; elide: Text.ElideRight
            }
          }
        }
      }
    }

    // typed filter, under the wordmark
    Text {
      anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.085 }
      text: root.query.length ? "> " + root.query + "▏" : "> type to filter"
      color: root.query.length ? "#eceef2" : "#5d6371"
      font.pixelSize: 16; font.letterSpacing: 1.5; font.family: "monospace"
    }
    Text {
      anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.12 }
      visible: root.count === 0
      text: root.mode === "backgrounds" ? "no backgrounds match" : "no themes match"
      color: "#7f8593"; font.pixelSize: 13; font.family: "monospace"
    }

    // hub under the arc
    Rectangle {
      width: 170; height: 170; radius: 85
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height - 52
      color: "#0a0f0c"; border.width: 2; border.color: "#1d7d4e"
      Rectangle {
        anchors.centerIn: parent; width: 118; height: 118; radius: 59
        color: "transparent"; border.width: 2; border.color: "#5938e08b"
      }
    }

    Text {
      anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.03 }
      text: "OMATRIX"; color: "#eceef2"; font.pixelSize: 24; font.weight: Font.Bold; font.letterSpacing: 8; font.family: "monospace"
    }

    Text {
      anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 }
      text: "type to filter    ·    ◄ ► or scroll to spin    ·    Enter apply    ·    Esc close"
      color: "#7f8593"; font.pixelSize: 13; font.letterSpacing: 1.2; font.family: "monospace"
    }

    // input
    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: function (ev) { root.spin((ev.angleDelta.y + ev.angleDelta.x) < 0 ? 1 : -1) }
    }
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      property real pressX: 0
      property real baseTarget: 0
      property bool moved: false
      onPressed: function (m) { pressX = m.x; baseTarget = root.target; moved = false }
      onPositionChanged: function (m) {
        if (!pressed) return
        if (Math.abs(m.x - pressX) > 4) moved = true
        root.target = baseTarget - (m.x - pressX) / 60
      }
      onReleased: function (m) { if (moved) root.target = Math.round(root.target) }
      onClicked: function (m) {
        if (m.button === Qt.RightButton) root.dismiss()
        else if (!moved) root.apply()
      }
    }

    Item {
      id: keys
      anchors.fill: parent
      focus: true
      Keys.onPressed: function (e) {
        if (e.key === Qt.Key_Escape) { root.dismiss(); e.accepted = true }
        else if (e.key === Qt.Key_Left) { root.spin(-1); e.accepted = true }
        else if (e.key === Qt.Key_Right) { root.spin(1); e.accepted = true }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.apply(); e.accepted = true }
        else if (e.key === Qt.Key_Backspace) {
          root.query = root.query.slice(0, -1)
          root.applyFilter()
          e.accepted = true
        }
        else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32 && e.text.charCodeAt(0) !== 127 && (e.modifiers === Qt.NoModifier || e.modifiers === Qt.ShiftModifier)) {
          root.query += e.text
          root.applyFilter()
          e.accepted = true
        }
      }
    }
  }
}

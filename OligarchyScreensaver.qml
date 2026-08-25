import QtQuick
import qs.Commons
import "TaxModel.js" as TaxModel

Item {
  id: root

  property int sceneIndex: 0
  property int sceneSerial: 0
  readonly property var scene: TaxModel.scene(sceneIndex)
  readonly property color ivory: "#E9E5D6"
  readonly property color gold: "#D4B35A"
  readonly property color green: "#A6D96A"
  readonly property color red: "#DA655E"
  property real driftX: -10
  property real driftY: 7
  property real orbitAngle: 0
  property real marketPhase: 0
  property int pizzaAttendance: 4

  NumberAnimation on driftX {
    from: -12; to: 12; duration: 19000
    loops: Animation.Infinite; easing.type: Easing.InOutSine
  }
  SequentialAnimation on driftY {
    loops: Animation.Infinite
    NumberAnimation { from: 7; to: -9; duration: 14000; easing.type: Easing.InOutSine }
    NumberAnimation { from: -9; to: 7; duration: 14000; easing.type: Easing.InOutSine }
  }
  NumberAnimation on orbitAngle {
    from: 0; to: 360; duration: 26000; loops: Animation.Infinite
  }
  NumberAnimation on marketPhase {
    from: 0; to: 1; duration: 9000; loops: Animation.Infinite
    onRunningChanged: marketChart.requestPaint()
  }
  onMarketPhaseChanged: marketChart.requestPaint()
  SequentialAnimation on pizzaAttendance {
    loops: Animation.Infinite
    NumberAnimation { from: 4; to: 99; duration: 11000; easing.type: Easing.InOutQuad }
    PauseAnimation { duration: 1800 }
    NumberAnimation { from: 99; to: 4; duration: 700; easing.type: Easing.InQuad }
  }

  Rectangle {
    anchors.fill: parent
    color: "#050705"
  }

  Item {
    anchors.fill: parent
    opacity: 0.34

    Repeater {
      model: Math.ceil(root.width / 80) + 1
      Rectangle {
        required property int index
        x: index * 80
        width: 1
        height: root.height
        color: "#203023"
      }
    }
    Repeater {
      model: Math.ceil(root.height / 80) + 1
      Rectangle {
        required property int index
        y: index * 80
        width: root.width
        height: 1
        color: "#203023"
      }
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Math.max(7, root.width * 0.006)
    color: root.green
  }

  Item {
    id: driftingContent
    anchors.fill: parent
    anchors.margins: Math.max(42, Math.min(root.width, root.height) * 0.055)
    transform: Translate { x: root.driftX; y: root.driftY }

    Row {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 12

      Text {
        text: "OLIGARCHY // PRIVATE IDLE CAPITAL"
        color: root.ivory
        font.family: Style.font.family
        font.pixelSize: Math.max(13, Math.min(root.width, root.height) * 0.018)
        font.bold: true
        font.letterSpacing: 1.5
      }
      Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - status.implicitWidth - 24); height: 1 }
      Text {
        id: status
        text: "SCENE " + (root.sceneIndex + 1) + "/" + TaxModel.SCENES.length + "  //  ASSETS NEVER SLEEP"
        color: root.gold
        font.family: Style.font.family
        font.pixelSize: Math.max(11, Math.min(root.width, root.height) * 0.014)
        font.bold: true
      }
    }

    Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.topMargin: Math.min(root.height * 0.105, 120)
      spacing: 8

      Text {
        width: parent.width
        text: root.scene.kicker
        color: root.gold
        font.family: Style.font.family
        font.pixelSize: Math.max(12, Math.min(root.width, root.height) * 0.016)
        font.bold: true
        font.letterSpacing: 2
      }
      Text {
        width: parent.width
        text: root.scene.title
        color: root.sceneIndex === 3 ? root.gold : (root.sceneIndex === 4 ? root.red : root.green)
        font.family: Style.font.family
        font.pixelSize: Math.max(32, Math.min(root.width, root.height) * 0.072)
        font.bold: true
        font.letterSpacing: 1
        elide: Text.ElideRight
      }
      Text {
        width: parent.width
        text: root.scene.subtitle
        color: root.ivory
        opacity: 0.72
        font.family: Style.font.family
        font.pixelSize: Math.max(13, Math.min(root.width, root.height) * 0.019)
        wrapMode: Text.WordWrap
      }
    }

    Item {
      id: stage
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.topMargin: Math.min(root.height * 0.30, 330)
      anchors.bottomMargin: Math.min(root.height * 0.12, 110)

      // Scene 1: a literal trickle-up economy. Every coin ends at one owner.
      Item {
        anchors.fill: parent
        visible: root.sceneIndex === 0

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          width: Math.min(parent.width * 0.38, 520)
          height: Math.max(70, parent.height * 0.22)
          color: "#0D150F"
          border.color: root.green
          border.width: 2

          Column {
            anchors.centerIn: parent
            spacing: 5
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "BENEFICIAL OWNER"
              color: root.green
              font.family: Style.font.family
              font.pixelSize: Math.max(16, root.height * 0.025)
              font.bold: true
              font.letterSpacing: 2
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "100.00% LIQUIDITY RECEIVED"
              color: root.gold
              font.family: Style.font.family
              font.pixelSize: Math.max(12, root.height * 0.017)
              font.bold: true
            }
          }
        }

        Repeater {
          model: 28
          Text {
            required property int index
            x: (index * 173 + 37) % Math.max(1, parent.width - 40)
            y: parent.height + (index % 8) * 52
            text: index % 3 === 0 ? "$" : (index % 3 === 1 ? "¢" : "◆")
            color: index % 4 === 0 ? root.gold : root.green
            opacity: 0.35 + (index % 5) * 0.12
            font.family: Style.font.family
            font.pixelSize: 18 + (index % 4) * 5
            font.bold: true

            NumberAnimation on y {
              from: stage.height + (index % 8) * 52
              to: -80
              duration: 6500 + (index % 7) * 730
              loops: Animation.Infinite
              easing.type: Easing.InQuad
            }
          }
        }

        Text {
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          text: "BOTTOM 99%"
          color: root.ivory
          opacity: 0.52
          font.family: Style.font.family
          font.pixelSize: Math.max(13, root.height * 0.02)
          font.bold: true
        }
        Text {
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          text: "PLEASE ALLOW 3–5 GENERATIONS FOR SETTLEMENT"
          color: root.red
          font.family: Style.font.family
          font.pixelSize: Math.max(12, root.height * 0.017)
          font.bold: true
        }
      }

      // Scene 2: an absurd but legible market board with a moving chart.
      Item {
        anchors.fill: parent
        visible: root.sceneIndex === 1

        Row {
          anchors.fill: parent
          spacing: Math.max(20, parent.width * 0.035)

          Column {
            width: parent.width * 0.53
            spacing: Math.max(6, parent.height * 0.025)

            Repeater {
              model: TaxModel.MARKET_ROWS.length
              Rectangle {
                required property int index
                readonly property var row: TaxModel.marketRow(index)
                width: parent.width
                height: Math.max(44, stage.height * 0.13)
                color: index % 2 === 0 ? "#0B100D" : "#080B09"
                border.color: "#243129"
                border.width: 1

                Row {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 12
                  Text { width: parent.width * 0.14; text: row.symbol; color: root.green; font.family: Style.font.family; font.pixelSize: Math.max(13, root.height * 0.018); font.bold: true }
                  Text { width: parent.width * 0.42; text: row.name.toUpperCase(); color: root.ivory; font.family: Style.font.family; font.pixelSize: Math.max(11, root.height * 0.015); elide: Text.ElideRight }
                  Text { width: parent.width * 0.19; text: row.price; color: root.gold; font.family: Style.font.family; font.pixelSize: Math.max(12, root.height * 0.016); font.bold: true; horizontalAlignment: Text.AlignRight }
                  Text { width: parent.width * 0.16; text: row.change; color: row.change === "BEAT" ? root.red : root.green; font.family: Style.font.family; font.pixelSize: Math.max(12, root.height * 0.016); font.bold: true; horizontalAlignment: Text.AlignRight }
                }
              }
            }
          }

          Rectangle {
            width: parent.width * 0.44
            height: parent.height
            color: "#080B09"
            border.color: root.green
            border.width: 1

            Canvas {
              id: marketChart
              anchors.fill: parent
              anchors.margins: 20
              onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = "#26372A"
                ctx.lineWidth = 1
                for (var gy = 0; gy <= 5; gy++) {
                  ctx.beginPath(); ctx.moveTo(0, gy * height / 5); ctx.lineTo(width, gy * height / 5); ctx.stroke()
                }
                ctx.strokeStyle = root.green
                ctx.lineWidth = 3
                ctx.beginPath()
                for (var i = 0; i <= 48; i++) {
                  var x = i * width / 48
                  var base = height * (0.78 - i * 0.0105)
                  var noise = Math.sin(i * 1.67 + root.marketPhase * Math.PI * 2) * height * 0.07
                  var y = Math.max(8, Math.min(height - 8, base + noise))
                  if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                }
                ctx.stroke()
              }
            }

            Column {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.margins: 20
              Text { text: "SHAREHOLDER VALUE"; color: root.gold; font.family: Style.font.family; font.pixelSize: Math.max(12, root.height * 0.016); font.bold: true; font.letterSpacing: 1 }
              Text { text: "+∞"; color: root.green; font.family: Style.font.family; font.pixelSize: Math.max(30, root.height * 0.05); font.bold: true }
            }
          }
        }
      }

      // Scene 3: shell companies orbit a deliberately vague center.
      Item {
        anchors.fill: parent
        visible: root.sceneIndex === 2

        Rectangle {
          anchors.centerIn: parent
          width: Math.min(parent.width, parent.height) * 0.28
          height: width
          radius: width / 2
          color: "#0D150F"
          border.color: root.gold
          border.width: 3

          Column {
            anchors.centerIn: parent
            width: parent.width * 0.82
            Text { width: parent.width; text: "OWNER"; color: root.gold; font.family: Style.font.family; font.pixelSize: Math.max(18, root.height * 0.032); font.bold: true; horizontalAlignment: Text.AlignHCenter }
            Text { width: parent.width; text: "REDACTED"; color: root.ivory; font.family: Style.font.family; font.pixelSize: Math.max(13, root.height * 0.019); font.bold: true; horizontalAlignment: Text.AlignHCenter }
          }
        }

        Repeater {
          model: 9
          Rectangle {
            required property int index
            readonly property real angle: (index * 40 + root.orbitAngle) * Math.PI / 180
            width: Math.max(112, stage.width * 0.12)
            height: Math.max(52, stage.height * 0.11)
            x: stage.width / 2 + Math.cos(angle) * stage.width * (0.25 + (index % 2) * 0.10) - width / 2
            y: stage.height / 2 + Math.sin(angle) * stage.height * (0.27 + (index % 2) * 0.10) - height / 2
            color: "#080B09"
            border.color: index % 3 === 0 ? root.gold : root.green
            border.width: 1

            Column {
              anchors.centerIn: parent
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "SHELL-" + String(index + 1).padStart(2, "0"); color: root.green; font.family: Style.font.family; font.pixelSize: Math.max(11, root.height * 0.015); font.bold: true }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: index % 2 ? "CAYMAN" : "DELAWARE"; color: root.ivory; opacity: 0.6; font.family: Style.font.family; font.pixelSize: Math.max(9, root.height * 0.012) }
            }
          }
        }
      }

      // Scene 4: governance, simplified for controlling shareholders.
      Item {
        anchors.fill: parent
        visible: root.sceneIndex === 3

        Column {
          anchors.centerIn: parent
          width: Math.min(parent.width * 0.88, 1100)
          spacing: Math.max(16, parent.height * 0.045)

          Repeater {
            model: [
              ["EXECUTIVE COMPENSATION", "APPROVED", 1.0],
              ["WORKER REPRESENTATION", "TABLED", 0.08],
              ["PLANETARY EXTERNALITIES", "OFF BALANCE SHEET", 0.03],
              ["DIVIDEND TO CONTROLLING INTEREST", "UNANIMOUS", 0.96]
            ]
            Rectangle {
              required property var modelData
              required property int index
              width: parent.width
              height: Math.max(66, stage.height * 0.13)
              color: "#0B100D"
              border.color: index === 1 || index === 2 ? "#4C332F" : "#30442B"
              border.width: 1

              Item {
                anchors.fill: parent
                anchors.margins: 12
                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.48; text: modelData[0]; color: root.ivory; font.family: Style.font.family; font.pixelSize: Math.max(12, root.height * 0.017); font.bold: true; elide: Text.ElideRight }
                Rectangle { anchors.left: parent.left; anchors.leftMargin: parent.width * 0.50; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.28; height: 12; color: "#182019"; Rectangle { width: parent.width * modelData[2]; height: parent.height; color: index === 1 || index === 2 ? root.red : root.green } }
                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.18; text: modelData[1]; color: index === 1 || index === 2 ? root.red : root.gold; font.family: Style.font.family; font.pixelSize: Math.max(11, root.height * 0.015); font.bold: true; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
              }
            }
          }
        }
      }

      // Scene 5: compensation denominated in pizza while profits stay liquid.
      Item {
        anchors.fill: parent
        visible: root.sceneIndex === 4

        Row {
          anchors.centerIn: parent
          width: Math.min(parent.width * 0.94, 1260)
          height: parent.height * 0.90
          spacing: Math.max(32, parent.width * 0.055)

          Item {
            width: parent.height
            height: parent.height

            Rectangle {
              id: pizza
              anchors.centerIn: parent
              width: Math.min(parent.width, parent.height) * 0.84
              height: width
              radius: width / 2
              color: "#D4A846"
              border.color: "#9A5B2B"
              border.width: Math.max(10, width * 0.045)

              Repeater {
                model: 8
                Rectangle {
                  required property int index
                  x: pizza.width / 2 - width / 2
                  y: pizza.border.width
                  width: 2
                  height: pizza.width / 2 - pizza.border.width
                  color: "#8A552D"
                  opacity: 0.72
                  transformOrigin: Item.Bottom
                  rotation: index * 45
                }
              }

              Repeater {
                model: 18
                Rectangle {
                  required property int index
                  readonly property real angle: (index * 137.5) * Math.PI / 180
                  readonly property real distance: pizza.width * (0.11 + (index % 4) * 0.072)
                  x: pizza.width / 2 + Math.cos(angle) * distance - width / 2
                  y: pizza.height / 2 + Math.sin(angle) * distance - height / 2
                  width: Math.max(10, pizza.width * 0.055)
                  height: width
                  radius: width / 2
                  color: index % 5 === 0 ? "#557A3D" : "#B74338"
                  border.color: "#722B28"
                  border.width: 1
                }
              }

              Rectangle {
                anchors.centerIn: parent
                width: pizza.width * 0.18
                height: width
                radius: width / 2
                color: "#080B09"
                border.color: root.gold
                border.width: 2
                Text {
                  anchors.centerIn: parent
                  text: "Q4"
                  color: root.gold
                  font.family: Style.font.family
                  font.pixelSize: Math.max(16, pizza.width * 0.065)
                  font.bold: true
                }
              }
            }

            Rectangle {
              id: laborSlice
              width: pizza.width * 0.31
              height: pizza.width * 0.13
              x: pizza.x + pizza.width * 0.70
              y: pizza.y + pizza.height * 0.06
              rotation: -22
              color: "#D4A846"
              border.color: root.red
              border.width: 2
              Text {
                anchors.centerIn: parent
                text: "LABOR // 1 SLICE"
                color: "#080B09"
                font.family: Style.font.family
                font.pixelSize: Math.max(9, laborSlice.height * 0.20)
                font.bold: true
              }

              SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { from: pizza.x + pizza.width * 0.62; to: pizza.x + pizza.width * 0.78; duration: 2200; easing.type: Easing.InOutSine }
                NumberAnimation { from: pizza.x + pizza.width * 0.78; to: pizza.x + pizza.width * 0.62; duration: 2200; easing.type: Easing.InOutSine }
              }
            }
          }

          Column {
            width: parent.width - parent.height - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(10, parent.height * 0.028)

            Repeater {
              model: [
                ["RECORD PROFITS", "+38.7%"],
                ["MERIT INCREASE", "0.0%"],
                ["MORALE BUDGET", "$14.99"],
                ["EXECUTIVE SLICES", "7 OF 8"]
              ]
              Rectangle {
                required property var modelData
                required property int index
                width: parent.width
                height: Math.max(52, stage.height * 0.11)
                color: index === 1 ? "#150D0C" : "#0B100D"
                border.color: index === 1 ? root.red : "#30442B"
                border.width: 1
                Row {
                  anchors.fill: parent
                  anchors.margins: 12
                  Text { width: parent.width * 0.62; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; color: root.ivory; font.family: Style.font.family; font.pixelSize: Math.max(11, root.height * 0.016); font.bold: true }
                  Text { width: parent.width * 0.38; anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: index === 1 ? root.red : root.gold; font.family: Style.font.family; font.pixelSize: Math.max(13, root.height * 0.019); font.bold: true; horizontalAlignment: Text.AlignRight }
                }
              }
            }

            Rectangle {
              width: parent.width
              height: Math.max(72, stage.height * 0.15)
              color: "#080B09"
              border.color: root.green
              border.width: 2
              Column {
                anchors.centerIn: parent
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "MANDATORY ATTENDANCE"; color: root.ivory; font.family: Style.font.family; font.pixelSize: Math.max(11, root.height * 0.015); font.bold: true; font.letterSpacing: 1 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.pizzaAttendance + "%  //  HR IS WATCHING"; color: root.green; font.family: Style.font.family; font.pixelSize: Math.max(18, root.height * 0.028); font.bold: true }
              }
            }
          }
        }
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Math.max(42, root.height * 0.055)
      color: "#080B09"
      border.color: "#233027"
      border.width: 1

      Text {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        text: "BILLIONAIRES IN  //  TAXABLE INCOME OUT  //  PUBLIC CODE  //  PRIVATE GAINS  //  MOVE MOUSE OR PRESS ANY KEY TO RESUME LABOR"
        color: root.green
        font.family: Style.font.family
        font.pixelSize: Math.max(11, root.height * 0.014)
        font.bold: true
        font.letterSpacing: 1
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }
    }
  }
}

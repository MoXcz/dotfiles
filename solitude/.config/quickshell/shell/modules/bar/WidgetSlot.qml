import QtQuick
import "widgets"
import qs.modules.displays

// Maps a widget id from Config.bar to its component. Unknown ids render
// nothing and are reported once per shell run.
Loader {
  id: root

  required property string widgetId
  required property Item host      // Bar root, holds the shared warning set
  required property var window     // PanelWindow this slot is rendered in
  readonly property var screen: window ? window.screen : null

  readonly property var registry: ({
    workspaces: workspacesComp,
    activeWindow: activeWindowComp,
    clock: clockComp,
    tray: trayComp,
    audio: audioComp,
    network: networkComp,
    wifi: wifiComp,
    battery: batteryComp,
    bluetooth: bluetoothComp,
    system: systemComp,
    displays: displaysComp,
    vpn: vpnComp,
    windows: windowsComp,
    spacer: spacerComp
  })

  height: parent ? parent.height : implicitHeight
  sourceComponent: registry[widgetId] || null
  // Widgets opt out with a `shown` property; reading item.visible here would
  // loop, since a hidden Loader makes its item invisible too.
  visible: item !== null && (item.shown === undefined || item.shown)

  Component { id: workspacesComp; Workspaces { screen: root.screen } }
  Component { id: activeWindowComp; ActiveWindow {} }
  Component { id: clockComp; Clock {} }
  Component { id: trayComp; Tray {} }
  Component { id: audioComp; Audio {} }
  Component { id: networkComp; Network {} }
  Component { id: wifiComp; Network { compact: true } }
  Component { id: batteryComp; Battery {} }
  Component { id: bluetoothComp; BluetoothWidget {} }
  Component { id: systemComp; SystemWidget {} }
  // Displays lives in modules/displays (hyprmoncfg panel), not widgets/.
  Component { id: displaysComp; Displays {} }
  Component { id: vpnComp; Vpn {} }
  Component { id: windowsComp; Windows {} }
  Component { id: spacerComp; Spacer {} }

  Component.onCompleted: {
    if (registry[widgetId] || host.warnedIds[widgetId]) return
    host.warnedIds[widgetId] = true
    console.warn("bar: unknown widget id '" + widgetId + "'")
  }
}

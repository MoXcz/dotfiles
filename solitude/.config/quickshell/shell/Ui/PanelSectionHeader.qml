import QtQuick
import qs.Commons

// Small bold caption introducing a panel section (omarchy kit port).
Text {
  property color foreground: Theme.foreground
  property string fontFamily: Theme.fontFamily
  property real fontSize: Theme.fontCaption

  textFormat: Text.PlainText
  color: Theme.muted
  font.family: fontFamily
  font.pixelSize: fontSize
  font.bold: true
  // Nerd-font glyphs overshoot the ascent; reserve it so a header at the top
  // of a clipping list is not beheaded.
  topPadding: Math.ceil(fontSize * 0.15)
}

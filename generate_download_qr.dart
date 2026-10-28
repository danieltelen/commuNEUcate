import 'dart:io';

import 'package:qr/qr.dart';

void main() {
  const downloadUrl =
      'https://github.com/danieltelen/commuNEUcate/releases/latest/download/app-release.apk';
  const quietZone = 4;
  final qr = QrImage(
    QrCode.fromData(
      data: downloadUrl,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    ),
  );
  final size = qr.moduleCount + quietZone * 2;
  final path = StringBuffer();

  for (var row = 0; row < qr.moduleCount; row++) {
    for (var column = 0; column < qr.moduleCount; column++) {
      if (qr.isDark(row, column)) {
        path.write('M${column + quietZone} ${row + quietZone}h1v1h-1z');
      }
    }
  }

  final svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" shape-rendering="crispEdges">
<title>Download CommNEUcate for Android</title>
<desc>Scan to download the Android APK from the latest GitHub release.</desc>
<rect width="$size" height="$size" fill="#fff"/>
<path d="$path" fill="#000"/>
</svg>
''';
  File('communeucate-download-qr.svg').writeAsStringSync(svg);
  stdout.writeln('Created communeucate-download-qr.svg for $downloadUrl');
}

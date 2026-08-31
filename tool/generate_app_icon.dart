import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final sourceFile = File('assets/images/agriai_logo.png');
  final source = img.decodePng(sourceFile.readAsBytesSync());
  if (source == null) {
    throw StateError('Unable to decode ${sourceFile.path}');
  }

  // Use the distinctive plant/circuit emblem for the launcher icon. Keeping
  // the long brand text out makes the mark readable at phone-icon sizes.
  final cropSize = (source.width * 0.558).round();
  final cropped = img.copyCrop(
    source,
    x: (source.width * 0.220).round(),
    y: (source.height * 0.016).round(),
    width: cropSize,
    height: cropSize,
  );
  final emblem = img.copyResize(
    cropped,
    width: 860,
    height: 860,
    interpolation: img.Interpolation.linear,
  );
  final canvas = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(canvas, emblem, center: true);

  File('assets/images/agriai_app_icon.png').writeAsBytesSync(
    img.encodePng(canvas, level: 6),
  );
}

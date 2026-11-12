import 'dart:io';
import 'dart:math';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  if (Platform.environment['DRIVER_SESSION_ID'] != null) {
    final window = await driver.webDriver.window;
    await window.setSize(const Rectangle(0, 0, 430, 1100));
  }
  await integrationDriver(
    driver: driver,
    onScreenshot: (name, image, [arguments]) async {
      final directory = Directory('docs/screenshots');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(image, flush: true);
      return image.isNotEmpty;
    },
  );
}

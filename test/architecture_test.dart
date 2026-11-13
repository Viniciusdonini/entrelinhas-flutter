import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Layer dependencies', () {
    test('models do not import Flutter or backend libraries', () {
      for (final file in _dartFiles('models')) {
        for (final dependency in _dependencies(file)) {
          expect(
            dependency.startsWith('package:flutter/') ||
                dependency == 'dart:ui' ||
                _isRemoteDataPackage(dependency),
            isFalse,
            reason:
                '${file.path} must describe data without UI or backend SDKs '
                '(found $dependency).',
          );
        }
      }
    });

    test('services do not import widgets or screens', () {
      for (final file in _dartFiles('services')) {
        for (final dependency in _dependencies(file)) {
          expect(
            _hasLayer(dependency, 'widgets') ||
                _hasLayer(dependency, 'screens') ||
                _isFlutterWidgetLibrary(dependency),
            isFalse,
            reason:
                '${file.path} must return data rather than interface '
                'components (found $dependency).',
          );
        }
      }
    });

    test('services delegate transport and persistence to repositories', () {
      for (final file in _dartFiles('services')) {
        for (final dependency in _dependencies(file)) {
          expect(
            _isRemoteDataPackage(dependency),
            isFalse,
            reason: '${file.path} must not call backend SDKs directly.',
          );
        }
      }
    });

    test('repositories do not depend on screens, widgets or services', () {
      for (final file in _dartFiles('repositories')) {
        for (final dependency in _dependencies(file)) {
          expect(
            _hasLayer(dependency, 'screens') ||
                _hasLayer(dependency, 'widgets') ||
                _hasLayer(dependency, 'services') ||
                _isFlutterWidgetLibrary(dependency),
            isFalse,
            reason: '${file.path} must implement data access independently.',
          );
        }
      }
    });

    test('screens access remote data through a service', () {
      for (final file in _dartFiles('screens')) {
        for (final dependency in _dependencies(file)) {
          expect(
            _isRemoteDataPackage(dependency) ||
                _hasLayer(dependency, 'repositories') ||
                _hasLayer(dependency, 'network'),
            isFalse,
            reason:
                '${file.path} must delegate backend access to services '
                '(found $dependency).',
          );
        }
      }
    });

    test('core neither imports nor exports screens or services', () {
      for (final file in _dartFiles('core')) {
        for (final dependency in _dependencies(file)) {
          expect(
            _hasLayer(dependency, 'screens') ||
                _hasLayer(dependency, 'services'),
            isFalse,
            reason:
                '${file.path} must remain independent of features '
                '(found $dependency).',
          );
        }
      }
    });
  });

  test('screen and shared-widget files expose one matching public widget', () {
    final publicWidget = RegExp(
      r'\bclass\s+([A-Z]\w*)\s+extends\s+(?:StatelessWidget|StatefulWidget)\b',
    );
    for (final file in [..._dartFiles('screens'), ..._dartFiles('widgets')]) {
      final widgets = publicWidget
          .allMatches(file.readAsStringSync())
          .map((match) => match.group(1)!)
          .toList();
      expect(
        widgets,
        hasLength(1),
        reason: '${file.path} must expose exactly one public widget.',
      );
      if (widgets.length == 1) {
        final filename = file.uri.pathSegments.last;
        expect(
          filename,
          '${_snakeCase(widgets.single)}.dart',
          reason: 'The filename must match ${widgets.single}.',
        );
      }
    }
  });
}

List<File> _dartFiles(String layer) {
  final directory = Directory('lib/$layer');
  expect(
    directory.existsSync(),
    isTrue,
    reason: 'Missing required layer $layer',
  );
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

/// Includes export directives and every URI in conditional imports/exports.
Iterable<String> _dependencies(File file) sync* {
  final directives = RegExp(
    r'''^\s*(?:import|export)\s+([^;]+);''',
    multiLine: true,
  );
  final quotedUri = RegExp(r'''['"]([^'"]+)['"]''');
  for (final directive in directives.allMatches(file.readAsStringSync())) {
    for (final uri in quotedUri.allMatches(directive.group(1)!)) {
      yield uri.group(1)!;
    }
  }
}

bool _hasLayer(String uri, String layer) => uri.split('/').contains(layer);

bool _isRemoteDataPackage(String uri) =>
    RegExp(r'^package:(?:firebase[^/]*|cloud_firestore|http|dio)/')
        .hasMatch(uri);

bool _isFlutterWidgetLibrary(String uri) => RegExp(
  r'^package:flutter/(?:material\.dart|widgets\.dart|cupertino\.dart|'
  r'rendering\.dart|src/(?:material|widgets|cupertino|rendering)/)',
).hasMatch(uri);

String _snakeCase(String name) => name
    .replaceAllMapped(
      RegExp(r'([A-Z]+)([A-Z][a-z])'),
      (match) => '${match[1]}_${match[2]}',
    )
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match[1]}_${match[2]}',
    )
    .toLowerCase();

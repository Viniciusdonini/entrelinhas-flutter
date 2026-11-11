import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/service_messages.dart';
import 'book_service.dart';
import 'firestore_book_service.dart';
import 'service_exception.dart';

/// Receives configuration at build time; no real project identifiers live here.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static const _timeout = Duration(seconds: 15);
  static const _initializationTimeout = Duration(seconds: 60);
  static const _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static bool _emulatorsConnected = false;

  static Future<BookService> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: _options())
            .timeout(_initializationTimeout);
      }

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      if (_useEmulator && !_emulatorsConnected) {
        const configuredHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
        final host = configuredHost.isNotEmpty
            ? configuredHost
            : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : '127.0.0.1';
        if (host.contains('/') || host.contains(':') || host.trim() != host) {
          throw const ServiceException(ServiceMessages.invalidEmulatorHost);
        }
        firestore.settings = const Settings(persistenceEnabled: false);
        firestore.useFirestoreEmulator(host, 8080, automaticHostMapping: false);
        await auth
            .useAuthEmulator(host, 9099, automaticHostMapping: false)
            .timeout(_timeout);
        _emulatorsConnected = true;
      }

      final user =
          auth.currentUser ??
          (await auth.signInAnonymously().timeout(_timeout)).user;
      if (user == null) {
        throw const ServiceException(ServiceMessages.sessionFailed);
      }
      return FirestoreBookService(firestore: firestore, userId: user.uid);
    } on ServiceException {
      rethrow;
    } on TimeoutException {
      throw const ServiceException(ServiceMessages.initializationTimeout);
    } on FirebaseException catch (error) {
      if (error.code == 'operation-not-allowed' ||
          error.code == 'admin-restricted-operation') {
        throw const ServiceException(ServiceMessages.anonymousProviderDisabled);
      }
      if (error.code == 'network-request-failed') {
        throw const ServiceException(ServiceMessages.firebaseUnavailable);
      }
      throw const ServiceException(ServiceMessages.initializationFailed);
    } on Object {
      throw const ServiceException(ServiceMessages.initializationFailed);
    }
  }

  static FirebaseOptions _options() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
    final expectedPlatform = kIsWeb
        ? ':web:'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => ':android:',
            TargetPlatform.iOS || TargetPlatform.macOS => ':ios:',
            _ => ':web:',
          };

    if (!_useEmulator &&
        [apiKey, appId, senderId, projectId].any((value) => value.isEmpty)) {
      throw const ServiceException(ServiceMessages.configurationRequired);
    }
    if (_useEmulator &&
        projectId.isNotEmpty &&
        !projectId.startsWith('demo-')) {
      throw const ServiceException(ServiceMessages.emulatorProjectRequired);
    }
    if (!_useEmulator) {
      final isApple =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
      if (!appId.contains(expectedPlatform) ||
          (isApple && iosBundleId.isEmpty)) {
        throw const ServiceException(
          ServiceMessages.platformConfigurationRequired,
        );
      }
    }

    return FirebaseOptions(
      apiKey: apiKey.isEmpty ? 'demo-api-key-not-a-secret' : apiKey,
      appId: appId.isEmpty
          ? '1:123456789000${expectedPlatform}0000000000000000000000'
          : appId,
      messagingSenderId: senderId.isEmpty ? '123456789000' : senderId,
      projectId: projectId.isEmpty ? 'demo-entrelinhas' : projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    );
  }
}

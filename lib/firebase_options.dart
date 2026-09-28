import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwtZr8eubzB_db05FXaWt3DqUDbnu5Df8',
    appId: '1:883439999168:web:4fae9c0a21f74842b8b525',
    messagingSenderId: '883439999168',
    projectId: 'etherlog',
    authDomain: 'etherlog.firebaseapp.com',
    storageBucket: 'etherlog.firebasestorage.app',
    measurementId: 'G-87SXGREFWB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwtZr8eubzB_db05FXaWt3DqUDbnu5Df8',
    appId: '1:883439999168:android:d48b111111111111111111',
    messagingSenderId: '883439999168',
    projectId: 'etherlog',
    storageBucket: 'etherlog.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwtZr8eubzB_db05FXaWt3DqUDbnu5Df8',
    appId: '1:883439999168:ios:d48b111111111111111111',
    messagingSenderId: '883439999168',
    projectId: 'etherlog',
    storageBucket: 'etherlog.firebasestorage.app',
    iosBundleId: 'com.etherlog.etherlog',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDwtZr8eubzB_db05FXaWt3DqUDbnu5Df8',
    appId: '1:883439999168:ios:d48b111111111111111111',
    messagingSenderId: '883439999168',
    projectId: 'etherlog',
    storageBucket: 'etherlog.firebasestorage.app',
    iosBundleId: 'com.etherlog.etherlog',
  );
}

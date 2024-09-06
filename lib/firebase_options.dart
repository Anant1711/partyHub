// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBx65GKA1RKjhq5yzNkrEvGDRdjvxuUSxU',
    appId: '1:201814951789:web:8aba32279174d6ced57c64',
    messagingSenderId: '201814951789',
    projectId: 'hubp-7657a',
    authDomain: 'hubp-7657a.firebaseapp.com',
    storageBucket: 'hubp-7657a.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBTv9cNX3j1tP8-6nY0WEB8WUwq-LRwFb4',
    appId: '1:201814951789:android:c2bdf378f73dae6ed57c64',
    messagingSenderId: '201814951789',
    projectId: 'hubp-7657a',
    storageBucket: 'hubp-7657a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyADwNcu8Yn7_E3pEDwM1mEFBCr_ja6kMIA',
    appId: '1:201814951789:ios:88e375b10910d874d57c64',
    messagingSenderId: '201814951789',
    projectId: 'hubp-7657a',
    storageBucket: 'hubp-7657a.appspot.com',
    androidClientId: '201814951789-8hja1h9a8mcrv2tet792811aisll5afv.apps.googleusercontent.com',
    iosClientId: '201814951789-1hop6h00g6sj51m8v4raeoh0ug6ornlm.apps.googleusercontent.com',
    iosBundleId: 'com.example.clique',
  );
}
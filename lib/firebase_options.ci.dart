// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
// CI placeholder — does NOT contain real Firebase credentials.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'ci-placeholder',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ci-placeholder',
    storageBucket: 'ci-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'ci-placeholder',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ci-placeholder',
    storageBucket: 'ci-placeholder.appspot.com',
    iosBundleId: 'com.iqub.iqub',
  );
}

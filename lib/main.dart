import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before running the app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // ProviderScope is required at the root for Riverpod to work
    const ProviderScope(child: IqubApp()),
  );
}

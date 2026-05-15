// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Pour l'instant on configure pour le web
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "",//mettre ici l api key de firebase
    authDomain: "pilates-app-4430c.firebaseapp.com",
    projectId: "pilates-app-4430c",
    storageBucket: "pilates-app-4430c.firebasestorage.app",
    messagingSenderId: "330283354212",
    appId: "1:330283354212:web:e8516915cdf03d1a717771",
  );
}

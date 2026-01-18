import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDBWBndErw2KVNQaiBx7_PDyBnAFKve-a8",
            authDomain: "redivo-k8jip5.firebaseapp.com",
            projectId: "redivo-k8jip5",
            storageBucket: "redivo-k8jip5.firebasestorage.app",
            messagingSenderId: "302509052594",
            appId: "1:302509052594:web:7a99f3bcd8115a6f0eafab"));
  } else {
    await Firebase.initializeApp();
  }
}

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyD7UaxOaDGy5IZRQGrrUx5l5unraQU5zKQ",
      authDomain: "uas-palp.firebaseapp.com",
      projectId: "uas-palp",
      storageBucket: "uas-palp.firebasestorage.app",
      messagingSenderId: "565176457928",
      appId: "1:565176457928:web:5721f509a8c0496b9163fd" 
    );
  }
}
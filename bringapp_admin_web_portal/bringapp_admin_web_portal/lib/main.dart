import 'package:bringapp_admin_web_portal/authentication/login_screen.dart';
import 'package:bringapp_admin_web_portal/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // 🔧 Replace these with your actual Firebase Web app config
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDtXBs5PcSAl0ApoJmeolx-mrI3XCgffJo",
        authDomain: "food-app-95d46.firebaseapp.com",
        projectId: "food-app-95d46",
        storageBucket: "food-app-95d46.firebasestorage.app",
        messagingSenderId: "119697802402",
        appId:"1:119697802402:web:9ceb602790a890149803fb",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Web Portal',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}

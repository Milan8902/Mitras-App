import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:users_food_app/assistantMethods/address_changer.dart';
import 'package:users_food_app/assistantMethods/cart_item_counter.dart';
import 'package:users_food_app/assistantMethods/total_amount.dart';
import 'firebase_options.dart';

import 'global/global.dart';
import 'splash_screen/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Storage
  FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 30));
  FirebaseStorage.instance.setMaxOperationRetryTime(const Duration(seconds: 30));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ((c) => CartItemCounter())),
        ChangeNotifierProvider(create: ((c) => TotalAmount())),
        ChangeNotifierProvider(create: ((c) => AddressChanger())),
      ],
      child: MaterialApp(
        title: 'Users App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.amber),
        home: const SplashScreen(),
      ),
    );
  }
}

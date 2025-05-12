import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../authentication/register.dart';

import '../global/global.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_dialog.dart';
import '../widgets/header_widget.dart';
import '../widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final double _headerHeight = 250;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  //form validation for login
  formValidation() {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      //login
      loginNow();
    } else {
      showDialog(
        context: context,
        builder: (c) {
          return const ErrorDialog(message: "Please enter email/password.");
        },
      );
    }
  }

  //login function
  loginNow() async {
    showDialog(
      context: context,
      builder: (c) {
        return const LoadingDialog(message: "Checking Credentials...");
      },
    );

    User? currentUser;
    await firebaseAuth
        .signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        )
        .then((auth) {
          currentUser = auth.user!;
        })
        .catchError((error) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (c) {
              return ErrorDialog(message: error.message.toString());
            },
          );
        });
    if (currentUser != null) {
      readDataAndSetDataLocally(currentUser!);
    }
  }

  //read data from firestore and save it locally
  Future readDataAndSetDataLocally(User currentUser) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (!snapshot.exists) {
        throw Exception("No record exists for this user.");
      }

      Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception("Invalid user data format");
      }

      // Validate required fields
      if (userData["status"] != "approved") {
        throw Exception("Your account has been blocked!");
      }

      if (userData["email"] == null || userData["name"] == null) {
        throw Exception("User data is incomplete. Please contact support.");
      }

      // Validate and clean cart data
      List<String> userCartList = [];
      if (userData.containsKey("userCart") && userData["userCart"] is List) {
        List<dynamic> cartItems = userData["userCart"];
        userCartList = cartItems
            .where((item) => item is String && item != "garbageValue")
            .map((item) => item.toString())
            .toList();
      }

      // Save validated data locally
      await sharedPreferences!.setString("uid", currentUser.uid);
      await sharedPreferences!.setString("email", userData["email"]);
      await sharedPreferences!.setString("name", userData["name"]);
      await sharedPreferences!.setString("photoUrl", userData["photoUrl"] ?? "");
      await sharedPreferences!.setStringList("userCart", userCartList);

      // Update Firestore with cleaned cart data if needed
      if (userCartList.length != (userData["userCart"] as List).length) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid)
            .update({
          "userCart": userCartList.isEmpty ? ["garbageValue"] : userCartList,
        });
      }

      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const HomeScreen()),
        );
      }
    } catch (e) {
      print("Error during login: $e");
      
      // Cleanup on error
      try {
        await firebaseAuth.signOut();
        await sharedPreferences!.clear();
      } catch (cleanupError) {
        print("Error during cleanup: $cleanupError");
      }

      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        
        String errorMessage = "Login failed. ";
        if (e.toString().contains("blocked")) {
          errorMessage = "Your account has been blocked!";
        } else if (e.toString().contains("No record")) {
          errorMessage = "No account found with these credentials.";
        } else if (e.toString().contains("invalid-email")) {
          errorMessage = "Invalid email format.";
        } else if (e.toString().contains("wrong-password")) {
          errorMessage = "Incorrect password.";
        } else if (e.toString().contains("user-not-found")) {
          errorMessage = "No account found with this email.";
        } else if (e.toString().contains("too-many-requests")) {
          errorMessage = "Too many attempts. Please try again later.";
        } else {
          errorMessage += "Please try again.";
        }

        showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(message: errorMessage);
          },
        );

        // Redirect to login screen if session is invalid
        if (e.toString().contains("No record") || 
            e.toString().contains("blocked") ||
            e.toString().contains("incomplete")) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [Color(0xFFFFFFFF), Color(0xFFFAC898)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: _headerHeight,
                child: HeaderWidget(
                  height: _headerHeight,
                  showIcon: true,
                  icon: Icons.food_bank,
                ), //let's create a common header widget
              ),
              const SizedBox(height: 50),
              Center(
                child: Text(
                  'Login',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      data: Icons.email,
                      controller: emailController,
                      hintText: "Email",
                      isObsecre: false,
                    ),
                    CustomTextField(
                      data: Icons.lock,
                      controller: passwordController,
                      hintText: "Password",
                      isObsecre: !_isPasswordVisible,
                      onVisibilityChanged: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          // Navigator.push( context, MaterialPageRoute( builder: (context) => ForgotPasswordPage()), );
                        },
                        child: const Text(
                          "Forgot your password?",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 5.0,
                          ),
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 1.0],
                          colors: [Colors.amber, Colors.black],
                        ),
                        color: Colors.deepPurple.shade300,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                          minimumSize: MaterialStateProperty.all(
                            const Size(50, 50),
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          shadowColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                          child: Text(
                            'Sign In'.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onPressed: () {
                          formValidation();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Create',
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const RegisterScreen(),
                                        ),
                                      );
                                    },
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../authentication/login.dart';
import '../global/global.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_dialog.dart';
import '../widgets/header_widget.dart';
import '../widgets/loading_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Image picker
  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();

  // Function for getting image
  Future<void> _getImage() async {
    try {
      imageXFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (imageXFile != null) {
        setState(() {});
      }
    } catch (e) {
      print("Error picking image: $e");
      showDialog(
        context: context,
        builder: (c) {
          return ErrorDialog(
            message: "Failed to pick image. Please try again.",
          );
        },
      );
    }
  }

  // Convert image to Base64
  Future<String> convertImageToBase64(XFile image) async {
    try {
      File imageFile = File(image.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print("Error converting image to base64: $e");
      throw Exception("Failed to process image. Please try again.");
    }
  }

  // Form Validation
  Future<void> signUpFormValidation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (imageXFile == null) {
      showDialog(
        context: context,
        builder: (c) {
          return const ErrorDialog(message: "Please select a profile image");
        },
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert image to base64 string
      String base64Image = await convertImageToBase64(imageXFile!);
      
      // Authenticate and sign up the user
      await AuthenticateSellerAndSignUp(base64Image);
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (c) {
          return ErrorDialog(message: error.toString());
        },
      );
    }
  }

  Future<void> AuthenticateSellerAndSignUp(String base64Image) async {
    User? currentUser;
    try {
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
        throw Exception("Please enter a valid email address");
      }

      // Validate password
      if (passwordController.text.length < 6) {
        throw Exception("Password must be at least 6 characters long");
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) {
          return const LoadingDialog(message: "Creating Account...");
        },
      );

      print("Starting user creation process...");

      // Create user with email and password
      final authResult = await firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      currentUser = authResult.user;
      print("Firebase Auth successful: ${currentUser?.uid}");

      if (currentUser != null) {
        try {
          print("Starting user data save...");
          // Save user data with base64 image
          await saveDataToFirestore(currentUser, base64Image);
          print("User data saved successfully");
          
          // Clear form fields
          nameController.clear();
          emailController.clear();
          passwordController.clear();
          confirmpasswordController.clear();
          setState(() {
            imageXFile = null;
            _isLoading = false;
          });

          Navigator.pop(context); // Remove loading dialog
          Route newRoute = MaterialPageRoute(builder: (c) => const HomeScreen());
          Navigator.pushReplacement(context, newRoute);
        } catch (error) {
          print("Error in registration process: $error");
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (c) {
              return ErrorDialog(message: error.toString());
            },
          );
          // Clean up the created user if data saving fails
          try {
            await currentUser.delete();
          } catch (deleteError) {
            print("Error deleting user after failed data save: $deleteError");
          }
        }
      }
    } catch (error) {
      print("Firebase Auth Error: $error");
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (c) {
          return ErrorDialog(
            message: error is FirebaseAuthException 
                ? _getAuthErrorMessage(error) 
                : error.toString()
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveDataToFirestore(User currentUser, String base64Image) async {
    try {
      // First check if the user document already exists
      final userDocRef = FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid);
      
      // Prepare user data
      final Map<String, dynamic> userData = {
        "uid": currentUser.uid,
        "email": currentUser.email,
        "name": nameController.text.trim(),
        "photoBase64": base64Image,
        "status": "approved",
        "userCart": ['garbageValue'],
        "createdAt": FieldValue.serverTimestamp(),
        "lastUpdated": FieldValue.serverTimestamp(),
        "phone": "",
        "address": "",
        "userType": "user",
        "isActive": true,
        "registrationDate": FieldValue.serverTimestamp(),
      };
      
      print("Attempting to save user data for: ${userData['email']}");
      
      // Create user document
      await userDocRef.set(userData);
      print("User document created successfully");

      // Create cart collection
      await userDocRef.collection("cart").doc("items").set({
        "items": [],
        "lastUpdated": FieldValue.serverTimestamp(),
      });
      print("Cart collection created successfully");

      // Create orders collection
      await userDocRef.collection("orders").doc("metadata").set({
        "lastOrderId": null,
        "createdAt": FieldValue.serverTimestamp(),
      });
      print("Orders collection created successfully");

      // Save data locally
      try {
        sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences!.setString("uid", currentUser.uid);
        await sharedPreferences!.setString("email", currentUser.email.toString());
        await sharedPreferences!.setString("name", nameController.text.trim());
        await sharedPreferences!.setString("photoBase64", base64Image);
        await sharedPreferences!.setStringList("userCart", ['garbageValue']);
        print("Local data saved successfully");
      } catch (localError) {
        print("Error saving local data: $localError");
        // Continue even if local save fails
      }
    } catch (error) {
      print("Error in saveDataToFirestore: $error");
      if (error is FirebaseException) {
        switch (error.code) {
          case 'permission-denied':
            throw Exception("Permission denied. Please check your Firebase configuration.");
          case 'not-found':
            throw Exception("Failed to create user document. Please try again.");
          case 'already-exists':
            throw Exception("User document already exists.");
          case 'invalid-argument':
            throw Exception("Invalid user data provided. Please check your input.");
          case 'unavailable':
            throw Exception("Firebase service is currently unavailable. Please try again later.");
          default:
            throw Exception("Failed to save user data: ${error.message}");
        }
      }
      throw Exception("Failed to save user data: ${error.toString()}");
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'Please use a stronger password.';
      default:
        return 'Failed to create account: ${error.message}';
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
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFAC898),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                children: [
                  const HeaderWidget(
                    height: 150,
                    showIcon: false,
                    icon: Icons.add,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    margin: const EdgeInsets.fromLTRB(25, 50, 25, 10),
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: _isLoading ? null : _getImage,
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.20,
                        backgroundColor: Colors.white,
                        backgroundImage: imageXFile == null
                            ? null
                            : FileImage(File(imageXFile!.path)),
                        child: imageXFile == null
                            ? Icon(
                                Icons.person_add_alt_1,
                                size: MediaQuery.of(context).size.width * 0.20,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      data: Icons.person,
                      controller: nameController,
                      hintText: "Name",
                      isObsecre: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      data: Icons.email,
                      controller: emailController,
                      hintText: "Email",
                      isObsecre: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      data: Icons.lock,
                      controller: confirmpasswordController,
                      hintText: "Confirm Password",
                      isObsecre: !_isConfirmPasswordVisible,
                      onVisibilityChanged: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 5.0)
                    ],
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 1.0],
                      colors: [
                        Colors.amber,
                        Colors.black,
                      ],
                    ),
                    color: Colors.deepPurple.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all(const Size(50, 50)),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.transparent),
                      shadowColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                    onPressed: _isLoading ? null : signUpFormValidation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                      child: Text(
                        _isLoading ? 'Creating Account...' : 'Sign Up'.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: "Already have an account? "),
                      TextSpan(
                        text: 'Login',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()));
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
      ),
    );
  }
}

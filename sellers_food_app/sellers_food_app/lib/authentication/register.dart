import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;
import 'package:shared_preferences/shared_preferences.dart';

import '../global/global.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_dialog.dart';
import '../widgets/header_widget.dart';
import '../widgets/loading_dialog.dart';
import 'login.dart';

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
  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();

  Position? position;
  List<Placemark>? placeMarks;
  String completeAddress = "";
  String sellerImageBase64 = "";

  Future<void> _getImage() async {
    try {
      imageXFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (imageXFile != null) {
        final bytes = await imageXFile!.readAsBytes();
        sellerImageBase64 = base64Encode(bytes);
        setState(() {});
      }
    } catch (e) {
      print("Error picking image: $e");
      showDialog(
        context: context,
        builder: (c) => ErrorDialog(
          message: "Failed to pick image. Please try again.",
        ),
      );
    }
  }

  Future<void> getCurrenLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showDialog(
          context: context,
          builder: (c) => const ErrorDialog(
            message: "Location services are disabled. Please enable location services to continue.",
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showDialog(
            context: context,
            builder: (c) => const ErrorDialog(
              message: "Location permission is required to get your address.",
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showDialog(
          context: context,
          builder: (c) => const ErrorDialog(
            message: "Location permissions are permanently denied. Please enable location permissions in your device settings.",
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (c) => const LoadingDialog(message: "Getting your location..."),
      );

      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        newPosition.latitude,
        newPosition.longitude,
      );

      Navigator.pop(context);

      if (placemarks.isNotEmpty) {
        Placemark pMark = placemarks[0];
        setState(() {
          position = newPosition;
          placeMarks = placemarks;
          completeAddress = '${pMark.thoroughfare ?? ''}, ${pMark.locality ?? ''}, ${pMark.subAdministrativeArea ?? ''}, ${pMark.administrativeArea ?? ''}, ${pMark.country ?? ''}';
          locationController.text = completeAddress;
        });
      } else {
        showDialog(
          context: context,
          builder: (c) => const ErrorDialog(
            message: "Could not get address from location. Please try again.",
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showDialog(
        context: context,
        builder: (c) => ErrorDialog(
          message: "Error getting location: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> signUpFormValidation() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (imageXFile == null) {
        showDialog(
          context: context,
          builder: (c) => const ErrorDialog(message: "Please select a profile image"),
        );
        return;
      }

      if (position == null || completeAddress.isEmpty) {
        showDialog(
          context: context,
          builder: (c) => const ErrorDialog(message: "Please get your location first"),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      await AuthenticateSellerAndSignUp();
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => ErrorDialog(
            message: error is FirebaseAuthException 
                ? _getAuthErrorMessage(error) 
                : "Registration failed: ${error.toString()}",
          ),
        );
      }
    }
  }

  Future<void> AuthenticateSellerAndSignUp() async {
    User? currentUser;
    try {
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
        throw Exception("Please enter a valid email address");
      }

      // Validate password length
      if (passwordController.text.length < 6) {
        throw Exception("Password must be at least 6 characters long");
      }

      // Validate phone number
      if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(phoneController.text.trim())) {
        throw Exception("Please enter a valid phone number");
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const LoadingDialog(message: "Creating Account..."),
        );
      }

      // Create user account
      final authResult = await firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      currentUser = authResult.user;

      if (currentUser != null) {
        try {
          // Save user data to Firestore
          await saveDataToFirestore(currentUser);
          
          // Clear form data
          nameController.clear();
          emailController.clear();
          passwordController.clear();
          confirmpasswordController.clear();
          phoneController.clear();
          locationController.clear();
          
          if (mounted) {
            setState(() {
              imageXFile = null;
              _isLoading = false;
            });

            Navigator.pop(context); // Remove loading dialog
            Route newRoute = MaterialPageRoute(builder: (c) => const HomeScreen());
            Navigator.pushReplacement(context, newRoute);
          }
        } catch (error) {
          if (mounted) {
            Navigator.pop(context); // Remove loading dialog
            showDialog(
              context: context,
              builder: (c) => ErrorDialog(
                message: "Failed to save user data: ${error.toString()}",
              ),
            );
          }
          // Clean up the created user if data save fails
          try {
            await currentUser.delete();
          } catch (deleteError) {
            print("Error deleting user after failed data save: $deleteError");
          }
        }
      }
    } catch (error) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        showDialog(
          context: context,
          builder: (c) => ErrorDialog(
            message: error is FirebaseAuthException 
                ? _getAuthErrorMessage(error) 
                : "Registration failed: ${error.toString()}",
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> saveDataToFirestore(User currentUser) async {
    try {
      // Validate required data
      if (position == null) {
        throw Exception("Location data is missing");
      }
      if (sellerImageBase64.isEmpty) {
        throw Exception("Profile image is missing");
      }

      final sellerDocRef = FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid);
      
      final Map<String, dynamic> sellerData = {
        "sellerUID": currentUser.uid,
        "sellerEmail": currentUser.email,
        "sellerName": nameController.text.trim(),
        "sellerAvatarBase64": sellerImageBase64,
        "phone": phoneController.text.trim(),
        "address": completeAddress,
        "status": "approved",
        "earnings": 0.0,
        "lat": position!.latitude,
        "lng": position!.longitude,
        "createdAt": FieldValue.serverTimestamp(),
        "lastUpdated": FieldValue.serverTimestamp(),
        "isActive": true,
        "registrationDate": FieldValue.serverTimestamp(),
      };
      
      // Save seller data
      await sellerDocRef.set(sellerData);

      // Create menus collection
      await sellerDocRef.collection("menus").doc("metadata").set({
        "lastMenuId": null,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Create orders collection
      await sellerDocRef.collection("orders").doc("metadata").set({
        "lastOrderId": null,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Save data locally
      sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences!.setString("uid", currentUser.uid);
      await sharedPreferences!.setString("email", currentUser.email.toString());
      await sharedPreferences!.setString("name", nameController.text.trim());
      await sharedPreferences!.setString("photoBase64", sellerImageBase64);
    } catch (e) {
      throw Exception("Failed to save seller data: ${e.toString()}");
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
              Stack(
                children: [
                  const SizedBox(
                    height: 150,
                    child: HeaderWidget(150, false, Icons.add),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(25, 50, 25, 10),
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: _getImage,
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
                      hintText: "Confirm password",
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
                    CustomTextField(
                      data: Icons.phone_android_outlined,
                      controller: phoneController,
                      hintText: "Phone number",
                      isObsecre: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            data: Icons.my_location,
                            controller: locationController,
                            hintText: "Restaurant Address",
                            isObsecre: false,
                            enabled: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please get your location';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: getCurrenLocation,
                          icon: const Icon(Icons.location_on, size: 40),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Container(
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
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(50, 50),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : signUpFormValidation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Sign Up'.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
                                builder: (context) => const LoginScreen(),
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
      ),
    );
  }
}


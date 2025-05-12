import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../global/global.dart';
import '../authentication/login.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ImagePicker _picker = ImagePicker();
  XFile? imageXFile;
  String userImageUrl = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    try {
      if (sharedPreferences == null || sharedPreferences!.getString("uid") == null) {
        throw Exception("User session not found. Please login again.");
      }

      String uid = sharedPreferences!.getString("uid")!;
      if (uid.isEmpty) {
        throw Exception("Invalid user ID");
      }

      // First check if the user document exists
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        // If document doesn't exist, create it with basic user data
        Map<String, dynamic> userData = {
          "uid": uid,
          "name": sharedPreferences!.getString("name")?.trim() ?? "",
          "email": sharedPreferences!.getString("email")?.trim() ?? "",
          "phone": sharedPreferences!.getString("phone")?.trim() ?? "",
          "address": sharedPreferences!.getString("address")?.trim() ?? "",
          "photoUrl": sharedPreferences!.getString("photoUrl")?.trim() ?? "",
          "status": "approved",
          "userCart": ["garbageValue"],
        };

        // Validate data before saving
        if (userData["name"].toString().isEmpty || userData["email"].toString().isEmpty) {
          throw Exception("Invalid user data");
        }

        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .set(userData);

        // Verify the document was created
        DocumentSnapshot verifyDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get();

        if (!verifyDoc.exists) {
          throw Exception("Failed to create user document");
        }
      } else {
        // Verify user status
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) {
          throw Exception("Invalid user data format");
        }
        if (userData["status"] != "approved") {
          throw Exception("Your account is not approved. Please contact support.");
        }
      }

      // Now load the data
      _nameController.text = sharedPreferences!.getString("name")?.trim() ?? "";
      _emailController.text = sharedPreferences!.getString("email")?.trim() ?? "";
      _phoneController.text = sharedPreferences!.getString("phone")?.trim() ?? "";
      _addressController.text = sharedPreferences!.getString("address")?.trim() ?? "";

      // Verify data consistency
      if (_emailController.text.isEmpty || _nameController.text.isEmpty) {
        throw Exception("User data is incomplete. Please login again.");
      }
    } catch (e) {
      print("Error loading user data: $e");
      // If there's an error, try to sign out and redirect to login
      try {
        await FirebaseAuth.instance.signOut();
        await sharedPreferences!.clear();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (c) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (signOutError) {
        print("Error signing out: $signOutError");
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: "Session error. Please login again.",
            );
          },
        );
      }
    }
  }

  Future<void> _getImage() async {
    imageXFile = await _picker.pickImage(source: ImageSource.gallery);
    if (imageXFile != null) {
      setState(() {});
      _updateProfileImage();
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return const LoadingDialog(message: "Updating profile image...");
        },
      );

      String base64Image = await convertImageToBase64(imageXFile!);
      
      // First check if the document exists
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(sharedPreferences!.getString("uid"))
          .get();

      if (!userDoc.exists) {
        // If document doesn't exist, create it
        await FirebaseFirestore.instance
            .collection("users")
            .doc(sharedPreferences!.getString("uid"))
            .set({
          "photoUrl": base64Image,
          "status": "approved",
          "userCart": ["garbageValue"],
        });
      } else {
        // Update existing document
        await FirebaseFirestore.instance
            .collection("users")
            .doc(sharedPreferences!.getString("uid"))
            .update({
          "photoUrl": base64Image,
        });
      }

      await sharedPreferences!.setString("photoUrl", base64Image);

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile image updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      print("Error updating profile image: $e");
      showDialog(
        context: context,
        builder: (c) {
          return ErrorDialog(
            message: "Error updating profile image. Please try again later.",
          );
        },
      );
    }
  }

  Future<String> convertImageToBase64(XFile image) async {
    try {
      File imageFile = File(image.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print("Error converting image to base64: $e");
      return '';
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (sharedPreferences == null || sharedPreferences!.getString("uid") == null) {
        throw Exception("User session not found. Please login again.");
      }

      String uid = sharedPreferences!.getString("uid")!;
      if (uid.isEmpty) {
        throw Exception("Invalid user ID");
      }

      // Validate input data
      String name = _nameController.text.trim();
      String phone = _phoneController.text.trim();
      String address = _addressController.text.trim();

      if (name.isEmpty) {
        throw Exception("Name cannot be empty");
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return const LoadingDialog(message: "Updating profile...");
        },
      );

      // First check if the document exists
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User document not found. Please login again.");
      }

      // Verify user status
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception("Invalid user data format");
      }
      if (userData["status"] != "approved") {
        throw Exception("Your account is not approved. Please contact support.");
      }

      // Update the document with validated data
      Map<String, dynamic> updateData = {
        "name": name,
        "phone": phone,
        "address": address,
      };

      // Remove any empty fields to avoid invalid arguments
      updateData.removeWhere((key, value) => value.toString().isEmpty);

      if (updateData.isEmpty) {
        throw Exception("No valid data to update");
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update(updateData);

      // Verify the update
      DocumentSnapshot verifyDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!verifyDoc.exists) {
        throw Exception("Failed to update profile. Please try again.");
      }

      Map<String, dynamic>? verifyData = verifyDoc.data() as Map<String, dynamic>?;
      if (verifyData == null) {
        throw Exception("Invalid data format after update");
      }

      // Verify only the fields that were updated
      bool updateSuccessful = true;
      if (updateData.containsKey("name") && verifyData["name"] != name) updateSuccessful = false;
      if (updateData.containsKey("phone") && verifyData["phone"] != phone) updateSuccessful = false;
      if (updateData.containsKey("address") && verifyData["address"] != address) updateSuccessful = false;

      if (!updateSuccessful) {
        throw Exception("Failed to update profile. Please try again.");
      }

      // Update local storage
      if (updateData.containsKey("name")) {
        await sharedPreferences!.setString("name", name);
      }
      if (updateData.containsKey("phone")) {
        await sharedPreferences!.setString("phone", phone);
      }
      if (updateData.containsKey("address")) {
        await sharedPreferences!.setString("address", address);
      }

      Navigator.pop(context);
      
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      print("Error updating profile: $e");
      
      // If there's a session error, sign out and redirect to login
      if (e.toString().contains("session") || 
          e.toString().contains("not found") || 
          e.toString().contains("invalid")) {
        try {
          await FirebaseAuth.instance.signOut();
          await sharedPreferences!.clear();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (c) => const LoginScreen()),
              (route) => false,
            );
          }
        } catch (signOutError) {
          print("Error signing out: $signOutError");
        }
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: e.toString().contains("session") || 
                      e.toString().contains("not found") || 
                      e.toString().contains("invalid")
                  ? "Session error. Please login again."
                  : "Error updating profile: ${e.toString()}",
            );
          },
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (c) {
          return const ErrorDialog(message: "New passwords do not match!");
        },
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return const LoadingDialog(message: "Changing password...");
        },
      );

      AuthCredential credential = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _currentPasswordController.text.trim(),
      );

      await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);
      await FirebaseAuth.instance.currentUser!.updatePassword(_newPasswordController.text.trim());

      Navigator.pop(context);
      
      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (c) {
          return ErrorDialog(message: "Error changing password: $e");
        },
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Delete Account',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return const LoadingDialog(message: "Deleting account...");
        },
      );

      String uid = sharedPreferences!.getString("uid")!;
      if (uid.isEmpty) {
        throw Exception("Invalid user ID");
      }

      // Start a Firestore transaction to ensure atomic operations
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get user document
        DocumentSnapshot userDoc = await transaction.get(
          FirebaseFirestore.instance.collection("users").doc(uid)
        );

        if (!userDoc.exists) {
          throw Exception("User document not found");
        }

        // Get user data for cleanup
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) {
          throw Exception("Invalid user data format");
        }

        // Delete user's cart items if they exist
        if (userData.containsKey("userCart") && userData["userCart"] is List) {
          List<dynamic> cartItems = userData["userCart"];
          for (var item in cartItems) {
            if (item is String && item != "garbageValue") {
              // Delete cart item document if it exists
              DocumentReference cartItemRef = FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .collection("cart")
                  .doc(item);
              
              DocumentSnapshot cartItemDoc = await transaction.get(cartItemRef);
              if (cartItemDoc.exists) {
                transaction.delete(cartItemRef);
              }
            }
          }
        }

        // Delete user's orders if they exist
        QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
            .collection("orders")
            .where("uid", isEqualTo: uid)
            .get();

        for (var doc in ordersSnapshot.docs) {
          transaction.delete(doc.reference);
        }

        // Delete user document
        transaction.delete(userDoc.reference);

        // Delete any other user-related collections
        // For example, if you have a "favorites" collection
        QuerySnapshot favoritesSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("favorites")
            .get();

        for (var doc in favoritesSnapshot.docs) {
          transaction.delete(doc.reference);
        }
      });

      // After successful deletion of Firestore data, delete authentication
      await FirebaseAuth.instance.currentUser!.delete();

      // Clear shared preferences
      await sharedPreferences!.clear();

      Navigator.pop(context); // Remove loading dialog
      
      // Navigate to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading dialog
      print("Error deleting account: $e");
      
      String errorMessage = "Error deleting account. ";
      if (e.toString().contains("requires-recent-login")) {
        errorMessage += "Please login again before deleting your account.";
      } else if (e.toString().contains("not-found")) {
        errorMessage += "User data not found.";
      } else if (e.toString().contains("permission-denied")) {
        errorMessage += "Permission denied. Please try again later.";
      } else {
        errorMessage += "Please try again later.";
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: errorMessage,
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_isChangingPassword)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: Colors.black,
              ),
              onPressed: () {
                if (_isEditing) {
                  _updateProfile();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFFFF3E0)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Profile Picture
                  GestureDetector(
                    onTap: _isEditing ? _getImage : null,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: sharedPreferences!.getString("photoUrl") != null
                                ? (sharedPreferences!.getString("photoUrl")!.startsWith('http')
                                    ? NetworkImage(sharedPreferences!.getString("photoUrl")!)
                                    : MemoryImage(base64Decode(sharedPreferences!.getString("photoUrl")!)))
                                : const AssetImage('images/user.png') as ImageProvider,
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading profile image: $exception');
                            },
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  if (!_isChangingPassword) ...[
                    // Profile Information
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoField(
                            label: 'Name',
                            controller: _nameController,
                            icon: Icons.person,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildInfoField(
                            label: 'Email',
                            controller: _emailController,
                            icon: Icons.email,
                            enabled: false,
                          ),
                          const SizedBox(height: 20),
                          _buildInfoField(
                            label: 'Phone',
                            controller: _phoneController,
                            icon: Icons.phone,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildInfoField(
                            label: 'Address',
                            controller: _addressController,
                            icon: Icons.location_on,
                            enabled: _isEditing,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Column(
                      children: [
                        _buildActionButton(
                          icon: Icons.lock,
                          label: 'Change Password',
                          onTap: () {
                            setState(() {
                              _isChangingPassword = true;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildActionButton(
                          icon: Icons.delete_forever,
                          label: 'Delete Account',
                          onTap: _deleteAccount,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Change Password Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPasswordField(
                            label: 'Current Password',
                            controller: _currentPasswordController,
                            isVisible: _isPasswordVisible,
                            onVisibilityChanged: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            label: 'New Password',
                            controller: _newPasswordController,
                            isVisible: _isNewPasswordVisible,
                            onVisibilityChanged: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            label: 'Confirm New Password',
                            controller: _confirmPasswordController,
                            isVisible: _isConfirmPasswordVisible,
                            onVisibilityChanged: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isChangingPassword = false;
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Change Password'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Colors.orange),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onVisibilityChanged,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isDestructive
              ? const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                )
              : const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: (isDestructive ? Colors.red : Colors.orange).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
} 
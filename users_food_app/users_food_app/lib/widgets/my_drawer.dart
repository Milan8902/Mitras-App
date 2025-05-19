import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:users_food_app/authentication/login.dart';
import 'package:users_food_app/global/global.dart';
import 'package:users_food_app/screens/address_screen.dart';
import 'package:users_food_app/screens/history_screen.dart';
import 'package:users_food_app/screens/home_screen.dart';
import 'package:users_food_app/screens/my_orders_screen.dart';
import 'package:users_food_app/screens/profile_screen.dart';
import 'package:users_food_app/screens/search_screen.dart';
import 'dart:convert';

class MyDrawer extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  MyDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
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
        child: ListView(
          children: [
            //header drawer
            Container(
              padding: const EdgeInsets.only(top: 25, bottom: 10),
              child: Column(
                children: [
                  Material(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(80),
                    ),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: SizedBox(
                        height: 160,
                        width: 160,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                offset: const Offset(-1, 10),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            //we get the profile image from sharedPreferences (global.dart)
                            backgroundImage: sharedPreferences!.getString("photoUrl") != null
                                ? (sharedPreferences!.getString("photoUrl")!.startsWith('http')
                                    ? NetworkImage(sharedPreferences!.getString("photoUrl")!)
                                    : MemoryImage(base64Decode(sharedPreferences!.getString("photoUrl")!)))
                                : const AssetImage('images/user.png') as ImageProvider,
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading profile image: $exception');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  //we get the user name from sharedPreferences (global.dart)
                  Text(
                    sharedPreferences!.getString("name")!,
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            //body drawer
            Container(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                children: [
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.home,
                      color: Colors.black,
                      size: 25,
                    ),
                    title: Text(
                      'Home',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: ((context) => const HomeScreen()),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 25,
                    ),
                    title: Text(
                      'My Profile',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.reorder,
                      color: Colors.black,
                      size: 25,
                    ),
                    title: Text(
                      'My Orders',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const MyOrdersScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: Colors.black,
                      size: 25,
                    ),
                    title: Text(
                      'History',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: ((context) => const HistoryScreen()),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.black,
                      size: 25,
                    ),
                    title: Text(
                      'About Us',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'About Us',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAboutItem(
                                    icon: Icons.restaurant,
                                    title: 'Our Story',
                                    content: 'Welcome to FoodApp, your ultimate destination for delicious food delivery. We connect food lovers with the best local restaurants, bringing culinary excellence right to your doorstep.',
                                  ),
                                  const SizedBox(height: 15),
                                  _buildAboutItem(
                                    icon: Icons.emoji_events,
                                    title: 'Our Mission',
                                    content: 'To revolutionize food delivery by providing a seamless, reliable, and delightful experience for both customers and restaurant partners.',
                                  ),
                                  const SizedBox(height: 15),
                                  _buildAboutItem(
                                    icon: Icons.thumb_up,
                                    title: 'Why Choose Us',
                                    content: '• Fast and reliable delivery\n• Wide variety of restaurants\n• Easy ordering process\n• Secure payment options\n• Real-time order tracking',
                                  ),
                                  const SizedBox(height: 15),
                                  _buildAboutItem(
                                    icon: Icons.update,
                                    title: 'App Version',
                                    content: 'Version 1.0.0',
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.contact_support,
                      color: Colors.black,
                      size: 25,
                    ),
                    title: Text(
                      'Contact Us',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'Contact Us',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContactItem(
                                  icon: Icons.email,
                                  title: 'Email',
                                  content: 'support@foodapp.com',
                                ),
                                const SizedBox(height: 15),
                                _buildContactItem(
                                  icon: Icons.phone,
                                  title: 'Phone',
                                  content: '+1 (555) 123-4567',
                                ),
                                const SizedBox(height: 15),
                                _buildContactItem(
                                  icon: Icons.location_on,
                                  title: 'Address',
                                  content: '123 Food Street, Cuisine City, FC 12345',
                                ),
                                const SizedBox(height: 15),
                                _buildContactItem(
                                  icon: Icons.access_time,
                                  title: 'Business Hours',
                                  content: 'Monday - Sunday: 9:00 AM - 10:00 PM',
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.exit_to_app,
                      color: Colors.black,
                      size: 25,
                    ),
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      firebaseAuth.signOut().then((value) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const LoginScreen(),
                          ),
                        );
                        _controller.clear();
                      });
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

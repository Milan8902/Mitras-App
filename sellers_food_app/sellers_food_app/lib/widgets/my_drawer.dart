import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sellers_food_app/authentication/login.dart';
import 'package:sellers_food_app/screens/history_screen.dart';
import 'package:sellers_food_app/screens/home_screen.dart';
import 'package:sellers_food_app/screens/new_orders_screen.dart';
import 'package:sellers_food_app/screens/chat_list_screen.dart';
import 'package:sellers_food_app/screens/profile_screen.dart';
import '../global/global.dart';
import 'dart:convert';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [Color(0xFFFFFFFF), Color(0xFFFAC898)],
          ),
        ),
        child: ListView(
          children: [
            // Header drawer
            Container(
              padding: const EdgeInsets.only(top: 25, bottom: 10),
              child: Column(
                children: [
                  Material(
                    borderRadius: const BorderRadius.all(Radius.circular(80)),
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
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundImage: sharedPreferences!.getString("photoUrl") != null &&
                                    sharedPreferences!.getString("photoUrl")!.isNotEmpty
                                ? (sharedPreferences!.getString("photoUrl")!.startsWith('http')
                                    ? NetworkImage(sharedPreferences!.getString("photoUrl")!)
                                    : MemoryImage(base64Decode(sharedPreferences!.getString("photoUrl")!)))
                                : const AssetImage('images/seller.png') as ImageProvider,
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading profile image: $exception');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sharedPreferences!.getString("name")!,
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Body drawer
            Container(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                children: [
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.home,
                      color: Colors.black,
                      size: 30,
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
                        MaterialPageRoute(builder: (c) => const HomeScreen()),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 30,
                    ),
                    title: Text(
                      'Profile',
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
                        MaterialPageRoute(builder: (c) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.reorder,
                      color: Colors.black,
                      size: 30,
                    ),
                    title: Text(
                      'New Orders',
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
                          builder: (c) => const NewOrdersScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.local_shipping,
                      color: Colors.black,
                      size: 30,
                    ),
                    title: Text(
                      'History - Orders',
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
                          builder: (c) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.message,
                      color: Colors.black,
                      size: 30,
                    ),
                    title: Text(
                      'Messages',
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
                          builder: (c) => const ChatListScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.info,
                      color: Colors.black,
                      size: 30,
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
                        builder: (context) => AlertDialog(
                          title: Text(
                            'About Foodie Sellers',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'Foodie Sellers is a platform that connects food sellers with customers. '
                            'We provide a seamless experience for managing your restaurant, '
                            'processing orders, and growing your business.',
                            style: GoogleFonts.lato(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.contact_support,
                      color: Colors.black,
                      size: 30,
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
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Contact Information',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email: support@foodiesellers.com',
                                style: GoogleFonts.lato(),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Phone: +1 234 567 8900',
                                style: GoogleFonts.lato(),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Address: 123 Food Street, Cuisine City',
                                style: GoogleFonts.lato(),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                  ListTile(
                    leading: const Icon(
                      Icons.exit_to_app,
                      color: Colors.black,
                      size: 30,
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
                      });
                    },
                  ),
                  const Divider(height: 10, color: Colors.white, thickness: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

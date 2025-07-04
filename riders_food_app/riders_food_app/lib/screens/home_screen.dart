import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riders_food_app/assistantMethods/get_current_location.dart';
import 'package:riders_food_app/authentication/login.dart';
import 'package:riders_food_app/screens/earnings_screen.dart';
import 'package:riders_food_app/screens/history_screen.dart';
import 'package:riders_food_app/screens/new_orders_screen.dart';
import 'package:riders_food_app/screens/not_yet_delivered_screen.dart';
import 'package:riders_food_app/screens/parcel_in_progress_screen.dart';
import '../global/global.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controllerAnim;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic>? riderData;

  @override
  void initState() {
    super.initState();
    _controllerAnim = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controllerAnim,
      curve: Curves.easeInOut,
    );
    _controllerAnim.forward();

    UserLocation uLocation = UserLocation();
    uLocation.getCurrenLocation();

    getPerParcelDeliveryAmount();
    getRiderPreviousEarnings();
    getRiderData();
  }

  @override
  void dispose() {
    _controllerAnim.dispose();
    super.dispose();
  }

  getRiderData() {
    String? riderId = sharedPreferences?.getString("uid");
    if (riderId != null) {
      FirebaseFirestore.instance
          .collection("riders")
          .doc(riderId)
          .get()
          .then((snap) {
        if (snap.exists && snap.data() != null) {
          setState(() {
            riderData = snap.data();
          });
        }
      });
    }
  }

  getRiderPreviousEarnings() {
    String? riderId = sharedPreferences?.getString("uid");
    if (riderId != null) {
      FirebaseFirestore.instance
          .collection("riders")
          .doc(riderId)
          .get()
          .then((snap) {
        if (snap.exists && snap.data() != null && snap.data()!.containsKey("earnings")) {
          previousRiderEarnings = snap.data()!["earnings"].toString();
          debugPrint("✅ Rider earnings loaded: $previousRiderEarnings");
        } else {
          previousRiderEarnings = "0";
          debugPrint("⚠️ Rider earnings field not found.");
        }
      }).catchError((e) {
        debugPrint("❌ Failed to load rider earnings: $e");
      });
    }
  }

  getPerParcelDeliveryAmount() {
    FirebaseFirestore.instance
        .collection("perDelivery")
        .doc("taydinadnan")
        .get()
        .then((snap) {
      if (snap.exists && snap.data() != null && snap.data()!.containsKey("amount")) {
        perParcelDeliveryAmount = snap.data()!["amount"].toString();
        debugPrint("✅ Per parcel amount: $perParcelDeliveryAmount");
      } else {
        perParcelDeliveryAmount = "0";
        debugPrint("⚠️ 'amount' field not found or document missing.");
      }
    }).catchError((e) {
      debugPrint("❌ Error loading delivery amount: $e");
    });
  }

  Widget makeDashboardItem(String title, IconData iconData, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewOrdersScreen()));
        } else if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ParcelInProgressScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotYetDeliveredScreen()));
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        } else if (index == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
        } else if (index == 5) {
          firebaseAuth.signOut().then((value) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          });
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: index == 0 || index == 3 || index == 4
                  ? [Colors.amber, Colors.orange]
                  : [Colors.orangeAccent, Colors.amber],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconData,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = sharedPreferences?.getString("name")?.toUpperCase() ?? "RIDER";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [Color(0xFFFFFFFF), Color(0xFFFAC898)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 220,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFAC898), Color(0xFFFFE0B2)],
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome $userName',
                            style: GoogleFonts.pacifico(
                              fontSize: 34,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your deliveries with ease!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Profile Section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: sharedPreferences?.getString("photoUrl") != null
                                        ? Image.memory(
                                            base64Decode(sharedPreferences!.getString("photoUrl")!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.person,
                                                  size: 30,
                                                  color: Colors.grey.shade400,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sharedPreferences?.getString("name") ?? "Rider",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sharedPreferences?.getString("email") ?? "No email",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Dashboard Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildListDelegate([
                  makeDashboardItem("New Available", Icons.assignment, 0),
                  makeDashboardItem("Parcels in Progress", Icons.airport_shuttle, 1),
                  makeDashboardItem("Not Yet Delivered", Icons.location_history, 2),
                  makeDashboardItem("History", Icons.done_all, 3),
                  makeDashboardItem("Total Earnings", Icons.monetization_on, 4),
                  makeDashboardItem("Logout", Icons.logout, 5),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
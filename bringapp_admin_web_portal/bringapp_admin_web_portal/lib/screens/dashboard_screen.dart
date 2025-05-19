import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/simple_app_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Statistics variables
  final Map<String, dynamic> _stats = {
    'users': 0,
    'riders': 0,
    'sellers': 0,
  };

  // Stream subscriptions
  final Map<String, StreamSubscription?> _subscriptions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupRealTimeListeners();
  }

  @override
  void dispose() {
    _subscriptions.values.forEach((subscription) => subscription?.cancel());
    super.dispose();
  }

  void _setupRealTimeListeners() {
    // Helper function to handle stream errors
    void handleStreamError(String collection, dynamic error) {
      print('Error in $collection stream: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error tracking $collection: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Listen to users, riders, and sellers counts
    ['users', 'riders', 'sellers'].forEach((collection) {
      _subscriptions[collection] = FirebaseFirestore.instance
          .collection(collection)
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            setState(() {
              _stats[collection] = snapshot.docs.length;
              _isLoading = false;
            });
          }
        },
        onError: (error) => handleStreamError(collection, error),
      );
    });
  }

  Widget buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      color: const Color(0xff1b232A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1b232A),
      appBar: SimpleAppBar(
        title: "Dashboard",
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 
                                 MediaQuery.of(context).size.width > 800 ? 3 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width > 800 ? 1.5 : 1.2,
                    children: [
                      buildStatCard("Total Users", _stats['users'], Icons.people, Colors.blue),
                      buildStatCard("Total Riders", _stats['riders'], Icons.delivery_dining, Colors.green),
                      buildStatCard("Total Sellers", _stats['sellers'], Icons.store, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
} 
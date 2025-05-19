import 'package:bringapp_admin_web_portal/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/simple_app_bar.dart';

class EnhancedRidersScreen extends StatefulWidget {
  const EnhancedRidersScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedRidersScreen> createState() => _EnhancedRidersScreenState();
}

class _EnhancedRidersScreenState extends State<EnhancedRidersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  bool _isLoading = false;
  QuerySnapshot? _ridersSnapshot;
  Map<String, List<Map<String, dynamic>>> _riderEarnings = {};
  Map<String, double> _riderRatings = {};
  Map<String, int> _riderDeliveries = {};

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRiders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection("riders");
      
      if (_statusFilter != 'all') {
        query = query.where("status", isEqualTo: _statusFilter);
      }

      final snapshot = await query.get();
      
      // Load earnings data for each rider
      for (var doc in snapshot.docs) {
        await _loadRiderEarnings(doc.id);
        await _loadRiderRatings(doc.id);
        await _loadRiderDeliveries(doc.id);
      }

      setState(() {
        _ridersSnapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading riders: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadRiderEarnings(String riderId) async {
    try {
      final earningsSnapshot = await FirebaseFirestore.instance
          .collection("earnings")
          .where("riderId", isEqualTo: riderId)
          .orderBy("timestamp", descending: true)
          .limit(30) // Last 30 days
          .get();

      List<Map<String, dynamic>> earnings = [];
      for (var doc in earningsSnapshot.docs) {
        final data = doc.data();
        earnings.add({
          'date': (data['timestamp'] as Timestamp).toDate(),
          'amount': data['amount'] ?? 0.0,
        });
      }

      setState(() {
        _riderEarnings[riderId] = earnings;
      });
    } catch (e) {
      print("Error loading earnings for rider $riderId: $e");
    }
  }

  Future<void> _loadRiderRatings(String riderId) async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection("ratings")
          .where("riderId", isEqualTo: riderId)
          .get();

      double totalRating = 0;
      int ratingCount = 0;

      for (var doc in ratingsSnapshot.docs) {
        final rating = doc.data()['rating'] ?? 0.0;
        totalRating += rating;
        ratingCount++;
      }

      setState(() {
        _riderRatings[riderId] = ratingCount > 0 ? totalRating / ratingCount : 0.0;
      });
    } catch (e) {
      print("Error loading ratings for rider $riderId: $e");
    }
  }

  Future<void> _loadRiderDeliveries(String riderId) async {
    try {
      final deliveriesSnapshot = await FirebaseFirestore.instance
          .collection("orders")
          .where("riderId", isEqualTo: riderId)
          .where("status", isEqualTo: "delivered")
          .get();

      setState(() {
        _riderDeliveries[riderId] = deliveriesSnapshot.docs.length;
      });
    } catch (e) {
      print("Error loading deliveries for rider $riderId: $e");
    }
  }

  List<QueryDocumentSnapshot> get _filteredRiders {
    if (_ridersSnapshot == null) return [];
    
    return _ridersSnapshot!.docs.where((doc) {
      final riderData = doc.data() as Map<String, dynamic>;
      final name = riderData['name']?.toString().toLowerCase() ?? '';
      final email = riderData['email']?.toString().toLowerCase() ?? '';
      final phone = riderData['phone']?.toString().toLowerCase() ?? '';
      
      return name.contains(_searchQuery.toLowerCase()) ||
             email.contains(_searchQuery.toLowerCase()) ||
             phone.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _updateRiderStatus(String riderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection("riders")
          .doc(riderId)
          .update({"status": status});
      
      await _loadRiders();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rider status updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating rider status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRider(String riderId) async {
    await FirebaseFirestore.instance.collection("riders").doc(riderId).delete();
    _loadRiders();
  }

  void _showRiderDetails(Map<String, dynamic> riderData, String riderId) {
    final earnings = _riderEarnings[riderId] ?? [];
    final rating = _riderRatings[riderId] ?? 0.0;
    final deliveries = _riderDeliveries[riderId] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Rider Details",
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow("Name", (riderData['riderName'] ?? riderData['name'] ?? 'N/A')),
              _buildDetailRow("Email", riderData['email'] ?? 'N/A'),
              _buildDetailRow("Phone", riderData['phone'] ?? 'N/A'),
              _buildDetailRow("Status", riderData['status'] ?? 'N/A'),
              _buildDetailRow("Rating", rating.toStringAsFixed(1)),
              _buildDetailRow("Total Deliveries", deliveries.toString()),
              _buildDetailRow("Joined Date", riderData['joinedAt'] != null 
                ? (riderData['joinedAt'] as Timestamp).toDate().toString()
                : 'N/A'),
              const SizedBox(height: 16),
              const Text(
                "Earnings History (Last 30 Days)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: earnings.isEmpty
                    ? const Center(child: Text("No earnings data available"))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '\$${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= earnings.length) return const Text('');
                                  final date = earnings[value.toInt()]['date'] as DateTime;
                                  return Text(
                                    DateFormat('MM/dd').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: earnings.asMap().entries.map((entry) {
                                return FlSpot(
                                  entry.key.toDouble(),
                                  entry.value['amount'] as double,
                                );
                              }).toList(),
                              isCurved: true,
                              color: Colors.amber,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.amber.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Rider'),
                  content: const Text('Are you sure you want to delete this rider?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                _deleteRider(riderData['id']);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1b232A),
      appBar: SimpleAppBar(
        title: "Enhanced Rider Management",
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search riders...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _statusFilter,
                  dropdownColor: const Color(0xff1b232A),
                  style: const TextStyle(color: Colors.white),
                  underline: Container(
                    height: 2,
                    color: Colors.amber,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Riders')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'not approved', child: Text('Not Approved')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statusFilter = value;
                      });
                      _loadRiders();
                    }
                  },
                ),
              ],
            ),
          ),

          // Riders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _filteredRiders.isEmpty
                    ? Center(
                        child: Text(
                          "No riders found",
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 24,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRiders.length,
                        itemBuilder: (context, index) {
                          final rider = _filteredRiders[index];
                          final riderData = rider.data() as Map<String, dynamic>;
                          final rating = _riderRatings[rider.id] ?? 0.0;
                          final deliveries = _riderDeliveries[rider.id] ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: const Color(0xff1b232A),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber,
                                child: Text(
                                  ((riderData['riderName'] ?? riderData['name'] ?? 'N').toString().substring(0, 1).toUpperCase()),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                (riderData['riderName'] ?? riderData['name'] ?? 'No Name'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    riderData['email'] ?? 'No Email',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      Text(
                                        " ${rating.toStringAsFixed(1)}",
                                        style: const TextStyle(color: Colors.amber),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.local_shipping,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      Text(
                                        " $deliveries deliveries",
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Status: ${riderData['status'] ?? 'Unknown'}",
                                    style: TextStyle(
                                      color: riderData['status'] == 'approved'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blue),
                                    onPressed: () => _showRiderDetails(riderData, rider.id),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      riderData['status'] == 'approved'
                                          ? Icons.block
                                          : Icons.check_circle,
                                      color: riderData['status'] == 'approved'
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    onPressed: () => _updateRiderStatus(
                                      rider.id,
                                      riderData['status'] == 'approved'
                                          ? 'not approved'
                                          : 'approved',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Rider'),
                                          content: const Text('Are you sure you want to delete this rider?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        _deleteRider(rider.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 
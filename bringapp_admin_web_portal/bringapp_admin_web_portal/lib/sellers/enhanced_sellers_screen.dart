import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/simple_app_bar.dart';

class EnhancedSellersScreen extends StatefulWidget {
  const EnhancedSellersScreen({super.key});

  @override
  State<EnhancedSellersScreen> createState() => _EnhancedSellersScreenState();
}

class _EnhancedSellersScreenState extends State<EnhancedSellersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'all';
  StreamSubscription? _statsSubscription;
  final _currencyFormat = NumberFormat.currency(symbol: '₱');

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }

  String _getSellerName(Map<String, dynamic> sellerData) {
    // Try different possible field names for the seller's name
    final possibleNameFields = [
      'name',
      'sellerName',
      'restaurantName',
      'shopName',
      'businessName',
      'storeName'
    ];

    for (var field in possibleNameFields) {
      if (sellerData[field] != null && sellerData[field].toString().isNotEmpty) {
        return sellerData[field].toString();
      }
    }

    // If no name field is found, return a default value
    return 'Unnamed Seller';
  }

  Future<void> _loadSellers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, get the total count of sellers
      final countSnapshot = await _firestore
          .collection('sellers')
          .count()
          .get();

      final totalSellers = countSnapshot.count ?? 0;
      print('Total sellers in database: $totalSellers'); // Debug log

      // Fetch all sellers
      final allSellersSnapshot = await _firestore.collection('sellers').get();
      print('Raw query returned ${allSellersSnapshot.docs.length} sellers'); // Debug log
      
      // Log each seller's data structure for debugging
      for (var doc in allSellersSnapshot.docs) {
        final data = doc.data();
        print('\nSeller ID: ${doc.id}');
        print('All available fields: ${data.keys.toList()}');
        print('Full seller data: $data');
      }

      if (!mounted) return;

      final sellers = allSellersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Ensure we have a display name
        if (!data.containsKey('name')) {
          data['name'] = _getSellerName(data);
        }
        return data;
      }).toList();

      print('\nTotal sellers processed: ${sellers.length}'); // Debug log

      setState(() {
        _sellers = List<Map<String, dynamic>>.from(sellers);
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _error = 'Timeout loading sellers. Please check your connection.';
        _isLoading = false;
      });
      print('Timeout loading sellers: $e');
    } catch (e) {
      setState(() {
        _error = 'Error loading sellers: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading sellers: $e');
    }
  }

  Future<void> _updateSellerStatus(String sellerId, String newStatus) async {
    try {
      await _firestore.collection('sellers').doc(sellerId).update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seller status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadSellers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating seller status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error updating seller status: $e');
    }
  }

  Future<void> _deleteSeller(String sellerId) async {
    try {
      await _firestore.collection('sellers').doc(sellerId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadSellers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting seller: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error deleting seller: $e');
    }
  }

  void _showSellerDetails(Map<String, dynamic> sellerData) {
    final sellerId = sellerData['id'] as String?;
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller ID missing, cannot show details.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getSellerName(sellerData)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${sellerData['email'] ?? 'N/A'}'),
              Text('Phone: ${sellerData['phone'] ?? 'N/A'}'),
              Text('Status: ${sellerData['status'] ?? 'N/A'}'),
              Text('Address: ${sellerData['address'] ?? 'N/A'}'),
              if (sellerData['businessName'] != null) 
                Text('Business Name: ${sellerData['businessName']}'),
              if (sellerData['restaurantName'] != null) 
                Text('Restaurant Name: ${sellerData['restaurantName']}'),
              if (sellerData['shopName'] != null) 
                Text('Shop Name: ${sellerData['shopName']}'),
              if (sellerData['storeName'] != null) 
                Text('Store Name: ${sellerData['storeName']}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => _updateSellerStatus(sellerId, 'active'),
                    child: const Text('Activate'),
                  ),
                  TextButton(
                    onPressed: () => _updateSellerStatus(sellerId, 'inactive'),
                    child: const Text('Deactivate'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete this seller? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _deleteSeller(sellerId);
                              },
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleAppBar(title: "Sellers"),
      body: Column(
        children: [
          // Search and filter controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search sellers...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statusFilter = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          // Sellers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _sellers.length,
                    itemBuilder: (context, index) {
                      final seller = _sellers[index];
                      final name = _getSellerName(seller);
                      final status = seller['status'] as String? ?? 'inactive';
                      
                      if (_statusFilter != 'all' && status != _statusFilter) {
                        return const SizedBox.shrink();
                      }
                      
                      if (_searchQuery.isNotEmpty &&
                          !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: status == 'active' ? Colors.green : Colors.red,
                            child: Text(name[0].toUpperCase()),
                          ),
                          title: Text(name),
                          subtitle: Text('Status: ${status.toUpperCase()}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => _showSellerDetails(seller),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // TODO: Implement edit functionality
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
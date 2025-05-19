import 'dart:async';
import 'package:bringapp_admin_web_portal/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/simple_app_bar.dart';

class EnhancedUsersScreen extends StatefulWidget {
  const EnhancedUsersScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedUsersScreen> createState() => _EnhancedUsersScreenState();
}

class _EnhancedUsersScreenState extends State<EnhancedUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  List<String> _selectedUsers = [];
  bool _isLoading = false;
  QuerySnapshot? _usersSnapshot;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (_isLoading) return;  // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection("users")
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data() ?? {},
            toFirestore: (data, _) => data,
          );
      
      if (_statusFilter != 'all') {
        query = query.where("status", isEqualTo: _statusFilter);
      }

      // Add error handling for the query
      final snapshot = await query.get().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Loading users timed out');
        },
      );

      if (mounted) {
        setState(() {
          _usersSnapshot = snapshot;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Loading users timed out. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading users: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<QueryDocumentSnapshot> get _filteredUsers {
    if (_usersSnapshot == null) return [];
    
    return _usersSnapshot!.docs.where((doc) {
      final userData = doc.data() as Map<String, dynamic>;
      final name = userData['name']?.toString().toLowerCase() ?? '';
      final email = userData['email']?.toString().toLowerCase() ?? '';
      final phone = userData['phone']?.toString().toLowerCase() ?? '';
      
      return name.contains(_searchQuery.toLowerCase()) ||
             email.contains(_searchQuery.toLowerCase()) ||
             phone.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({"status": status});
      
      await _loadUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User status updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating user status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkUpdateStatus(String status) async {
    if (_selectedUsers.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      int successCount = 0;
      List<String> failedUsers = [];

      for (String userId in _selectedUsers) {
        try {
          // Check if user has any active orders before updating status
          if (status == 'not approved') {
            final activeOrdersQuery = await FirebaseFirestore.instance
                .collection("orders")
                .where("userID", isEqualTo: userId)
                .where("orderStatus", whereIn: ['pending', 'processing', 'out_for_delivery', 'accepted'])
                .get();

            if (activeOrdersQuery.docs.isNotEmpty) {
              failedUsers.add(userId);
              continue;
            }
          }

          final docRef = FirebaseFirestore.instance.collection("users").doc(userId);
          batch.update(docRef, {"status": status});
          successCount++;
        } catch (e) {
          print('Error updating user $userId: $e');
          failedUsers.add(userId);
        }
      }

      await batch.commit();
      
      setState(() {
        _selectedUsers.clear();
        _isLoading = false;
      });

      await _loadUsers();

      if (mounted) {
        String message = "$successCount users updated successfully";
        if (failedUsers.isNotEmpty) {
          message += "\nFailed to update ${failedUsers.length} users";
          if (status == 'not approved') {
            message += " (some users have active orders)";
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failedUsers.isEmpty ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error in bulk update: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating users: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // Check if user has any active orders
      final activeOrdersQuery = await FirebaseFirestore.instance
          .collection("orders")
          .where("userID", isEqualTo: userId)
          .where("orderStatus", whereIn: ['pending', 'processing', 'out_for_delivery', 'accepted'])
          .get();

      if (activeOrdersQuery.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot delete user with active orders"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show confirmation dialog
      if (mounted) {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }

      // Delete user
      await FirebaseFirestore.instance.collection("users").doc(userId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUsers();
      }
    } catch (e) {
      print('Error deleting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting user: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "User Details",
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
              _buildDetailRow("Name", userData['name'] ?? 'N/A'),
              _buildDetailRow("Email", userData['email'] ?? 'N/A'),
              _buildDetailRow("Phone", userData['phone'] ?? 'N/A'),
              _buildDetailRow("Status", userData['status'] ?? 'N/A'),
              _buildDetailRow("Address", userData['address'] ?? 'N/A'),
              _buildDetailRow("Joined Date", userData['joinedAt'] != null 
                ? (userData['joinedAt'] as Timestamp).toDate().toString()
                : 'N/A'),
              _buildDetailRow("Last Login", userData['lastLogin'] != null
                ? (userData['lastLogin'] as Timestamp).toDate().toString()
                : 'N/A'),
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
                  title: const Text('Delete User'),
                  content: const Text('Are you sure you want to delete this user?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                _deleteUser(userData['id']);
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
            width: 100,
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
        title: "Enhanced User Management",
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
                      hintText: "Search users...",
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
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'not approved', child: Text('Not Approved')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statusFilter = value;
                      });
                      _loadUsers();
                    }
                  },
                ),
              ],
            ),
          ),

          // Bulk Actions
          if (_selectedUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${_selectedUsers.length} users selected",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _bulkUpdateStatus('approved'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Approve Selected"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _bulkUpdateStatus('not approved'),
                    icon: const Icon(Icons.block),
                    label: const Text("Block Selected"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedUsers.clear();
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.white),
                    tooltip: "Clear Selection",
                  ),
                ],
              ),
            ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          "No users found",
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 24,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final userData = user.data() as Map<String, dynamic>;
                          final isSelected = _selectedUsers.contains(user.id);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: const Color(0xff1b232A),
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedUsers.add(user.id);
                                    } else {
                                      _selectedUsers.remove(user.id);
                                    }
                                  });
                                },
                              ),
                              title: Text(
                                userData['name'] ?? 'No Name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['email'] ?? 'No Email',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    "Status: ${userData['status'] ?? 'Unknown'}",
                                    style: TextStyle(
                                      color: userData['status'] == 'approved'
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
                                    onPressed: () => _showUserDetails(userData),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      userData['status'] == 'approved'
                                          ? Icons.block
                                          : Icons.check_circle,
                                      color: userData['status'] == 'approved'
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    onPressed: () => _updateUserStatus(
                                      user.id,
                                      userData['status'] == 'approved'
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
                                          title: const Text('Delete User'),
                                          content: const Text('Are you sure you want to delete this user?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        _deleteUser(user.id);
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
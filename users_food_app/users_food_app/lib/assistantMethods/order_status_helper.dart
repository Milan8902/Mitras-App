import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:users_food_app/global/global.dart';

class OrderStatusHelper {
  // Update order status in both user's orders and main orders collection
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? riderUid,
  }) async {
    try {
      final userUid = sharedPreferences!.getString("uid");
      if (userUid == null) throw Exception("User not logged in");

      final batch = FirebaseFirestore.instance.batch();
      
      // Update in user's orders
      final userOrderRef = FirebaseFirestore.instance
          .collection("users")
          .doc(userUid)
          .collection("orders")
          .doc(orderId);
      
      // Update in main orders collection
      final mainOrderRef = FirebaseFirestore.instance
          .collection("orders")
          .doc(orderId);

      // Prepare update data
      final updateData = {
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add rider UID if provided (for delivery status updates)
      if (riderUid != null && status == 'delivering') {
        updateData['riderUID'] = riderUid;
      }

      // Add both updates to the batch
      batch.update(userOrderRef, updateData);
      batch.update(mainOrderRef, updateData);

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print("Error updating order status: $e");
      rethrow;
    }
  }

  // Get order status
  static Future<String> getOrderStatus(String orderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("orders")
          .doc(orderId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['status'] ?? 'unknown';
      }
      return 'not_found';
    } catch (e) {
      print("Error getting order status: $e");
      return 'error';
    }
  }

  // Get human-readable status
  static String getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return 'Order Placed';
      case 'picking':
        return 'Preparing';
      case 'delivering':
        return 'On the Way';
      case 'ended':
        return 'Delivered';
      case 'received':
        return 'Received';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }

  // Get status color
  static int getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'picking':
        return 0xFFFFA000; // Orange
      case 'delivering':
        return 0xFF2196F3; // Blue
      case 'ended':
        return 0xFF4CAF50; // Green
      case 'received':
        return 0xFF9C27B0; // Purple
      case 'cancelled':
        return 0xFFF44336; // Red
      default:
        return 0xFF607D8B; // Blue Grey
    }
  }

  // Get status icon
  static String getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'picking':
        return 'inventory_2';
      case 'delivering':
        return 'delivery_dining';
      case 'ended':
        return 'check_circle';
      case 'received':
        return 'verified_user';
      case 'cancelled':
        return 'cancel';
      default:
        return 'shopping_bag';
    }
  }
}

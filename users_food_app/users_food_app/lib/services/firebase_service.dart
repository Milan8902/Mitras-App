import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initializeFirebase() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initializeFirebase();
    }
  }

  Stream<QuerySnapshot> getSellerMessages(String restaurantId) {
    try {
      ensureInitialized();

      if (restaurantId == null || restaurantId.isEmpty) {
        throw Exception('Invalid restaurant ID');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated');
      }

      return _firestore
          .collection('user_chats')
          .doc(currentUser.uid)
          .collection('messages')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  Future<void> sendSellerMessage(String restaurantId, String message, {String? sellerId}) async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase is not initialized');
      }

      if (restaurantId == null || restaurantId.isEmpty) {
        throw Exception('Invalid restaurant ID');
      }

      if (message.trim().isEmpty) return;

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated');
      }

      final messageData = {
        'senderId': currentUser.uid,
        'restaurantId': restaurantId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': currentUser.displayName ?? 'User',
        'senderType': 'user',
        'isRead': false,
      };

      // Add message to seller's chat collection
      await _firestore
          .collection('seller_chats')
          .doc(restaurantId)
          .collection('messages')
          .add(messageData);

      // Add message to user's chat collection
      await _firestore
          .collection('user_chats')
          .doc(currentUser.uid)
          .collection('messages')
          .add(messageData);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}

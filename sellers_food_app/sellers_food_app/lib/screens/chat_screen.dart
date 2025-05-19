import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sellers_food_app/global/global.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'user_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhoto;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.userPhoto,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection("seller_chats")
          .doc(sharedPreferences!.getString("uid"))
          .collection("messages")
          .where("senderId", isEqualTo: widget.userId)
          .where("isRead", isEqualTo: false)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({"isRead": true});
        }
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String message = messageController.text.trim();
    messageController.clear();

    String restaurantId = sharedPreferences!.getString("uid")!;
    String restaurantName = sharedPreferences!.getString("name")!;

    try {
      final messageData = {
        'senderId': restaurantId,
        'restaurantId': restaurantId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': restaurantName,
        'senderType': 'restaurant',
        'isRead': false,
      };

      // Add message to seller's chat collection
      await FirebaseFirestore.instance
          .collection("seller_chats")
          .doc(restaurantId)
          .collection("messages")
          .add(messageData);

      // Add message to user's chat collection
      await FirebaseFirestore.instance
          .collection("user_chats")
          .doc(widget.userId)
          .collection("messages")
          .add(messageData);

      // Add message to shared chat collection for real-time sync with user app
      String chatId = '${widget.userId}_$restaurantId';
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Scroll to bottom
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error sending message: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan,
                Colors.amber,
              ],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        title: Row(
          children: [
            if (widget.userPhoto != null && widget.userPhoto!.isNotEmpty)
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.userPhoto!.startsWith('http')
                    ? NetworkImage(widget.userPhoto!)
                    : (() {
                        final decoded = _decodeBase64Image(widget.userPhoto);
                        if (decoded != null) {
                          return MemoryImage(decoded);
                        } else {
                          return const AssetImage('images/user.png');
                        }
                      })() as ImageProvider,
              ),
            if (widget.userPhoto != null && widget.userPhoto!.isNotEmpty)
              const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => UserDetailScreen(userId: widget.userId),
                  ),
                );
              },
              child: Text(
                widget.userName,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc('${widget.userId}_${sharedPreferences!.getString("uid")}')
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error in chat stream: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet",
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    try {
                      var messageData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      var content = messageData["message"]?.toString() ?? "";
                      var timestamp = messageData["timestamp"] as Timestamp?;
                      var senderType = messageData["senderType"]?.toString() ?? "user";
                      var isCurrentUser = senderType == "restaurant";

                      return Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.amber : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                content,
                                style: TextStyle(
                                  color: isCurrentUser ? Colors.white : Colors.black,
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  _formatTime(timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isCurrentUser ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    } catch (e) {
                      print('Error building message: $e');
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    var now = DateTime.now();
    var messageTime = timestamp.toDate();
    var difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
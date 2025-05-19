import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sellers_food_app/global/global.dart';
import 'package:sellers_food_app/screens/chat_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String sellerId = sharedPreferences!.getString("uid")!;

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
        title: Text(
          'Messages',
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.amber,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("seller_chats")
              .doc(sellerId)
              .collection("messages")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No messages yet",
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group messages by sender
            Map<String, Map<String, dynamic>> chatGroups = {};
            for (var doc in snapshot.data!.docs) {
              try {
                var data = doc.data() as Map<String, dynamic>;

                var senderId = data['senderId'] as String?;
                var senderType = data['senderType'] as String?;
                
                if (senderId == null || senderType == null) {
                  continue;
                }
                
                if (senderType == 'restaurant') {
                  continue;
                }
                
                if (!chatGroups.containsKey(senderId)) {
                  chatGroups[senderId] = {
                    'lastMessage': data['message'] ?? '',
                    'lastMessageTime': data['timestamp'],
                    'senderName': data['senderName'] ?? 'User',
                    'unreadCount': data['isRead'] == false ? 1 : 0,
                  };
                } else {
                  if (data['isRead'] == false) {
                    chatGroups[senderId]!['unreadCount'] = (chatGroups[senderId]!['unreadCount'] as int) + 1;
                  }
                }
              } catch (e) {
                continue;
              }
            }

            if (chatGroups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No messages yet",
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: chatGroups.length,
              itemBuilder: (context, index) {
                var senderId = chatGroups.keys.elementAt(index);
                var chatData = chatGroups[senderId]!;
                var lastMessage = chatData['lastMessage'] as String? ?? '';
                var lastMessageTime = chatData['lastMessageTime'] as Timestamp?;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return ListTile(
                        leading: CircleAvatar(radius: 24, backgroundColor: Colors.grey[300]),
                        title: Text('Loading...', style: GoogleFonts.poppins()),
                      );
                    }
                    final userData = userSnapshot.data!.data();
                    if (userData == null) {
                      return Dismissible(
                        key: Key('unknown_$senderId'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Chat'),
                              content: const Text('Are you sure you want to delete this chat?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          final sellerId = sharedPreferences!.getString("uid")!;
                          final messages = await FirebaseFirestore.instance
                              .collection("seller_chats")
                              .doc(sellerId)
                              .collection("messages")
                              .where("senderId", isEqualTo: senderId)
                              .get();
                          for (var doc in messages.docs) {
                            await doc.reference.delete();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chat deleted')),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(radius: 24, backgroundColor: Colors.grey[300]),
                          title: Text('Unknown User', style: GoogleFonts.poppins()),
                          subtitle: Text(
                            lastMessage,
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            ),
                          trailing: Text(
                            lastMessageTime != null ? _formatTime(lastMessageTime) : '',
                            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                          ),
                        ),
                      );
                    }
                    final userMap = userData as Map<String, dynamic>;
                    final userName = userMap['name'] ?? 'User';
                    final userPhoto = userMap['photoUrl'];
                    ImageProvider avatarProvider;
                    if (userPhoto != null && userPhoto is String && userPhoto.isNotEmpty) {
                      if (userPhoto.startsWith('http')) {
                        avatarProvider = NetworkImage(userPhoto);
                      } else {
                        final decoded = _decodeBase64Image(userPhoto);
                        if (decoded != null) {
                          avatarProvider = MemoryImage(decoded);
                        } else {
                          avatarProvider = const AssetImage('images/user.png');
                        }
                      }
                    } else {
                      avatarProvider = const AssetImage('images/user.png');
                    }

                    return Dismissible(
                      key: Key(senderId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Chat'),
                            content: const Text('Are you sure you want to delete this chat?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                            ],
                              ),
                        );
                      },
                      onDismissed: (direction) async {
                        // Delete all messages for this chat
                        final sellerId = sharedPreferences!.getString("uid")!;
                        final messages = await FirebaseFirestore.instance
                            .collection("seller_chats")
                            .doc(sellerId)
                            .collection("messages")
                            .where("senderId", isEqualTo: senderId)
                            .get();
                        for (var doc in messages.docs) {
                          await doc.reference.delete();
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chat deleted')),
                          );
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: avatarProvider,
                        ),
                        title: Text(
                          userName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Text(
                          lastMessage,
                          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                          Text(
                              lastMessageTime != null ? _formatTime(lastMessageTime) : '',
                              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                          ),
                            if ((chatData['unreadCount'] ?? 0) > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                                  chatData['unreadCount'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ChatScreen(
                            userId: senderId,
                            userName: userName,
                                userPhoto: userPhoto,
                          ),
                        ),
                      );
                    },
                  ),
                    );
                  },
                );
              },
            );
          },
        ),
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
} 
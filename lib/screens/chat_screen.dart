import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarthomedevices_app/widgets/chat_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  // 1. This is the "chat room ID". It's the user's ID.
  final String chatRoomId;
  // 2. This is for the AppBar title (Admin will pass the user's email)
  final String? userName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 3. Get Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 4. Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Part C, Step 2: "Mark as Read" Logic
  @override
  void initState() {
    super.initState();
    // Run this function once when the screen loads
    _markMessagesAsRead();
  }

  // Use dispose to clean up controllers
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Determine which unread counter to reset based on who I am.
    // If my UID matches the chatRoomId (I am the USER):
    if (currentUser.uid == widget.chatRoomId) {
      await _firestore.collection('chats').doc(widget.chatRoomId).set({
        'unreadByUserCount': 0, // Reset the user's count
      }, SetOptions(merge: true));
    }
    // If my UID does *not* match (I am the ADMIN):
    else {
      await _firestore.collection('chats').doc(widget.chatRoomId).set({
        'unreadByAdminCount': 0, // Reset the admin's count
      }, SetOptions(merge: true));
    }
  }

  // Part C, Step 3: "_sendMessage" Logic
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String messageText = _messageController.text.trim();
    // Clear the field immediately for a snappy feel
    _messageController.clear();

    final timestamp = FieldValue.serverTimestamp();

    try {
      // --- TASK 1: Save the message to the subcollection ---
      await _firestore
          .collection('chats')
          .doc(widget.chatRoomId) // The chat room is always the User's UID
          .collection('messages')
          .add({
        'text': messageText,
        'createdAt': timestamp,
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
      });

      // --- TASK 2: Update the Parent Doc & Increment Unread Counts ---
      Map<String, dynamic> parentDocData = {
        'lastMessage': messageText,
        'lastMessageAt': timestamp,
      };

      // If I am the USER sending:
      if (currentUser.uid == widget.chatRoomId) {
        parentDocData['userEmail'] = currentUser.email;
        // Increment the ADMIN's unread count
        parentDocData['unreadByAdminCount'] = FieldValue.increment(1);
      }
      // If I am the ADMIN sending:
      else {
        // Increment the USER's unread count
        parentDocData['unreadByUserCount'] = FieldValue.increment(1);
      }

      // Use .set(merge: true) to create the document if needed or update existing fields
      await _firestore
          .collection('chats')
          .doc(widget.chatRoomId)
          .set(parentDocData, SetOptions(merge: true));

      // --- TASK 3: Scroll to bottom ---
      // We wrap this in a check to ensure we only try to scroll if the scroll controller has something to scroll to
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Part C, Step 4: The build Method (UI)
  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        // Show "Chat with [User Email]" for admin, or "Contact Admin" for user
        title: Text(widget.userName ?? 'Contact Admin'),
      ),
      body: Column(
        children: [
          // --- The Message List (Expanded to fill space) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Query the 'messages' subcollection for this chat room
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false) // Oldest first
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hello!'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;

                    // Use the ChatBubble widget
                    return ChatBubble(
                      message: messageData['text'] ?? '',
                      // Check if the message sender is the current logged-in user
                      isCurrentUser: messageData['senderId'] == currentUser!.uid,
                    );
                  },
                );
              },
            ),
          ),

          // --- The Text Input Field ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// lib/screens/admin_chat_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// Note: Changed import path based on common structure
import 'package:smarthomedevices_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active User Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Query all 'chats', sorted by last message time (newest first)
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active chats.'));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              final String userId = chatDoc.id; // The document ID is the User's UID
              // Display the user's email, or their ID if the email field is missing
              final String userEmail = chatData['userEmail'] ?? 'User ID: $userId';
              final String lastMessage = chatData['lastMessage'] ?? 'Start a conversation...';

              // 2. --- Get the Admin's unread count ---
              final int unreadCount = chatData['unreadByAdminCount'] as int? ?? 0;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(userEmail,
                    style: TextStyle(
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal
                    )
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 3. --- Show a Badge on the trailing icon if there are unread messages ---
                trailing: unreadCount > 0
                    ? Badge(
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.arrow_forward_ios, size: 16),
                  backgroundColor: Colors.red,
                )
                    : const Icon(Icons.arrow_forward_ios, size: 16),

                onTap: () {
                  // Navigate to the ChatScreen, passing the user's ID and Email
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatRoomId: userId,
                        userName: userEmail,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
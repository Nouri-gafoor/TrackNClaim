import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class CommunicationListPage extends StatelessWidget {
  const CommunicationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("matches")
            .where("status", isEqualTo: "accepted")
            .where(Filter.or(
          Filter("lostUserId", isEqualTo: user?.uid),
          Filter("finderUserId", isEqualTo: user?.uid),
        ))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active conversations"));
          }

          final matches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final data = match.data() as Map<String, dynamic>;

              final lostUserId = data["lostUserId"] as String?;
              final finderUserId = data["finderUserId"] as String?;

              if (lostUserId == null || finderUserId == null) {
                return const SizedBox.shrink(); // skip invalid docs
              }

              // figure out who the "other user" is
              final isLost = lostUserId == user?.uid;
              final otherUserId = isLost ? finderUserId : lostUserId;

              // ✅ generate a consistent chatId
              final chatId = match.id;

              return ListTile(
                leading: const Icon(Icons.chat, color: Colors.blue),
                title: Text("Chat about ${data['category']}"),
                subtitle: Text("📍 ${data['location']}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(// 👈 same as before
                        chatId: match.id,   // 👈 Firestore doc ID of the match
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

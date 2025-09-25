import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import your QR pages
import 'package:tracknclaim/presentation/pages/lost_found/QrGenerate_page.dart';
import 'package:tracknclaim/presentation/pages/lost_found/QrScan_page.dart';

class ChatPage extends StatefulWidget {
  final String chatId; // same as matchDocId

  const ChatPage({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}


class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _ensureChatExists() async {
    final chatRef =
    FirebaseFirestore.instance.collection("chats").doc(widget.chatId);

    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        "participants": widget.chatId.split("_"),
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  /// 🔹 Normal message or system MATCH_FOUND
  Future<void> _sendMessage({bool isMatchFound = false}) async {
    await _ensureChatExists();

    if (isMatchFound) {
      // 🔹 Fetch lostUserId & finderUserId from matches collection
      final matchDoc = await FirebaseFirestore.instance
          .collection("matches")
          .doc(widget.chatId)
          .get();

      final matchData = matchDoc.data() as Map<String, dynamic>?;

      if (matchData != null) {
        final lostUserId = matchData["lostUserId"];
        final finderUserId = matchData["finderUserId"];

        await FirebaseFirestore.instance
            .collection("chats")
            .doc(widget.chatId) // ✅ always use chatId for messages
            .collection("messages")
            .add({
          "senderId": "system",
          "text": "MATCH_FOUND",
          "lostUserId": lostUserId,
          "finderUserId": finderUserId,
          "timestamp": FieldValue.serverTimestamp(),
        });
      }
    } else {
      final text = _messageController.text.trim();
      if (text.isEmpty) return;

      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId) // ✅ fixed
          .collection("messages")
          .add({
        "senderId": user?.uid,
        "text": text,
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          // 🔹 Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(widget.chatId) // ✅ fixed
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                    messages[index].data() as Map<String, dynamic>;
                    final isMe = data["senderId"] == user?.uid;

                    if (data["text"] == "MATCH_FOUND") {
                      return _buildMatchFoundWidget(data);
                    }

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data["text"] ?? "",
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Message input + MATCH_FOUND button
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(),
                ),
                IconButton(
                  icon: const Icon(Icons.verified, color: Colors.green),
                  tooltip: "Confirm Match",
                  onPressed: () => _sendMessage(isMatchFound: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Build the special "Match Found" message with QR buttons
  Widget _buildMatchFoundWidget(Map<String, dynamic> data) {
    final lostUserId = data["lostUserId"];
    final finderUserId = data["finderUserId"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("🎉 A match has been confirmed!"),
        const SizedBox(height: 8),

        if (user?.uid == lostUserId) // Lost side
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: const Text("Show QR"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrGeneratePage(
                    chatId: widget.chatId, // match docId goes into QR
                    lostUserId: lostUserId,
                    finderUserId: finderUserId,
                  ),
                ),
              );
            },
          ),

        if (user?.uid == finderUserId) // Finder side
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Scan QR"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QrScanPage(),
                ),
              );
            },
          ),
      ],
    );
  }
}

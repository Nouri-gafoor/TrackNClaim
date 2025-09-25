import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../lost_found/lost_page.dart';
import '../lost_found/found_page.dart';

class ReporterDashboardPage extends StatelessWidget {
  final String? userRole;

  const ReporterDashboardPage({Key? key, this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lost'),
              Tab(text: 'Found'),
              Tab(text: 'Matches'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 🔹 Lost tab
            Column(
              children: [
                Expanded(child: _buildReportsList('lost_reports', user.uid)),
                _buildReportButton(
                  context,
                  "Report Lost Item",
                  const LostPage(),
                ),
              ],
            ),

            // 🔹 Found tab
            Column(
              children: [
                Expanded(child: _buildReportsList('finder_reports', user.uid)),
                _buildReportButton(
                  context,
                  "Report Found Item",
                  const FoundPage(),
                ),
              ],
            ),

            // 🔹 Matches tab
            _buildMatchesList(user.uid),
          ],
        ),
      ),
    );
  }

  /// 🔹 Build report list
  Widget _buildReportsList(String collection, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where("uid", isEqualTo: uid)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No reports yet."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: Text(data['category'] ?? "Unknown"),
                subtitle: Text(
                  "${data['description'] ?? ''}\n"
                      "📅 ${data['date'] ?? ''}\n"
                      "📍 ${data['location'] ?? ''}",
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  /// 🔹 Matches (notifications) – FIXED: use two queries and merge
  Widget _buildMatchesList(String uid) {
    final lostMatchesStream = FirebaseFirestore.instance
        .collection("matches")
        .where("lostUserId", isEqualTo: uid)
        .snapshots();

    final finderMatchesStream = FirebaseFirestore.instance
        .collection("matches")
        .where("finderUserId", isEqualTo: uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: lostMatchesStream,
      builder: (context, lostSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: finderMatchesStream,
          builder: (context, finderSnapshot) {
            if (lostSnapshot.hasError || finderSnapshot.hasError) {
              return Center(child: Text("Error loading matches"));
            }

            if (!lostSnapshot.hasData || !finderSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allMatches = [
              ...lostSnapshot.data!.docs,
              ...finderSnapshot.data!.docs,
            ];

            if (allMatches.isEmpty) {
              return const Center(child: Text("No matches yet."));
            }

            return ListView.builder(
              itemCount: allMatches.length,
              itemBuilder: (context, index) {
                final doc = allMatches[index];
                final data = doc.data() as Map<String, dynamic>;

                final isLostUser = data["lostUserId"] == uid;
                final isFinderUser = data["finderUserId"] == uid;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📌 Category: ${data['category'] ?? ''}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("📍 Location: ${data['location'] ?? ''}"),
                        const SizedBox(height: 8),

                        // 🔹 Lost User: Provide Identification Mark
                        if (isLostUser)
                          if (data["identificationMark"] == null)
                            ElevatedButton(
                              onPressed: () async {
                                final controller = TextEditingController();
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Provide Identification Mark"),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        hintText: "e.g., Red ribbon inside the bag",
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (controller.text.trim().isNotEmpty) {
                                            await FirebaseFirestore.instance
                                                .collection("matches")
                                                .doc(doc.id)
                                                .update({
                                              "identificationMark": controller.text.trim(),
                                              "status": "waiting_finder",
                                            });
                                          }
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text("Submit"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text("Provide Identification Mark"),
                            )
                          else
                            Text("📝 Identification Mark: ${data['identificationMark']}"),

                        // 🔹 Finder User: Accept / Reject buttons
                        if (isFinderUser && data["identificationMark"] != null)
                          if (data["finderDecision"] == null)
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection("matches")
                                        .doc(doc.id)
                                        .update({
                                      "finderDecision": "accepted",
                                      "status": "accepted",
                                    });
                                  },
                                  child: const Text("Accept"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection("matches")
                                        .doc(doc.id)
                                        .update({
                                      "finderDecision": "rejected",
                                      "status": "rejected",
                                    });
                                  },
                                  child: const Text("Reject"),
                                ),
                              ],
                            )
                          else
                            Text("✅ You ${data["finderDecision"]} this match"),

                        // 🔹 Lost User sees Finder’s decision
                        if (isLostUser && data["finderDecision"] != null)
                          Text("📢 Finder has ${data["finderDecision"]} your mark."),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🔹 Helper: Report button
  Widget _buildReportButton(BuildContext context, String label, Widget page) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(label),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
        ),
      ),
    );
  }
}

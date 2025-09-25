import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LostPage extends StatefulWidget {
  const LostPage({super.key});

  @override
  State<LostPage> createState() => _LostPageState();
}

class _LostPageState extends State<LostPage> {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _location;

  final List<String> _collegeSpots = [
    "Library",
    "Cafeteria",
    "Auditorium",
    "Lab Block",
    "Main Gate",
    "Parking Area",
    "Sports Ground",
  ];

  bool _isLoading = false;

  Future<void> _submitLostReport() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        setState(() => _isLoading = true);
        final user = FirebaseAuth.instance.currentUser;

        // Save lost report
        final docRef =
        await FirebaseFirestore.instance.collection("lost_reports").add({
          "uid": user?.uid,
          "category": _category,
          "description": _descriptionController.text.trim(),
          "date": Timestamp.fromDate(_selectedDate!),
          "location": _location,
          "createdAt": FieldValue.serverTimestamp(),
        });

        // Try to match with finder reports
        final finderReports = await FirebaseFirestore.instance
            .collection("finder_reports")
            .where("category", isEqualTo: _category)
            .where("location", isEqualTo: _location)
            .get();

        for (var report in finderReports.docs) {
          final data = report.data();
          final foundDate = (data["date"] as Timestamp?)?.toDate();

          if (foundDate != null &&
              (_selectedDate!.difference(foundDate)).inDays.abs() <= 2) {
            // Create match with embedded summaries
            await FirebaseFirestore.instance.collection("matches").add({
              "lostReportId": docRef.id,
              "finderReportId": report.id,
              "lostUserId": user?.uid,
              "finderUserId": data["uid"],
              "category": _category,
              "location": _location,
              "lostReport": {
                "id": docRef.id,
                "description": _descriptionController.text.trim(),
                "date": _selectedDate!.toIso8601String(),
                "location": _location,
                "uid": user?.uid,
              },
              "foundReport": {
                "id": report.id,
                "description": data["description"],
                "date": data["date"]?.toString(),
                "location": data["location"],
                "uid": data["uid"],
              },
              "createdAt": FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ A possible match was found!")),
            );
          }
        }

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lost item reported successfully!")),
        );

        Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Lost Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: "Category"),
                items: ["Bag", "Book", "ID Card", "Electronics", "Other"]
                    .map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val),
                validator: (val) => val == null ? "Select category" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (val) =>
                val == null || val.isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? "Choose Date"
                    : _selectedDate!.toLocal().toString().split(" ")[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _location,
                decoration: const InputDecoration(labelText: "Location"),
                items: _collegeSpots
                    .map((spot) =>
                    DropdownMenuItem(value: spot, child: Text(spot)))
                    .toList(),
                onChanged: (val) => setState(() => _location = val),
                validator: (val) => val == null ? "Select location" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitLostReport,
                child: _isLoading
                    ? const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)
                    : const Text("Submit Lost Report"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

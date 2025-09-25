import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tracknclaim/presentation/pages/lost_found/successpage.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _scanned = false;

  Future<void> _handleScan(String qrValue) async {
    if (_scanned) return;
    _scanned = true;

    final parts = qrValue.split("|");
    if (parts.length == 3) {
      final matchId = parts[0];
      final lostUserId = parts[1];
      final finderUserId = parts[2];
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      if (currentUserId != finderUserId) {
        // ❌ Wrong person scanning
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Only the Finder can scan this QR ❌")),
        );
        return;
      }

      try {
        // ✅ update match status
        await FirebaseFirestore.instance
            .collection("matches")
            .doc(matchId)
            .update({
          "status": "returned",
          "returnedAt": FieldValue.serverTimestamp(),
          "returnedBy": currentUserId,
        });

        // ✅ add chat confirmation
        await FirebaseFirestore.instance
            .collection("chats")
            .doc(matchId)
            .collection("messages")
            .add({
          "senderId": currentUserId,
          "text": "✅ Item returned successfully",
          "timestamp": FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SuccessPage(
                message: "Item returned successfully ✅",
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR Code ❌")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final qrValue = barcodes.first.rawValue ?? "";
            _handleScan(qrValue);
          }
        },
      ),
    );
  }
}

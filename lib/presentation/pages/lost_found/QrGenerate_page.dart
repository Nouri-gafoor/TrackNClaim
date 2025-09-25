import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrGeneratePage extends StatelessWidget {
  final String chatId;
  final String lostUserId;
  final String finderUserId;

  const QrGeneratePage({
    Key? key,
    required this.chatId,
    required this.lostUserId,
    required this.finderUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build QR data string: chatId|lostUserId|finderUserId
    final qrData = "$chatId|$lostUserId|$finderUserId";

    return Scaffold(
      appBar: AppBar(title: const Text("Show QR to Finder")),
      body: Center(
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 250,
        ),
      ),
    );
  }
}

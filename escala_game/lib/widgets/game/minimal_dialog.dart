import 'package:flutter/material.dart';

class MinimalDialog extends StatelessWidget {
  final String title;
  final String message;

  const MinimalDialog({
    Key? key,
    required this.title,
    required this.message,
  }) : super(key: key);

  static void show(BuildContext context,
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => MinimalDialog(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
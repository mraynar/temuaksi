import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

Future<void> handleLogout(BuildContext context) async {
  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleUser = user?.providerData
        .any((p) => p.providerId == 'google.com') ?? false;

    if (isGoogleUser) {
      try {
        await gsi.GoogleSignIn.instance.signOut()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // ignore, lanjut Firebase signOut
      }
    }

    await FirebaseAuth.instance.signOut();

  } catch (e) {
    debugPrint('Error logout: $e');
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}
  } finally {
    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}

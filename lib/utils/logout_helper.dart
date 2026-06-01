import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as real_gsi;

class GoogleSignIn {
  static final GoogleSignIn instance = GoogleSignIn();
  
  final _real = real_gsi.GoogleSignIn.instance;
  
  Future<bool> isSignedIn() async {
    return true;
  }
  
  Future<void> disconnect() async {
    try {
      await _real.disconnect();
    } catch (_) {}
  }
  
  Future<void> signOut() async {
    try {
      await _real.signOut();
    } catch (_) {}
  }
}

Future<void> handleLogout(BuildContext context) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint("Error Google SignOut: $e");
    }
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  } catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    debugPrint("Error logout: $e");
  }
}

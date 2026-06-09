import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Login dengan email & password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError('Email dan kata sandi tidak boleh kosong');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          _setError('Email atau kata sandi salah');
          break;
        case 'wrong-password':
          _setError('Kata sandi salah');
          break;
        case 'invalid-email':
          _setError('Format email tidak valid');
          break;
        default:
          _setError(e.message ?? 'Terjadi kesalahan');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Terjadi kesalahan sistem: $e');
      return false;
    }
  }

  /// Login dengan Google
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      final gsi.GoogleSignInAccount? googleUser =
          await gsi.GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final gsi.GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      final gsi.GoogleSignInClientAuthorization clientAuth =
          await googleUser.authorizationClient.authorizeScopes([]);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          await docRef.set({
            'uid': user.uid,
            'name': user.displayName ?? 'Pengguna Google',
            'nama_lengkap': user.displayName ?? 'Pengguna Google',
            'email': user.email ?? '',
            'nomor_telepon': user.phoneNumber ?? '',
            'role': 'Individu',
            'photo_url': user.photoURL ?? '',
            'points': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(e.message ?? 'Gagal autentikasi Google');
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Terjadi kesalahan sistem: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}

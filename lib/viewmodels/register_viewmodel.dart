import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  /// Daftar sebagai individu
  Future<bool> registerIndividu({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool agreeToTerms,
  }) async {
    if (password != confirmPassword) {
      _setError('Kata sandi tidak cocok!');
      return false;
    }
    if (!agreeToTerms) {
      _setError('Harap setujui Syarat & Ketentuan');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'nama_lengkap': name.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'nomor_telepon': phone.trim(),
        'role': 'individu',
        'photo_url': '',
        'points': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      await userCredential.user?.updateDisplayName(name.trim());

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'weak-password':
          _setError('Kata sandi terlalu lemah.');
          break;
        case 'email-already-in-use':
          _setError('Email sudah terdaftar.');
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

  /// Daftar sebagai perusahaan
  Future<bool> registerPerusahaan({
    required String nama,
    required String deskripsi,
    required String bidang,
    required String lokasi,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool agreeToTerms,
  }) async {
    if (password != confirmPassword) {
      _setError('Kata sandi tidak cocok!');
      return false;
    }
    if (nama.isEmpty || lokasi.isEmpty || email.isEmpty) {
      _setError('Nama, Lokasi, dan Email wajib diisi!');
      return false;
    }
    if (!agreeToTerms) {
      _setError('Harap setujui Syarat & Ketentuan');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'nama_lengkap': nama.trim(),
        'name': nama.trim(),
        'deskripsi_perusahaan': deskripsi.trim(),
        'bidang_industri': bidang.trim(),
        'alamat': lokasi.trim(),
        'email': email.trim(),
        'nomor_telepon': phone.trim(),
        'role': 'perusahaan',
        'photo_url': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'email-already-in-use':
          _setError('Email sudah terdaftar');
          break;
        case 'weak-password':
          _setError('Kata sandi terlalu lemah');
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
}

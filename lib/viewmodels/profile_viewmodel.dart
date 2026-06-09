import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _cloudName = "dm4ua5rj6";
  final String _uploadPreset = "temu_aksi_preset";

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get currentUid => _auth.currentUser?.uid ?? '';
  String get currentEmail => _auth.currentUser?.email ?? '';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String? msg) {
    _successMessage = msg;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Stream of user profile document for real-time updates
  Stream<DocumentSnapshot> streamUserProfile() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Load user data once (for edit form pre-fill)
  Future<Map<String, dynamic>> loadUserData() async {
    final uid = currentUid;
    if (uid.isEmpty) return {};
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? (doc.data() as Map<String, dynamic>) : {};
    } catch (_) {
      return {};
    }
  }

  /// Upload profile photo to Cloudinary
  Future<String?> uploadProfilePhoto(File file) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
    var request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonRes = jsonDecode(responseString);
        return jsonRes['secure_url'];
      }
    } catch (e) {
      debugPrint("Cloudinary Error: $e");
    }
    return null;
  }

  /// Update profile (name, phone, photo, dob)
  Future<bool> updateProfile({
    required String namaLengkap,
    required String nomorTelepon,
    required String currentPhotoUrl,
    File? newImageFile,
    DateTime? tanggalLahir,
  }) async {
    if (namaLengkap.isEmpty || nomorTelepon.isEmpty) {
      _setError("Nama dan Nomor Telepon tidak boleh kosong");
      return false;
    }

    _setLoading(true);

    try {
      String photoUrl = currentPhotoUrl;

      if (newImageFile != null) {
        final newUrl = await uploadProfilePhoto(newImageFile);
        if (newUrl == null) {
          _setError("Gagal mengunggah foto ke server");
          _setLoading(false);
          return false;
        }
        photoUrl = newUrl;
      }

      await _firestore.collection('users').doc(currentUid).update({
        'nama_lengkap': namaLengkap,
        'nomor_telepon': nomorTelepon,
        'photo_url': photoUrl,
        'tanggal_lahir': tanggalLahir != null
            ? Timestamp.fromDate(tanggalLahir)
            : null,
      });

      _setSuccess("Profil berhasil diperbarui!");
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal memperbarui profil: $e");
      _setLoading(false);
      return false;
    }
  }

  /// Submit complaint to Firestore
  Future<bool> submitComplaint({
    required String name,
    required String email,
    required String title,
    required String description,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      _setError("Silakan login terlebih dahulu");
      return false;
    }
    _setLoading(true);
    try {
      await _firestore.collection('complaints').add({
        'uid': uid,
        'user_name': name,
        'user_email': email,
        'title': title,
        'description': description,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
      _setSuccess("Pengaduan berhasil dikirim!");
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal mengirim pengaduan: $e");
      _setLoading(false);
      return false;
    }
  }

  /// Change password with reauthentication
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _setError("User tidak ditemukan");
      return false;
    }

    _setLoading(true);
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      _setSuccess("Kata sandi berhasil diperbarui");
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  /// Delete account permanently
  Future<bool> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _setError("User tidak ditemukan");
      return false;
    }

    _setLoading(true);
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return "Kata sandi saat ini salah.";
      case 'weak-password':
        return "Kata sandi terlalu lemah (minimal 6 karakter).";
      case 'requires-recent-login':
        return "Sesi telah berakhir demi keamanan. Silakan login ulang.";
      case 'network-request-failed':
        return "Koneksi internet bermasalah. Periksa jaringan Anda.";
      case 'too-many-requests':
        return "Terlalu banyak percobaan. Silakan coba lagi nanti.";
      default:
        return e.message ?? "Terjadi kesalahan sistem.";
    }
  }
}

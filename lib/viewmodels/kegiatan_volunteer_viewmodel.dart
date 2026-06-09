import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class KegiatanVolunteerViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _cloudName = "dm4ua5rj6";
  final String _uploadPreset = "temu_aksi_preset";

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get currentUid => _auth.currentUser?.uid ?? '';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Upload photo to Cloudinary
  Future<String?> uploadImage(File file) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
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

  /// Create a volunteer event
  Future<bool> createVolunteerEvent({
    required String judul,
    required String kategori,
    required String lokasi,
    required String deskripsi,
    required int kuota,
    required String persyaratan,
    required DateTime startDate,
    required DateTime endDate,
    required String jamMulaiStr,
    File? imageFile,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      _setError("Silakan login terlebih dahulu");
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      String photoUrl = '';
      if (imageFile != null) {
        final uploaded = await uploadImage(imageFile);
        if (uploaded == null) {
          _setError("Gagal mengunggah foto kegiatan");
          _setLoading(false);
          return false;
        }
        photoUrl = uploaded;
      }

      await _firestore.collection('volunteer_events').add({
        'company_id': uid,
        'judul': judul,
        'kategori': kategori,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'kuota': kuota,
        'persyaratan': persyaratan,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'jam_mulai': jamMulaiStr,
        'photo_url': photoUrl,
        'status': 'Aktif',
        'peserta_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal membuat kegiatan volunteer: $e");
      _setLoading(false);
      return false;
    }
  }

  /// Update a volunteer event
  Future<bool> updateVolunteerEvent({
    required String docId,
    required String judul,
    required String kategori,
    required String lokasi,
    required String deskripsi,
    required int kuota,
    required String persyaratan,
    required DateTime startDate,
    required DateTime endDate,
    required String jamMulaiStr,
    required String existingPhotoUrl,
    File? newImageFile,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      String photoUrl = existingPhotoUrl;
      if (newImageFile != null) {
        final uploaded = await uploadImage(newImageFile);
        if (uploaded == null) {
          _setError("Gagal mengunggah foto kegiatan baru");
          _setLoading(false);
          return false;
        }
        photoUrl = uploaded;
      }

      await _firestore.collection('volunteer_events').doc(docId).update({
        'judul': judul,
        'kategori': kategori,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'kuota': kuota,
        'persyaratan': persyaratan,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'jam_mulai': jamMulaiStr,
        'photo_url': photoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal memperbarui kegiatan volunteer: $e");
      _setLoading(false);
      return false;
    }
  }
}

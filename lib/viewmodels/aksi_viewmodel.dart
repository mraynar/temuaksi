import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AksiViewModel extends ChangeNotifier {
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

  /// Stream of company's aksi list
  Stream<QuerySnapshot> streamCompanyAksi() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('actions')
        .where('company_id', isEqualTo: uid)
        .snapshots();
  }

  /// Stream of proposal count for a given action
  Stream<QuerySnapshot> streamProposalCount(String actionId) {
    return _firestore
        .collection('proposals')
        .where('action_id', isEqualTo: actionId)
        .snapshots();
  }

  /// Delete an aksi (action)
  Future<bool> deleteAksi(String docId) async {
    _setError(null);
    try {
      await _firestore.collection('actions').doc(docId).delete();
      return true;
    } catch (e) {
      _setError('Gagal menghapus aksi: $e');
      return false;
    }
  }

  /// Upload photo to Cloudinary
  Future<String?> uploadImage(File file) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
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

  /// Create a new Action (Aksi)
  Future<bool> addAksi({
    required String title,
    required String category,
    required String scale,
    required int minFunding,
    required int maxFunding,
    required DateTime startDate,
    required DateTime endDate,
    required String criteria,
    required String syaratKetentuan,
    required String description,
    required String targetPeserta,
    required String responTime,
    required File? imageFile,
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
        if (uploaded != null) {
          photoUrl = uploaded;
        } else {
          throw Exception("Gagal mengunggah foto");
        }
      }

      await _firestore.collection('actions').add({
        'company_id': uid,
        'title': title,
        'category': category,
        'scale': scale,
        'min_funding': minFunding,
        'max_funding': maxFunding,
        'start_date': startDate,
        'end_date': endDate,
        'criteria': criteria,
        'syarat_ketentuan': syaratKetentuan,
        'description': description,
        'target_peserta': targetPeserta,
        'respon_time': responTime,
        'photo_url': photoUrl,
        'status': 'Aktif',
        'proposal_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Gagal mempublikasikan aksi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing Action (Aksi)
  Future<bool> updateAksi({
    required String docId,
    required String title,
    required String category,
    required String scale,
    required int minFunding,
    required int maxFunding,
    required DateTime startDate,
    required DateTime endDate,
    required String criteria,
    required String syaratKetentuan,
    required String description,
    required String targetPeserta,
    required String responTime,
    required String existingPhotoUrl,
    required File? newImageFile,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      String photoUrl = existingPhotoUrl;
      if (newImageFile != null) {
        final uploaded = await uploadImage(newImageFile);
        if (uploaded != null) {
          photoUrl = uploaded;
        } else {
          throw Exception("Gagal mengunggah foto baru");
        }
      }

      await _firestore.collection('actions').doc(docId).update({
        'title': title,
        'category': category,
        'scale': scale,
        'min_funding': minFunding,
        'max_funding': maxFunding,
        'start_date': startDate,
        'end_date': endDate,
        'criteria': criteria,
        'syarat_ketentuan': syaratKetentuan,
        'description': description,
        'target_peserta': targetPeserta,
        'respon_time': responTime,
        'photo_url': photoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Gagal memperbarui aksi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

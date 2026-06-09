import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ProposalViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _cloudName = "dm4ua5rj6";
  final String _uploadPreset = "temu_aksi_preset";

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String get currentUid => _auth.currentUser?.uid ?? '';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
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

  /// Stream of user's proposals for riwayat page
  Stream<QuerySnapshot> streamUserProposals() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('proposals')
        .where('user_id', isEqualTo: uid)
        .snapshots();
  }

  /// Upload file to Cloudinary (raw resource type)
  Future<String?> uploadToCloudinary(File file) async {
    final filename = file.path.split('/').last;
    final ext = filename.split('.').last.toLowerCase();
    MediaType contentType;

    if (ext == 'zip') {
      contentType = MediaType('application', 'zip');
    } else if (ext == 'pdf') {
      contentType = MediaType('application', 'pdf');
    } else if (ext == 'doc') {
      contentType = MediaType('application', 'msword');
    } else if (ext == 'docx') {
      contentType = MediaType('application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/raw/upload");
    var request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: filename,
      contentType: contentType,
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['secure_url'];
      } else {
        debugPrint("Cloudinary Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Cloudinary Upload Error: $e");
    }
    return null;
  }

  /// Submit a new proposal
  Future<bool> submitProposal({
    required String actionId,
    required String perusahaanId,
    required String actionTitle,
    required String namaEvent,
    required String deskripsi,
    required String lokasi,
    required DateTime tanggalEvent,
    required int danaDiminta,
    required File proposalFile,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      _setError('Silakan login terlebih dahulu');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userName = userDoc.exists
          ? (userDoc.data()?['nama_lengkap'] ??
              userDoc.data()?['name'] ??
              'Relawan TemuAksi')
          : 'Relawan TemuAksi';

      final fileUrl = await uploadToCloudinary(proposalFile);
      if (fileUrl == null) {
        _setError('Gagal mengunggah file proposal');
        _setLoading(false);
        return false;
      }

      await _firestore.collection('proposals').add({
        'user_id': uid,
        'user_name': userName,
        'user_email': _auth.currentUser?.email ?? '',
        'action_id': actionId,
        'perusahaan_id': perusahaanId,
        'action_title': actionTitle,
        'nama_event': namaEvent,
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'tanggal_event': Timestamp.fromDate(tanggalEvent),
        'dana_diminta': danaDiminta,
        'file_url': fileUrl,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      try {
        await _firestore
            .collection('actions')
            .doc(actionId)
            .update({'proposal_count': FieldValue.increment(1)});
      } catch (e) {
        debugPrint("Gagal update proposal_count: $e");
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Terjadi kesalahan: $e');
      return false;
    }
  }

  /// Update an existing proposal
  Future<bool> updateProposal({
    required String docId,
    required String namaEvent,
    required String lokasi,
    required String deskripsi,
    required int danaDiminta,
    DateTime? tanggalEvent,
  }) async {
    _setSaving(true);
    _setError(null);
    try {
      await _firestore.collection('proposals').doc(docId).update({
        'nama_event': namaEvent,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'dana_diminta': danaDiminta,
        'tanggal_event':
            tanggalEvent != null ? Timestamp.fromDate(tanggalEvent) : null,
      });
      _setSaving(false);
      return true;
    } catch (e) {
      _setSaving(false);
      _setError('Gagal memperbarui: $e');
      return false;
    }
  }

  /// Delete a proposal
  Future<bool> deleteProposal(String docId) async {
    _setError(null);
    try {
      await _firestore.collection('proposals').doc(docId).delete();
      return true;
    } catch (e) {
      _setError('Gagal menghapus: $e');
      return false;
    }
  }
}

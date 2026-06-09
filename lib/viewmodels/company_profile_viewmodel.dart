import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CompanyProfileViewModel extends ChangeNotifier {
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

  /// Stream of the company user document (profile, saldo, etc.)
  Stream<DocumentSnapshot> streamCompanyProfile() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Fetch impact stats: active aksi count, total relawan, partner count
  Future<Map<String, dynamic>> fetchImpactStats() async {
    final uid = currentUid;
    if (uid.isEmpty) return {'aksiAktif': 0, 'totalRelawan': 0, 'partner': 0};

    try {
      final results = await Future.wait([
        _firestore
            .collection('actions')
            .where('company_id', isEqualTo: uid)
            .where('status', isEqualTo: 'Aktif')
            .get(),
        _firestore
            .collection('volunteer_events')
            .where('company_id', isEqualTo: uid)
            .get(),
        _firestore
            .collection('proposals')
            .where('perusahaan_id', isEqualTo: uid)
            .where('status', isEqualTo: 'diterima')
            .get(),
      ]);

      final int aksiAktif = results[0].docs.length;

      int totalRelawan = 0;
      for (final doc in results[1].docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRelawan += (data['peserta_count'] as num?)?.toInt() ?? 0;
      }

      final int partner = results[2].docs.length;

      return {
        'aksiAktif': aksiAktif,
        'totalRelawan': totalRelawan,
        'partner': partner,
      };
    } catch (e) {
      _setError('Gagal memuat statistik: $e');
      return {'aksiAktif': 0, 'totalRelawan': 0, 'partner': 0};
    }
  }

  /// Stream volunteer events owned by this company
  Stream<QuerySnapshot> streamVolunteerEvents() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('volunteer_events')
        .where('company_id', isEqualTo: uid)
        .snapshots();
  }

  /// Stream registrants for a specific volunteer event
  Stream<QuerySnapshot> streamEventRegistrants(String eventId) {
    return _firestore
        .collection('volunteer_events')
        .doc(eventId)
        .collection('registrants')
        .snapshots();
  }

  /// Delete a volunteer event
  Future<bool> deleteVolunteerEvent(String docId) async {
    _setError(null);
    try {
      await _firestore.collection('volunteer_events').doc(docId).delete();
      return true;
    } catch (e) {
      _setError('Gagal menghapus kegiatan: $e');
      return false;
    }
  }

  /// Top Up Balance for company
  Future<bool> topUpSaldo(int amount) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      _setError("Silakan login terlebih dahulu");
      return false;
    }

    _setError(null);
    try {
      final userDoc = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);

        if (!snapshot.exists) {
          throw Exception("Data perusahaan tidak ditemukan!");
        }

        int currentBalance = 0;
        try {
          currentBalance = snapshot.get('saldo_csr') ?? 0;
        } catch (_) {
          currentBalance = 0;
        }

        int newBalance = currentBalance + amount;

        transaction.update(userDoc, {'saldo_csr': newBalance});

        DocumentReference historyDoc = _firestore.collection('transactions').doc();
        transaction.set(historyDoc, {
          'company_id': uid,
          'amount': amount,
          'type': 'topup',
          'status': 'success',
          'created_at': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      _setError('Gagal memproses top up: $e');
      return false;
    }
  }

  /// Stream transaction history for this company
  Stream<QuerySnapshot> streamTransactions() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('transactions')
        .where('company_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Stream team members for this company
  Stream<QuerySnapshot> streamCompanyTeam() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('users')
        .where('parent_uid', isEqualTo: uid)
        .where('role', isEqualTo: 'admin_perusahaan')
        .snapshots();
  }

  /// Upload photo to Cloudinary
  Future<String?> uploadToCloudinary(File file) async {
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

  /// Add company photo
  Future<bool> addCompanyPhoto(File file) async {
    final uid = currentUid;
    if (uid.isEmpty) return false;

    _setError(null);
    try {
      final uploadedUrl = await uploadToCloudinary(file);
      if (uploadedUrl == null) throw Exception("Gagal mengunggah foto");

      await _firestore.collection('users').doc(uid).update({
        'company_photos': FieldValue.arrayUnion([uploadedUrl])
      });
      return true;
    } catch (e) {
      _setError('Gagal menambahkan foto: $e');
      return false;
    }
  }

  /// Delete company photo
  Future<bool> deleteCompanyPhoto(String url) async {
    final uid = currentUid;
    if (uid.isEmpty) return false;

    _setError(null);
    try {
      await _firestore.collection('users').doc(uid).update({
        'company_photos': FieldValue.arrayRemove([url])
      });
      return true;
    } catch (e) {
      _setError('Gagal menghapus foto: $e');
      return false;
    }
  }

  /// Replace company photo
  Future<bool> replaceCompanyPhoto(String oldUrl, File newFile) async {
    final uid = currentUid;
    if (uid.isEmpty) return false;

    _setError(null);
    try {
      final newUrl = await uploadToCloudinary(newFile);
      if (newUrl == null) throw Exception("Gagal mengunggah foto baru");

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<String> photos = List<String>.from(data['company_photos'] ?? []);
        final idx = photos.indexOf(oldUrl);
        if (idx != -1) {
          photos[idx] = newUrl;
          await _firestore.collection('users').doc(uid).update({
            'company_photos': photos,
          });
        } else {
          await _firestore.collection('users').doc(uid).update({
            'company_photos': FieldValue.arrayRemove([oldUrl])
          });
          await _firestore.collection('users').doc(uid).update({
            'company_photos': FieldValue.arrayUnion([newUrl])
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Gagal mengganti foto: $e');
      return false;
    }
  }

  /// Load company data once (for form pre-fill)
  Future<Map<String, dynamic>> loadCompanyProfile() async {
    final uid = currentUid;
    if (uid.isEmpty) return {};
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? (doc.data() as Map<String, dynamic>) : {};
    } catch (_) {
      return {};
    }
  }

  /// Update public profile details
  Future<bool> updatePublicProfile({
    required String deskripsi,
    required String website,
    required String tahunBerdiri,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) return false;

    _setError(null);
    try {
      await _firestore.collection('users').doc(uid).update({
        'deskripsi_perusahaan': deskripsi,
        'website': website,
        'tahun_berdiri': tahunBerdiri,
      });
      return true;
    } catch (e) {
      _setError('Gagal menyimpan profil: $e');
      return false;
    }
  }
}

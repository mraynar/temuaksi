import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get currentUid => _auth.currentUser?.uid ?? '';

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
}

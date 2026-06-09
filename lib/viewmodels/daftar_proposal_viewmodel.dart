import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DaftarProposalViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isFundingLoading = false;
  String? _errorMessage;

  bool get isFundingLoading => _isFundingLoading;
  String? get errorMessage => _errorMessage;

  String get currentUid => _auth.currentUser?.uid ?? '';

  void _setFundingLoading(bool value) {
    _isFundingLoading = value;
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

  /// Stream proposals for this company, optionally filtered by status
  Stream<QuerySnapshot> streamCompanyProposals({String? statusFilter}) {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();

    if (statusFilter == null || statusFilter == 'all') {
      return _firestore
          .collection('proposals')
          .where('perusahaan_id', isEqualTo: uid)
          .snapshots();
    }
    return _firestore
        .collection('proposals')
        .where('perusahaan_id', isEqualTo: uid)
        .where('status', isEqualTo: statusFilter)
        .snapshots();
  }

  /// Update proposal status (e.g. pending → ditinjau, pending → ditolak)
  Future<bool> updateProposalStatus(String docId, String newStatus,
      {int? danaDisetujui}) async {
    _setError(null);
    try {
      final Map<String, dynamic> updateData = {'status': newStatus};
      if (danaDisetujui != null) {
        updateData['dana_disetujui'] = danaDisetujui;
      }
      await _firestore.collection('proposals').doc(docId).update(updateData);
      return true;
    } catch (e) {
      _setError('Gagal memperbarui status: $e');
      return false;
    }
  }

  /// Approve funding: deduct saldo_csr, mark proposal selesai, record transaction
  Future<bool> approveFunding({
    required String docId,
    required Map<String, dynamic> proposalData,
    required int danaDisetujui,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      _setError('Silakan login terlebih dahulu');
      return false;
    }

    _setFundingLoading(true);
    _setError(null);

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final proposalRef = _firestore.collection('proposals').doc(docId);
      final transactionRef = _firestore.collection('transactions').doc();

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw Exception("User tidak ditemukan");

        final userData = userSnapshot.data() as Map<String, dynamic>;
        final int currentSaldo = userData['saldo_csr'] ?? 0;

        if (currentSaldo < danaDisetujui) {
          throw Exception("Saldo CSR tidak mencukupi");
        }

        transaction.update(userRef, {
          'saldo_csr': FieldValue.increment(-danaDisetujui),
        });

        transaction.update(proposalRef, {
          'status': 'selesai',
          'dana_disetujui': danaDisetujui,
        });

        transaction.set(transactionRef, {
          'company_id': uid,
          'proposal_id': docId,
          'amount': danaDisetujui,
          'type': 'pendanaan',
          'status': 'success',
          'created_at': FieldValue.serverTimestamp(),
        });
      });

      _setFundingLoading(false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll("Exception: ", "");
      _setError('Gagal memproses pendanaan: $errorMsg');
      _setFundingLoading(false);
      return false;
    }
  }
}

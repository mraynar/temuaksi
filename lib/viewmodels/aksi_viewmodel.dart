import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AksiViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}

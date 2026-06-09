import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  /// Future to get all dashboard analytics count
  Future<List<QuerySnapshot>> getDashboardStats() {
    return Future.wait([
      _firestore.collection('users').get(),
      _firestore.collection('proposals').get(),
      _firestore.collection('actions').get(),
      _firestore.collection('volunteer_events').get(),
    ]);
  }

  /// Stream users with filter
  Stream<QuerySnapshot> streamUsers(String? roleFilter) {
    Query query = _firestore.collection('users');
    if (roleFilter != null) {
      if (roleFilter == 'individu') {
        query = query.where('role', whereIn: ['individu', 'Individu']);
      } else if (roleFilter == 'perusahaan') {
        query = query.where('role', whereIn: ['perusahaan', 'Perusahaan']);
      }
    }
    return query.snapshots();
  }

  /// Delete user account from Firestore
  Future<bool> deleteUser(String docId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firestore.collection('users').doc(docId).delete();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal menghapus akun: $e");
      _setLoading(false);
      return false;
    }
  }

  /// Stream complaints with filter
  Stream<QuerySnapshot> streamComplaints(String statusFilter) {
    Query query = _firestore.collection('complaints');
    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots();
  }

  /// Update complaint status
  Future<bool> updateComplaintStatus(String docId, String newStatus) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firestore.collection('complaints').doc(docId).update({
        'status': newStatus,
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Gagal memperbarui status: $e");
      _setLoading(false);
      return false;
    }
  }
}

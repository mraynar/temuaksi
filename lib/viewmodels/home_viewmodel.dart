import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/aksi_model.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  int _points = 0;
  List<AksiModel> _featuredList = [];
  List<QueryDocumentSnapshot> _companyList = [];
  bool _isLoading = false;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  UserModel? get user => _user;
  int get points => _points;
  List<AksiModel> get featuredList => _featuredList;
  List<QueryDocumentSnapshot> get companyList => _companyList;
  bool get isLoading => _isLoading;

  String get currentUid => _auth.currentUser?.uid ?? '';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Load user data and start listening to real-time points
  void listenUserPoints() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _userSubscription?.cancel();
    _userSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      try {
        if (doc.exists) {
          _user = UserModel.fromFirestore(doc);
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final pts = data['points'] ?? data['poin'] ?? 0;
          _points = pts is int
              ? pts
              : (pts is num
                  ? pts.toInt()
                  : (int.tryParse(pts.toString()) ?? 0));
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error parsing user points: $e");
      }
    }, onError: (error) {
      debugPrint("Error listening to user points: $error");
    });
  }

  /// Load featured aksi list
  Future<void> loadFeaturedAksi() async {
    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('actions')
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();

      _featuredList = snapshot.docs
          .map((doc) => AksiModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      _featuredList = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load company list for home display
  Future<void> loadCompanyList() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'perusahaan')
          .limit(10)
          .get();
      _companyList = snapshot.docs;
      notifyListeners();
    } catch (_) {
      _companyList = [];
      notifyListeners();
    }
  }

  /// Load all home data at once
  Future<void> init() async {
    listenUserPoints();
    await Future.wait([loadFeaturedAksi(), loadCompanyList()]);
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}

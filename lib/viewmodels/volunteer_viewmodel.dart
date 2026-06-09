import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/volunteer_model.dart';
import '../services/volunteer_service.dart';

class VolunteerViewModel extends ChangeNotifier {
  final VolunteerService _service = VolunteerService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<VolunteerModel> _volunteerList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VolunteerModel> get volunteerList => _volunteerList;
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

  /// Stream of active volunteer events
  Stream<QuerySnapshot> streamVolunteerEvents() {
    return _firestore
        .collection('volunteer_events')
        .where('status', isEqualTo: 'Aktif')
        .snapshots();
  }

  /// Stream of user's registration status for a specific event
  Stream<QuerySnapshot> streamUserRegistration(String eventId) {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('user_volunteers')
        .where('uid', isEqualTo: uid)
        .where('volunteer_event_id', isEqualTo: eventId)
        .snapshots();
  }

  /// Stream of all user_volunteers for current user (for detail page)
  Stream<QuerySnapshot> streamUserVolunteers() {
    final uid = currentUid;
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('user_volunteers')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  /// Load volunteer list from Firestore
  Future<void> loadVolunteerList() async {
    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('volunteer_events')
          .where('status', isEqualTo: 'Aktif')
          .get();
      _volunteerList =
          snapshot.docs.map((d) => VolunteerModel.fromFirestore(d)).toList();
    } catch (e) {
      _volunteerList = [];
      _setError('Gagal memuat data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Daftar volunteer — calls VolunteerService
  Future<bool> daftarVolunteer({
    required String eventId,
    required String title,
    required String category,
    required String description,
    required int pointReward,
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
      final userData = userDoc.data() ?? {};

      await _firestore.collection('user_volunteers').add({
        'uid': uid,
        'event_id': eventId,
        'volunteer_event_id': eventId,
        'title': title,
        'category': category,
        'description': description,
        'status': 'sedang berjalan',
        'points': pointReward,
        'registered_at': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('volunteer_events')
          .doc(eventId)
          .update({'peserta_count': FieldValue.increment(1)});

      await _firestore
          .collection('volunteer_events')
          .doc(eventId)
          .collection('registrants')
          .add({
        'uid': uid,
        'nama_lengkap': userData['nama_lengkap'] ?? '',
        'email': _auth.currentUser?.email ?? '',
        'registered_at': FieldValue.serverTimestamp(),
        'status': 'aktif',
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Gagal mendaftar: $e');
      return false;
    }
  }

  /// Submit progress — calls VolunteerService, uploads to Cloudinary
  Future<bool> submitProgress({
    required String registrationId,
    required String laporan,
    File? photoFile,
    File? pdfFile,
    required int pointReward,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      _setError('Silakan login terlebih dahulu');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      String? photoUrl;
      String? pdfUrl;

      if (photoFile != null) {
        photoUrl = await _service.uploadToCloudinary(photoFile, 'image');
      }
      if (pdfFile != null) {
        pdfUrl = await _service.uploadToCloudinary(pdfFile, 'raw');
      }

      await _service.submitProgressVolunteer(
        registrationId: registrationId,
        uid: uid,
        laporan: laporan,
        photoUrl: photoUrl,
        pdfUrl: pdfUrl,
        pointReward: pointReward,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Gagal mengirim progres: $e');
      return false;
    }
  }
}

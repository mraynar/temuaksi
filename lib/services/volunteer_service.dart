import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class VolunteerService {
  final String cloudName = "dm4ua5rj6";
  final String uploadPreset = "temu_aksi_preset";

  Future<void> daftarVolunteer(String eventId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User tidak terautentikasi');
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('user_volunteers')
        .where('user_id', isEqualTo: uid)
        .where('event_id', isEqualTo: eventId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      throw Exception('Sudah terdaftar di kegiatan ini');
    }

    await FirebaseFirestore.instance.collection('user_volunteers').add({
      'user_id': uid,
      'event_id': eventId,
      'status': 'active',
      'registered_at': Timestamp.now(),
    });
  }

  Future<String> uploadToCloudinary(File file, String resourceType) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");
    var request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;

    MediaType? contentType;
    String? filename;

    if (resourceType == 'raw') {
      contentType = MediaType('application', 'pdf');
      filename = 'laporan.pdf';
    } else {
      contentType = MediaType('image', 'jpeg');
      filename = file.path.split('/').last;
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: filename,
      contentType: contentType,
    ));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonRes = jsonDecode(response.body);
        return jsonRes['secure_url'];
      } else {
        throw Exception('Gagal upload ke Cloudinary. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Cloudinary Upload Error: $e");
      throw Exception('Error saat mengunggah file: $e');
    }
  }

  Future<void> submitProgressVolunteer({
    required String registrationId,
    required String uid,
    required String laporan,
    String? photoUrl,
    String? pdfUrl,
    required int pointReward,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final registrationRef = firestore.collection('user_volunteers').doc(registrationId);
    final userRef = firestore.collection('users').doc(uid);

    await firestore.runTransaction((transaction) async {
      transaction.update(registrationRef, {
        'status': 'selesai',
        'photo_url': photoUrl,
        'pdf_url': pdfUrl,
        'laporan': laporan,
        'progress_submitted_at': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {
        'points': FieldValue.increment(pointReward),
      });
    });
  }
}

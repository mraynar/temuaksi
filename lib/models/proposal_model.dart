import 'package:cloud_firestore/cloud_firestore.dart';

class ProposalModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String actionId;
  final String perusahaanId;
  final String actionTitle;
  final String namaEvent;
  final String deskripsi;
  final String lokasi;
  final int danaDiminta;
  final String fileUrl;
  final String status;
  final DateTime? tanggalEvent;
  final DateTime? createdAt;

  const ProposalModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.actionId,
    required this.perusahaanId,
    required this.actionTitle,
    required this.namaEvent,
    required this.deskripsi,
    required this.lokasi,
    required this.danaDiminta,
    required this.fileUrl,
    required this.status,
    this.tanggalEvent,
    this.createdAt,
  });

  factory ProposalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProposalModel(
      id: doc.id,
      userId: (data['user_id'] ?? '').toString(),
      userName: (data['user_name'] ?? '').toString(),
      userEmail: (data['user_email'] ?? '').toString(),
      actionId: (data['action_id'] ?? '').toString(),
      perusahaanId: (data['perusahaan_id'] ?? '').toString(),
      actionTitle: (data['action_title'] ?? '').toString(),
      namaEvent: (data['nama_event'] ?? '').toString(),
      deskripsi: (data['deskripsi'] ?? '').toString(),
      lokasi: (data['lokasi'] ?? '').toString(),
      danaDiminta: (data['dana_diminta'] ?? 0) is int
          ? (data['dana_diminta'] ?? 0) as int
          : int.tryParse((data['dana_diminta'] ?? 0).toString()) ?? 0,
      fileUrl: (data['file_url'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      tanggalEvent: (data['tanggal_event'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'action_id': actionId,
      'perusahaan_id': perusahaanId,
      'action_title': actionTitle,
      'nama_event': namaEvent,
      'deskripsi': deskripsi,
      'lokasi': lokasi,
      'dana_diminta': danaDiminta,
      'file_url': fileUrl,
      'status': status,
      'tanggal_event':
          tanggalEvent != null ? Timestamp.fromDate(tanggalEvent!) : null,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

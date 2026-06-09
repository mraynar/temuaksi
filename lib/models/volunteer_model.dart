import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerModel {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final DateTime? registeredAt;
  final String photoUrl;
  final String pdfUrl;
  final String laporan;

  const VolunteerModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    this.registeredAt,
    required this.photoUrl,
    required this.pdfUrl,
    required this.laporan,
  });

  factory VolunteerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VolunteerModel(
      id: doc.id,
      userId: (data['uid'] ?? data['user_id'] ?? '').toString(),
      eventId: (data['volunteer_event_id'] ?? data['event_id'] ?? '').toString(),
      status: (data['status'] ?? 'sedang berjalan').toString(),
      registeredAt: (data['registered_at'] as Timestamp?)?.toDate(),
      photoUrl: (data['photo_url'] ?? '').toString(),
      pdfUrl: (data['pdf_url'] ?? '').toString(),
      laporan: (data['laporan'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status,
      'registeredAt': registeredAt != null ? Timestamp.fromDate(registeredAt!) : null,
      'photo_url': photoUrl,
      'pdf_url': pdfUrl,
      'laporan': laporan,
    };
  }
}

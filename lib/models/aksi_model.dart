import 'package:cloud_firestore/cloud_firestore.dart';

class AksiModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final int pointReward;
  final String companyId;
  final DateTime? createdAt;

  const AksiModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.pointReward,
    required this.companyId,
    this.createdAt,
  });

  factory AksiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AksiModel(
      id: doc.id,
      title: (data['title'] ?? data['nama_event'] ?? '').toString(),
      description: (data['description'] ?? data['deskripsi'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? data['image_url'] ?? data['foto_url'] ?? '').toString(),
      category: (data['category'] ?? data['kategori'] ?? '').toString(),
      pointReward: (data['pointReward'] ?? data['point_reward'] ?? data['poin'] ?? 0) is int
          ? (data['pointReward'] ?? data['point_reward'] ?? data['poin'] ?? 0) as int
          : int.tryParse((data['pointReward'] ?? data['point_reward'] ?? data['poin'] ?? 0).toString()) ?? 0,
      companyId: (data['companyId'] ?? data['company_id'] ?? data['perusahaan_id'] ?? '').toString(),
      createdAt: ((data['createdAt'] ?? data['created_at']) as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'pointReward': pointReward,
      'companyId': companyId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

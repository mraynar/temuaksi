import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String role;
  final int points;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.role,
    required this.points,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: (data['name'] ?? data['nama_lengkap'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      photoUrl: (data['photo_url'] ?? '').toString(),
      role: (data['role'] ?? 'individu').toString().toLowerCase(),
      points: (data['points'] ?? 0) is int
          ? data['points'] as int
          : int.tryParse(data['points'].toString()) ?? 0,
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    int? points,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'role': role,
      'points': points,
    };
  }
}

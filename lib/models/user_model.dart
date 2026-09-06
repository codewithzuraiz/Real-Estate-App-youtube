import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String role;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.bio = '',
    this.role = 'Client / Buyer',
    this.avatarUrl = '',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      role: map['role'] ?? 'Client / Buyer',
      avatarUrl: map['avatarUrl'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? role,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

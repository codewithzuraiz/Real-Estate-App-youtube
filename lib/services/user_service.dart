import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Create user in Firestore
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Stream of user profile for real-time updates
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // Get user profile once
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Get user by phone number
  Future<UserModel?> getUserByPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    // Try exact match first
    var snapshot = await _usersCollection
        .where('phone', isEqualTo: phone.trim())
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return UserModel.fromMap(doc.data(), doc.id);
    }

    // Try without spaces
    snapshot = await _usersCollection
        .where('phone', isEqualTo: clean)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return UserModel.fromMap(doc.data(), doc.id);
    }

    return null;
  }

  // Update full user profile
  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
  }

  // Update specific fields
  Future<void> updateFields(String uid, Map<String, dynamic> fields) async {
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _usersCollection.doc(uid).update(fields);
  }
}

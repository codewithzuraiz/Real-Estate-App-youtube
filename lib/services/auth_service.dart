import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'Buyer',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());

      final newUser = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      await _userService.createUser(newUser);
    }

    return credential;
  }

  // Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign In with Phone & Password
  Future<UserCredential> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    final user = await _userService.getUserByPhone(phone);
    if (user == null || user.email.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No registered account found with phone number $phone.',
      );
    }
    return await signIn(
      email: user.email,
      password: password,
    );
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper method to convert Firebase exceptions into readable user-friendly messages
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'The password is too weak. Please choose a stronger password.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your email and password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore permission denied. Please enable read/write rules in Firebase Console.';
        case 'unavailable':
          return 'Service temporarily unavailable. Please check your internet connection.';
        default:
          return error.message ?? error.toString();
      }
    }
    return error.toString();
  }
}

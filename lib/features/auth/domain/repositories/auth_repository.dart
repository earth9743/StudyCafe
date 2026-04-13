import 'package:firebase_auth/firebase_auth.dart';
import 'package:kagong_map/features/auth/domain/models/user_model.dart';

/// 인증 Repository 인터페이스
abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithKakao();
  Future<void> signOut();
  Future<UserModel?> getUserProfile(String uid);
  Future<void> updateUserProfile(UserModel user);
  Future<void> saveAgreements({
    required String uid,
    required bool terms,
    required bool privacy,
    required bool location,
    required bool marketing,
  });

  /// 회원 탈퇴: Firestore 데이터 및 Firebase Auth 계정 삭제
  Future<void> deleteAccount();
}

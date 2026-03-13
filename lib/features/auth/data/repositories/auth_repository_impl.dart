import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:kagong_map/core/constants/firestore_paths.dart';
import 'package:kagong_map/features/auth/domain/models/user_model.dart'
    as app_model;
import 'package:kagong_map/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _createUserDocument(
        userCredential.user!,
        app_model.AuthProvider.google,
      );
    }

    return userCredential;
  }

  @override
  Future<UserCredential> signInWithKakao() async {
    // 카카오톡 설치 여부에 따라 로그인 방식 분기
    if (await kakao.isKakaoTalkInstalled()) {
      await kakao.UserApi.instance.loginWithKakaoTalk();
    } else {
      await kakao.UserApi.instance.loginWithKakaoAccount();
    }

    // 카카오 사용자 정보 조회
    final kakaoUser = await kakao.UserApi.instance.me();

    final email = kakaoUser.kakaoAccount?.email ?? '${kakaoUser.id}@kakao.user';
    final password = 'kakao_${kakaoUser.id}_secure_password';

    UserCredential userCredential;
    try {
      userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await userCredential.user?.updateDisplayName(
          kakaoUser.kakaoAccount?.profile?.nickname ?? '카공러',
        );
        await _createUserDocument(
          userCredential.user!,
          app_model.AuthProvider.kakao,
          displayName: kakaoUser.kakaoAccount?.profile?.nickname,
          photoUrl: kakaoUser.kakaoAccount?.profile?.thumbnailImageUrl,
        );
      } else {
        rethrow;
      }
    }

    return userCredential;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await kakao.UserApi.instance.logout();
    } catch (_) {}
  }

  @override
  Future<app_model.UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return app_model.UserModel.fromFirestore(doc);
  }

  @override
  Future<void> updateUserProfile(app_model.UserModel user) async {
    await _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .update(user.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  @override
  Future<void> saveAgreements({
    required String uid,
    required bool terms,
    required bool privacy,
    required bool location,
    required bool marketing,
  }) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).update({
      'agreedToTerms': terms,
      'agreedToPrivacy': privacy,
      'agreedToLocation': location,
      'agreedToMarketing': marketing,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _createUserDocument(
    User firebaseUser,
    app_model.AuthProvider provider, {
    String? displayName,
    String? photoUrl,
  }) async {
    final now = DateTime.now();
    final userModel = app_model.UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName ?? firebaseUser.displayName ?? '카공러',
      photoUrl: photoUrl ?? firebaseUser.photoURL,
      provider: provider,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(firebaseUser.uid)
        .set(userModel.toFirestore());
  }
}

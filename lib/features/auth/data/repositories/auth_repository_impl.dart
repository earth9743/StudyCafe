import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('[GoogleAuth] 구글 로그인 시작');
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('user_canceled: 구글 로그인이 취소되었습니다.');
    }

    debugPrint('[GoogleAuth] 구글 사용자: ${googleUser.email}');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    debugPrint('[GoogleAuth] Firebase 인증 시도');
    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _createUserDocument(
        userCredential.user!,
        app_model.AuthProvider.google,
      );
    }

    debugPrint('[GoogleAuth] 로그인 성공: ${userCredential.user?.uid}');
    return userCredential;
  }

  @override
  Future<UserCredential> signInWithKakao() async {
    // 카카오톡 설치 여부에 따라 로그인 방식 분기
    debugPrint('[KakaoAuth] 카카오 로그인 시작');
    if (await kakao.isKakaoTalkInstalled()) {
      debugPrint('[KakaoAuth] 카카오톡 앱으로 로그인');
      await kakao.UserApi.instance.loginWithKakaoTalk();
    } else {
      debugPrint('[KakaoAuth] 카카오 계정(웹)으로 로그인');
      await kakao.UserApi.instance.loginWithKakaoAccount();
    }

    // 카카오 사용자 정보 조회
    debugPrint('[KakaoAuth] 카카오 사용자 정보 조회');
    final kakaoUser = await kakao.UserApi.instance.me();
    debugPrint('[KakaoAuth] 카카오 사용자 ID: ${kakaoUser.id}');

    final email = kakaoUser.kakaoAccount?.email ?? '${kakaoUser.id}@kakao.user';
    final password = 'kakao_${kakaoUser.id}_secure_password';
    debugPrint('[KakaoAuth] Firebase 로그인 이메일: $email');

    UserCredential userCredential;
    try {
      debugPrint('[KakaoAuth] Firebase signIn 시도');
      userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[KakaoAuth] Firebase signIn 성공');
    } on FirebaseAuthException catch (e) {
      debugPrint('[KakaoAuth] FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        debugPrint('[KakaoAuth] 신규 사용자 - Firebase 계정 생성');
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
        debugPrint('[KakaoAuth] 신규 사용자 생성 완료');
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
      await GoogleSignIn().signOut();
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

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    // Cloud Function 호출 (Admin SDK로 서버에서 삭제 처리)
    // 재인증 불필요 - Admin SDK가 requires-recent-login 우회
    debugPrint('[AuthRepo] Cloud Function deleteAccount 호출');
    final callable = FirebaseFunctions.instance.httpsCallable('deleteAccount');
    await callable.call();
    debugPrint('[AuthRepo] Cloud Function deleteAccount 완료');

    // 소셜 로그인 세션 정리
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await kakao.UserApi.instance.logout();
    } catch (_) {}
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

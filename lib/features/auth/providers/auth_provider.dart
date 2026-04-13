import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kagong_map/features/auth/domain/models/user_model.dart';
import 'package:kagong_map/features/auth/domain/repositories/auth_repository.dart';

/// AuthRepository 프로바이더
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Firebase Auth 상태 스트림
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

/// 현재 로그인한 사용자 프로필
final userProfileProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final authRepo = ref.read(authRepositoryProvider);
      return authRepo.getUserProfile(user.uid);
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

/// 인증 컨트롤러 (로그인/로그아웃 액션)
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('[AuthController] 구글 로그인 에러: $e');
      debugPrint('[AuthController] 스택트레이스: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithKakao() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithKakao();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('[AuthController] 카카오 로그인 에러: $e');
      debugPrint('[AuthController] 스택트레이스: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
    });
  }

  /// 회원 탈퇴
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('[AuthController] 회원 탈퇴 에러: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> saveAgreements({
    required bool terms,
    required bool privacy,
    required bool location,
    required bool marketing,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final user = authRepo.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');
      await authRepo.saveAgreements(
        uid: user.uid,
        terms: terms,
        privacy: privacy,
        location: location,
        marketing: marketing,
      );
    });
  }
}

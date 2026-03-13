import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';

/// 메인 지도 화면 (Phase 2에서 네이버 지도 통합 예정)
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카공지도'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '지도 화면',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              'Phase 2에서 네이버 지도가 표시됩니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            user.when(
              data: (u) => Text(
                '로그인: ${u?.email ?? "없음"}',
                style: AppTextStyles.bodySmall,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

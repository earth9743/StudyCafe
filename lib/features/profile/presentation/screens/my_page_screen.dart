import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';
import 'package:kagong_map/features/profile/providers/my_review_provider.dart';

/// 마이페이지 화면
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isLoggedIn = authState.value != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: isLoggedIn
          ? _buildLoggedInContent(context, ref, userProfile)
          : _buildNotLoggedInContent(context),
    );
  }

  /// 로그인한 사용자의 마이페이지
  Widget _buildLoggedInContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue userProfile,
  ) {
    final user = ref.watch(authStateProvider).value!;
    final myReviews = ref.watch(myReviewsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 프로필 섹션
          _buildProfileSection(user.displayName ?? '사용자', user.email ?? ''),
          const SizedBox(height: 8),

          // 내가 남긴 리뷰 섹션
          _buildMyReviewsSection(context, ref, myReviews),
          const SizedBox(height: 8),

          // 메뉴 섹션
          _buildMenuSection(context, ref),
        ],
      ),
    );
  }

  /// 비로그인 사용자
  Widget _buildNotLoggedInContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '로그인이 필요합니다',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '로그인하면 리뷰 작성, 내 리뷰 확인 등\n다양한 기능을 이용할 수 있습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('로그인', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 프로필 섹션
  Widget _buildProfileSection(String name, String email) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 내가 남긴 리뷰 섹션
  Widget _buildMyReviewsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ReviewModel>> myReviews,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('내가 남긴 리뷰', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          myReviews.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.edit_note,
                          size: 36, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text(
                        '아직 작성한 리뷰가 없습니다',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  // 리뷰 개수 표시
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '총 ${reviews.length}개',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...reviews.map((review) => _buildMyReviewItem(review)),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    '리뷰를 불러오지 못했습니다',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      // ignore: unused_result
                      ref.refresh(myReviewsProvider);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('다시 시도'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: AppTextStyles.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 내 리뷰 아이템
  Widget _buildMyReviewItem(ReviewModel review) {
    final dateStr = DateFormat('yyyy.MM.dd').format(review.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카페 이름 + 날짜
          Row(
            children: [
              const Icon(Icons.local_cafe, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  review.cafeId.split('_').first,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),

          // 별점
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: i < review.rating
                      ? const Color(0xFFFFB800)
                      : AppColors.secondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 태그
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildTag('혼잡도', review.crowdLevel.label),
              _buildTag('콘센트', review.outletLevel.label),
              _buildTag('소음', review.noiseLevel.label),
            ],
          ),

          // 리뷰 내용
          if (review.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // 사진
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    review.photoUrls[index],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.secondary,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String category, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$category: $value',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 10,
        ),
      ),
    );
  }

  /// 메뉴 섹션 (로그아웃, 라이센스)
  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: '오픈소스 라이센스',
            onTap: () => _showLicenses(context),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.divider),
          _buildMenuItem(
            icon: Icons.logout,
            title: '로그아웃',
            titleColor: AppColors.error,
            onTap: () => _showLogoutDialog(context, ref),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: titleColor ?? AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: titleColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (titleColor == null)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }

  /// 로그아웃 확인 다이얼로그
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '정말 로그아웃 하시겠습니까?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 오픈소스 라이센스 화면
  void _showLicenses(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              centerTitle: true,
            ),
          ),
          child: const LicensePage(
            applicationName: '카공지도',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 카공지도. All rights reserved.',
          ),
        ),
      ),
    );
  }
}

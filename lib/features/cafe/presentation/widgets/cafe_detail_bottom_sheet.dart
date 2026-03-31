import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/cafe/domain/models/cafe_place_model.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';
import 'package:kagong_map/features/cafe/providers/review_provider.dart';
import 'package:kagong_map/features/cafe/presentation/widgets/review_write_sheet.dart';

/// 카페 상세 정보 Bottom Sheet
/// - compact: 마커 탭 → 카페 이름 + 주소 + 전화 + 상태 (콘텐츠 크기에 딱 맞게)
/// - full: 검색 선택 or 컴팩트에서 "자세히 보기" → 리뷰 포함 전체
class CafeDetailBottomSheet extends ConsumerWidget {
  final CafePlaceModel place;
  final bool compact;

  const CafeDetailBottomSheet({
    super.key,
    required this.place,
    this.compact = false,
  });

  String get _cafeId => generateCafeId(place.name, place.lat, place.lng);

  /// 검색에서 선택 시: 전체 (리뷰 포함)
  static void show(BuildContext context, CafePlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeDetailBottomSheet(place: place),
    );
  }

  /// 마커 탭 시: 컴팩트 (콘텐츠에 딱 맞게)
  static void showCompact(BuildContext context, CafePlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeDetailBottomSheet(place: place, compact: true),
    );
  }

  String get _displayAddress =>
      place.roadAddress.isNotEmpty ? place.roadAddress : place.address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cafeReviewStatsProvider(_cafeId));
    final reviewsAsync = ref.watch(cafeReviewsProvider(_cafeId));
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // 전체 모드일 때만 최대 높이 제한 (스크롤 가능)
      constraints: compact
          ? null
          : BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: compact
          ? _buildCompactContent(context, ref, stats, bottomPadding)
          : _buildFullContent(
              context, ref, stats, reviewsAsync, bottomPadding),
    );
  }

  /// 컴팩트 모드: 콘텐츠 크기에 딱 맞게 (Wrap 방식)
  Widget _buildCompactContent(
    BuildContext context,
    WidgetRef ref,
    CafeReviewStats stats,
    double bottomPadding,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildInfoRow(Icons.place_outlined, _displayAddress),
              if (place.phone.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildPhoneRow(),
              ],
              const SizedBox(height: 16),
              _buildStatusSection(stats),
              const SizedBox(height: 12),
              // 자세히 보기 버튼
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    show(context, place);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '자세히 보기',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 전체 모드: 스크롤 가능, 리뷰 포함
  Widget _buildFullContent(
    BuildContext context,
    WidgetRef ref,
    CafeReviewStats stats,
    AsyncValue<List<ReviewModel>> reviewsAsync,
    double bottomPadding,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.place_outlined, _displayAddress),
                if (place.phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildPhoneRow(),
                ],
                const SizedBox(height: 16),
                _buildStatusSection(stats),
                const SizedBox(height: 16),
                _buildRatingSummary(context, ref, stats),
                const SizedBox(height: 16),
                _buildReviewList(context, reviewsAsync),
                const SizedBox(height: 12),
                _buildDirectionsButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── 공통 위젯 ───────────────────────────

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 16),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.secondaryDark,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_cafe,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(place.name, style: AppTextStyles.h4),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildPhoneRow() {
    return GestureDetector(
      onTap: () => _makePhoneCall(place.phone),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            place.phone,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(CafeReviewStats stats) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatusChip(
            icon: Icons.people_outline,
            label: '혼잡도',
            value: stats.crowdLabel,
            color: _crowdColor(stats),
          ),
          _buildDividerVertical(),
          _buildStatusChip(
            icon: Icons.power_outlined,
            label: '콘센트',
            value: stats.outletLabel,
            color: _outletColor(stats),
          ),
          _buildDividerVertical(),
          _buildStatusChip(
            icon: Icons.volume_up_outlined,
            label: '소음',
            value: stats.noiseLabel,
            color: _noiseColor(stats),
          ),
        ],
      ),
    );
  }

  Color _crowdColor(CafeReviewStats stats) {
    if (stats.reviewCount == 0) return AppColors.crowdUnknown;
    if (stats.averageCrowd <= 1.5) return AppColors.crowdLow;
    if (stats.averageCrowd <= 2.5) return AppColors.crowdModerate;
    return AppColors.crowdHigh;
  }

  Color _outletColor(CafeReviewStats stats) {
    if (stats.reviewCount == 0) return AppColors.crowdUnknown;
    if (stats.averageOutlet <= 1.5) return AppColors.outletAvailable;
    if (stats.averageOutlet <= 2.5) return AppColors.outletLimited;
    return AppColors.outletUnavailable;
  }

  Color _noiseColor(CafeReviewStats stats) {
    if (stats.reviewCount == 0) return AppColors.crowdUnknown;
    if (stats.averageNoise <= 1.5) return AppColors.noiseQuiet;
    if (stats.averageNoise <= 2.5) return AppColors.noiseModerate;
    return AppColors.noiseLoud;
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerVertical() {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }

  // ─────────────────── 전체 모드 전용 ───────────────────

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '로그인이 필요합니다',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '리뷰를 작성하려면 로그인이 필요합니다.\n로그인 화면으로 이동하시겠습니까?',
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
              context.push('/login');
            },
            child: const Text(
              '로그인',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(
      BuildContext context, WidgetRef ref, CafeReviewStats stats) {
    final isLoggedIn = ref.watch(authStateProvider).value != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (stats.reviewCount > 0) ...[
            const Icon(Icons.star, size: 20, color: Color(0xFFFFB800)),
            const SizedBox(width: 4),
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text('(${stats.reviewCount})', style: AppTextStyles.bodySmall),
          ] else ...[
            const Icon(Icons.star_outline,
                size: 20, color: AppColors.crowdUnknown),
            const SizedBox(width: 8),
            Text(
              '아직 리뷰가 없습니다',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () async {
                if (!isLoggedIn) {
                  _showLoginRequiredDialog(context);
                  return;
                }
                final result = await ReviewWriteSheet.show(
                    context, place.name, _cafeId);
                if (result == true && context.mounted) {
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('리뷰가 등록되었습니다')),
                    );
                    show(context, place);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
              ),
              child: Text(
                '리뷰 쓰기',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(
    BuildContext context,
    AsyncValue<List<ReviewModel>> reviewsAsync,
  ) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        final displayReviews = reviews.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('최근 리뷰', style: AppTextStyles.labelMedium),
                const SizedBox(width: 6),
                Text(
                  '${reviews.length}개',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...displayReviews
                .map((review) => _buildReviewItem(review, context)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
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
      error: (e, s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '리뷰를 불러오지 못했습니다',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review, BuildContext context) {
    final dateStr = DateFormat('yyyy.MM.dd').format(review.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: i < review.rating
                            ? const Color(0xFFFFB800)
                            : AppColors.secondaryDark,
                      )),
              const SizedBox(width: 8),
              Text(review.userName, style: AppTextStyles.caption),
              const Spacer(),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildReviewTag(review.crowdLevel.label),
              const SizedBox(width: 6),
              _buildReviewTag(review.outletLevel.label),
              const SizedBox(width: 6),
              _buildReviewTag(review.noiseLevel.label),
            ],
          ),
          if (review.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.content,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                )),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (c, i) => const SizedBox(width: 6),
                itemBuilder: (_, index) => GestureDetector(
                  onTap: () => _showFullScreenPhoto(
                    context,
                    review.photoUrls,
                    index,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      review.photoUrls[index],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.secondary,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                          size: 20,
                        ),
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

  void _showFullScreenPhoto(
    BuildContext context,
    List<String> photoUrls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenPhotoViewer(
          photoUrls: photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildReviewTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDirectionsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _openInNaverMap(),
        icon: const Icon(Icons.open_in_new, color: AppColors.textOnPrimary),
        label: const Text('네이버 지도에서 보기', style: AppTextStyles.button),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openInNaverMap() async {
    final naverAppUri = Uri.parse(
      'nmap://place?lat=${place.lat}&lng=${place.lng}'
      '&name=${Uri.encodeComponent(place.name)}'
      '&appname=com.yjh.kagong.kagongMap',
    );
    final webUri = Uri.parse(
      'https://map.naver.com/v5/search/${Uri.encodeComponent(place.name)}',
    );

    if (await canLaunchUrl(naverAppUri)) {
      await launchUrl(naverAppUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 전체 화면 사진 뷰어
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: widget.photoUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.photoUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : null,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (_, index) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: Image.network(
              widget.photoUrls[index],
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white54,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

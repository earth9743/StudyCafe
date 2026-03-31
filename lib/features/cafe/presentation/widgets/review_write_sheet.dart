import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';
import 'package:kagong_map/features/cafe/providers/review_provider.dart';

/// 리뷰 작성 Bottom Sheet
class ReviewWriteSheet extends ConsumerStatefulWidget {
  final String cafeName;
  final String cafeId;

  const ReviewWriteSheet({
    super.key,
    required this.cafeName,
    required this.cafeId,
  });

  static Future<bool?> show(
      BuildContext context, String cafeName, String cafeId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewWriteSheet(cafeName: cafeName, cafeId: cafeId),
    );
  }

  @override
  ConsumerState<ReviewWriteSheet> createState() => _ReviewWriteSheetState();
}

class _ReviewWriteSheetState extends ConsumerState<ReviewWriteSheet>
    with WidgetsBindingObserver {
  int _rating = 3;
  CrowdLevel _crowdLevel = CrowdLevel.moderate;
  OutletLevel _outletLevel = OutletLevel.moderate;
  NoiseLevel _noiseLevel = NoiseLevel.moderate;
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();
  final _submitKey = GlobalKey();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _submitKey.currentContext == null) return;
        Scrollable.ensureVisible(
          _submitKey.currentContext!,
          duration: Duration.zero, // 즉시 이동, 애니메이션 충돌 없음
        );
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final success = await ref.read(reviewSubmitProvider.notifier).submitReview(
          cafeId: widget.cafeId,
          rating: _rating,
          crowdLevel: _crowdLevel,
          outletLevel: _outletLevel,
          noiseLevel: _noiseLevel,
          content: _contentController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 저장에 실패했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: bottomInset > 0
              ? screenHeight - bottomInset - topPadding
              : screenHeight * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondaryDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 스크롤 가능한 본문 (버튼 포함)
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, bottomInset > 0 ? 12 : bottomPadding + 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('리뷰 작성', style: AppTextStyles.h4),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(widget.cafeName,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 20),

                    // 별점
                    _buildSectionLabel('별점'),
                    const SizedBox(height: 8),
                    _buildStarRating(),
                    const SizedBox(height: 20),

                    // 혼잡도
                    _buildSectionLabel('혼잡도'),
                    const SizedBox(height: 8),
                    _buildSegmentedSelector<CrowdLevel>(
                      values: CrowdLevel.values,
                      selected: _crowdLevel,
                      labelOf: (v) => v.label,
                      colorOf: (v) {
                        switch (v) {
                          case CrowdLevel.low:
                            return AppColors.crowdLow;
                          case CrowdLevel.moderate:
                            return AppColors.crowdModerate;
                          case CrowdLevel.high:
                            return AppColors.crowdHigh;
                        }
                      },
                      onChanged: (v) => setState(() => _crowdLevel = v),
                    ),
                    const SizedBox(height: 16),

                    // 콘센트
                    _buildSectionLabel('콘센트'),
                    const SizedBox(height: 8),
                    _buildSegmentedSelector<OutletLevel>(
                      values: OutletLevel.values,
                      selected: _outletLevel,
                      labelOf: (v) => v.label,
                      colorOf: (v) {
                        switch (v) {
                          case OutletLevel.many:
                            return AppColors.outletAvailable;
                          case OutletLevel.moderate:
                            return AppColors.outletLimited;
                          case OutletLevel.few:
                            return AppColors.outletUnavailable;
                        }
                      },
                      onChanged: (v) => setState(() => _outletLevel = v),
                    ),
                    const SizedBox(height: 16),

                    // 소음
                    _buildSectionLabel('소음'),
                    const SizedBox(height: 8),
                    _buildSegmentedSelector<NoiseLevel>(
                      values: NoiseLevel.values,
                      selected: _noiseLevel,
                      labelOf: (v) => v.label,
                      colorOf: (v) {
                        switch (v) {
                          case NoiseLevel.quiet:
                            return AppColors.noiseQuiet;
                          case NoiseLevel.moderate:
                            return AppColors.noiseModerate;
                          case NoiseLevel.loud:
                            return AppColors.noiseLoud;
                        }
                      },
                      onChanged: (v) => setState(() => _noiseLevel = v),
                    ),
                    const SizedBox(height: 20),

                    // 텍스트 리뷰
                    _buildSectionLabel('한줄 리뷰 (선택)'),
                    const SizedBox(height: 8),
                    CupertinoTheme(
                      data: const CupertinoThemeData(
                        primaryColor: AppColors.textPrimary,
                      ),
                      child: TextField(
                        controller: _contentController,
                        focusNode: _focusNode,
                        maxLength: 500,
                        maxLines: 3,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                        hintText: '카페에 대한 후기를 남겨주세요',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textHint),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 제출 버튼
                    SizedBox(
                      key: _submitKey,
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('리뷰 등록',
                                style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: AppTextStyles.labelMedium);
  }

  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => setState(() => _rating = starIndex),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              starIndex <= _rating ? Icons.star : Icons.star_border,
              color: starIndex <= _rating
                  ? const Color(0xFFFFB800)
                  : AppColors.secondaryDark,
              size: 36,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSegmentedSelector<T>({
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required Color Function(T) colorOf,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: values.map((value) {
        final isSelected = value == selected;
        final color = colorOf(value);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              margin:
                  EdgeInsets.only(right: value != values.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                labelOf(value),
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

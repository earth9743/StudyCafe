import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';
import 'package:kagong_map/features/cafe/providers/review_provider.dart';

/// 리뷰에 첨부할 수 있는 최대 사진 수
const _kMaxPhotos = 5;

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

  /// 사용자가 선택한 이미지 파일 목록
  final List<File> _selectedImages = [];
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contentController.addListener(() {
      // 글자 수 카운터 실시간 업데이트
      setState(() {});
    });
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
          duration: Duration.zero,
        );
      });
    }
  }

  bool _isPicking = false;

  /// 갤러리에서 이미지를 선택한다. 최대 [_kMaxPhotos]장까지 허용.
  Future<void> _pickImages() async {
    if (_isPicking) return;
    _isPicking = true;

    final remaining = _kMaxPhotos - _selectedImages.length;
    if (remaining <= 0) {
      _isPicking = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 최대 $_kMaxPhotos장까지 추가할 수 있습니다')),
      );
      return;
    }

    try {
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (picked.isEmpty) {
        _isPicking = false;
        return;
      }

      final filesToAdd = picked
          .take(remaining)
          .map((xFile) => File(xFile.path))
          .toList();

      setState(() {
        _selectedImages.addAll(filesToAdd);
      });

      // 초과 선택 시 안내
      if (picked.length > remaining) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '최대 $_kMaxPhotos장까지만 추가됩니다. ${picked.length - remaining}장이 제외되었습니다.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ReviewWriteSheet] 이미지 선택 실패: $e');
    } finally {
      _isPicking = false;
    }
  }

  /// 선택된 이미지를 제거한다.
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
          imageFiles: _selectedImages,
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

                    // 한줄 리뷰 + 사진 첨부 (통합 컨테이너)
                    _buildSectionLabel('한줄 리뷰 (선택)'),
                    const SizedBox(height: 8),
                    _buildReviewInputBox(),
                    const SizedBox(height: 20),

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
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedImages.isNotEmpty
                                        ? '사진 업로드 중...'
                                        : '등록 중...',
                                    style: AppTextStyles.button,
                                  ),
                                ],
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

  /// 텍스트 입력 + 사진 첨부를 하나의 박스로 통합
  Widget _buildReviewInputBox() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 텍스트 입력 영역
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
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                counterText: '',
              ),
            ),
          ),

          // 선택된 사진 미리보기 (있을 때만)
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, index) =>
                      _buildPhotoThumbnail(_selectedImages[index], index),
                ),
              ),
            ),

          // 하단 툴바: 사진 추가 버튼 + 카운터
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _selectedImages.length < _kMaxPhotos
                      ? _pickImages
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: _selectedImages.length < _kMaxPhotos
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '사진 ${_selectedImages.length}/$_kMaxPhotos',
                        style: AppTextStyles.caption.copyWith(
                          color: _selectedImages.length < _kMaxPhotos
                              ? AppColors.textSecondary
                              : AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_contentController.text.length}/500',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 사진 썸네일 (X 삭제 버튼 포함)
  Widget _buildPhotoThumbnail(File file, int index) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
          ),
        ],
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


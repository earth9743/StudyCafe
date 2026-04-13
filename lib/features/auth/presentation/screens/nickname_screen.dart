import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';

/// 회원가입 시 닉네임 설정 화면
class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isChecking = false;
  bool _isAvailable = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNicknameChanged(String value) {
    _debounce?.cancel();

    final trimmed = value.trim();

    // 즉시 로컬 검증
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = null;
        _isAvailable = false;
        _isChecking = false;
      });
      return;
    }

    if (trimmed.length < 3) {
      setState(() {
        _errorText = '닉네임은 최소 3글자 이상이어야 합니다.';
        _isAvailable = false;
        _isChecking = false;
      });
      return;
    }

    if (trimmed.length > 12) {
      setState(() {
        _errorText = '닉네임은 12글자 이하여야 합니다.';
        _isAvailable = false;
        _isChecking = false;
      });
      return;
    }

    // 서버 중복 체크 (디바운스 500ms)
    setState(() {
      _isChecking = true;
      _errorText = null;
      _isAvailable = false;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final authRepo = ref.read(authRepositoryProvider);
      final available = await authRepo.isNicknameAvailable(trimmed);

      if (mounted && _controller.text.trim() == trimmed) {
        setState(() {
          _isChecking = false;
          if (available) {
            _isAvailable = true;
            _errorText = null;
          } else {
            _isAvailable = false;
            _errorText = '이미 사용 중인 닉네임입니다.';
          }
        });
      }
    });
  }

  Future<void> _saveNickname() async {
    final nickname = _controller.text.trim();
    if (nickname.length < 3 || !_isAvailable) return;

    try {
      await ref.read(authControllerProvider.notifier).saveNickname(nickname);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('닉네임 저장에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _isAvailable && !_isChecking && _errorText == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('닉네임 설정'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              '카공지도에서 사용할\n닉네임을 설정해주세요',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 사용자에게 보이는 이름이며, 리뷰 작성 시 표시됩니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              onChanged: _onNicknameChanged,
              maxLength: 12,
              decoration: InputDecoration(
                labelText: '닉네임',
                hintText: '3~12글자로 입력해주세요',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                errorText: _errorText,
                suffixIcon: _isChecking
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _isAvailable
                        ? const Icon(Icons.check_circle,
                            color: Colors.green)
                        : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isAvailable
                        ? Colors.green
                        : AppColors.divider,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isAvailable
                        ? Colors.green
                        : AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
            ),
            if (_isAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  '사용 가능한 닉네임입니다.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.green,
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canSubmit ? _saveNickname : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '시작하기',
                  style: AppTextStyles.button,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

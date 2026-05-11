import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_event.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_state.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key, required this.email});
  final String email;

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  static const int _length = 6;
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _syncCooldownFromState();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncCooldownFromState() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthOtpPending) {
      _startCountdown(state.cooldownUntil);
    }
  }

  void _startCountdown(DateTime until) {
    _ticker?.cancel();
    void tick() {
      if (!mounted) return;
      final left = until.difference(DateTime.now());
      setState(() {
        _remaining = left.isNegative ? Duration.zero : left;
      });
      if (left.isNegative) _ticker?.cancel();
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _onCodeChanged(String value) {
    if (value.length == _length) {
      _submit();
    }
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length != _length) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthOtpVerifyRequested(email: widget.email, code: code),
    );
  }

  void _resend() {
    context.read<AuthBloc>().add(AuthOtpResendRequested(widget.email));
  }

  void _back() {
    context.read<AuthBloc>().add(const AuthOtpReset());
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (a, b) =>
            a.runtimeType != b.runtimeType ||
            (a is AuthOtpPending &&
                b is AuthOtpPending &&
                a.cooldownUntil != b.cooldownUntil),
        listener: (context, state) {
          if (state is AuthLoaded) {
            context.go('/main');
            return;
          }
          if (state is AuthOtpPending) {
            _startCountdown(state.cooldownUntil);
            if (state.justResent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Code resent. Check your email.'),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        child: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final pending = state is AuthOtpPending ? state : null;
              final verifying = pending?.verifying ?? false;
              final resending = pending?.resending ?? false;
              final error = pending?.error;
              final canResend = _remaining == Duration.zero && !resending;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onBack: _back),
                    const SizedBox(height: 28),
                    const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.primary,
                      size: 56,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Verify your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a 6-digit code to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _OtpField(
                      controller: _controller,
                      focusNode: _focus,
                      length: _length,
                      onChanged: _onCodeChanged,
                      hasError: error != null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: verifying ? null : _submit,
                        child: verifying
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text('Verify'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive code?",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: canResend ? _resend : null,
                          child: Text(
                            resending
                                ? 'Sending...'
                                : canResend
                                    ? 'Resend'
                                    : 'Resend in ${_remaining.inSeconds}s',
                            style: TextStyle(
                              color: canResend
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        const Text(
          'Soplay',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onChanged,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(length),
            ],
            onChanged: onChanged,
            autofillHints: const [AutofillHints.oneTimeCode],
            enableInteractiveSelection: false,
            showCursor: false,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final value = controller.text;
            return GestureDetector(
              onTap: () => focusNode.requestFocus(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(length, (i) {
                  final ch = i < value.length ? value[i] : '';
                  final isFocused = focusNode.hasFocus && i == value.length;
                  return _OtpCell(
                    char: ch,
                    isFocused: isFocused,
                    hasError: hasError,
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.char,
    required this.isFocused,
    required this.hasError,
  });

  final String char;
  final bool isFocused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : isFocused
            ? AppColors.primary
            : AppColors.border;
    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isFocused || hasError ? 1.6 : 0.8,
        ),
      ),
      child: Text(
        char,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ExitGuard extends StatefulWidget {
  const ExitGuard({
    super.key,
    required this.child,
    this.blockWhen = false,
    this.hintText = 'กดปุ่มย้อนกลับอีกครั้งเพื่อออก',
    this.cooldown = const Duration(seconds: 2),
    this.onBlocked,
  });

  final Widget child;
  final bool blockWhen;
  final String hintText;
  final Duration cooldown;
  final VoidCallback? onBlocked;

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  DateTime? _lastBack;
  Future<bool> _onWillPop() async {
    if (widget.blockWhen) {
      widget.onBlocked?.call();
      return false;
    }

    final now = DateTime.now();
    final firstOrCooldownPassed =
        _lastBack == null || now.difference(_lastBack!) > widget.cooldown;

    if (firstOrCooldownPassed) {
      _lastBack = now;
      HapticFeedback.selectionClick();
      showGlassHint(widget.hintText);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);

        final shouldExit = await _onWillPop();
        if (!shouldExit) return;

        if (!mounted) return;

        if (nav.canPop()) {
          nav.pop(result);
        } else {
          SystemNavigator.pop();
        }
      },

      child: widget.child,
    );
  }
}

OverlayEntry? _glassHintEntry;

void showGlassHint(
  String message, {
  Duration duration = const Duration(milliseconds: 1400),
  IconData? icon = Icons.info_rounded,
  EdgeInsets safeMargin = const EdgeInsets.only(bottom: 90),
}) {
  _glassHintEntry?.remove();
  _glassHintEntry = null;

  final context = Get.overlayContext ?? Get.context;
  if (context == null) return;

  final overlay = Overlay.of(context, rootOverlay: true);

  final entry = OverlayEntry(
    builder: (_) => _GlassHintWidget(
      message: message,
      icon: icon,
      duration: duration,
      safeMargin: safeMargin,
      onDone: () {
        _glassHintEntry?.remove();
        _glassHintEntry = null;
      },
    ),
  );

  overlay.insert(entry);
  _glassHintEntry = entry;
}

class _GlassHintWidget extends StatefulWidget {
  const _GlassHintWidget({
    required this.message,
    required this.duration,
    required this.onDone,
    this.icon,
    required this.safeMargin,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDone;
  final IconData? icon;
  final EdgeInsets safeMargin;

  @override
  State<_GlassHintWidget> createState() => _GlassHintWidgetState();
}

class _GlassHintWidgetState extends State<_GlassHintWidget> {
  double _opacity = 0;
  double _scale = 0.94;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _opacity = 1;
        _scale = 1.0;
      });
    });

    _timer = Timer(widget.duration, () async {
      if (!mounted) return;
      setState(() {
        _opacity = 0;
        _scale = 0.98;
      });
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        bottom: true,
        child: Container(
          alignment: Alignment.bottomCenter,
          margin: widget.safeMargin,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: _opacity),
            builder: (_, t, child) {
              final s = lerpDouble(0.94, _scale, t)!;
              return Transform.scale(
                scale: s,
                child: Opacity(opacity: t, child: child),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.50),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        if (widget.icon != null)
                          Icon(widget.icon, size: 18, color: Colors.white),
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: GoogleFonts.notoSansThai(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            decoration: TextDecoration.none,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Design system for Boxing Interval Timer — 1:1 port of the iOS
// "Bold / Athletic" DesignSystem.swift (forced dark, phase-colored
// backgrounds, Nunito as the SF Rounded substitute).
//
// All tokens are the exact HEX values from the iOS app so both platforms
// look identical. No Material light chrome, no system blue.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:boxing_timer_flutter/core/models.dart';

// ============================================================================
// Design tokens
// ============================================================================

class DS {
  DS._();

  // Surfaces / base (for non-phase screens: config, settings, history, …)
  static const Color bg = Color(0xFF0E0E11); // deep near-black
  static const Color surface = Color(0xFF1B1C20); // cards
  static const Color surfaceHi = Color(0xFF26272C); // elevated card / control

  // Phase colors (full-bleed timer background).
  static const Color phaseRound = Color(0xFF18A957); // green — round
  static const Color phaseRest = Color(0xFFDC3B3B); // red — rest
  static const Color phaseWarm = Color(0xFF3A3B40); // gray — warmup/cooldown
  static const Color phaseDone = Color(0xFF2E6BE6); // blue — finished

  // Accent
  static const Color accent = Color(0xFFFF7A1A); // energetic orange

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0x9EFFFFFF); // white 62%
  static const Color textTertiary = Color(0x66FFFFFF); // white 40%
  static const Color divider = Color(0x1AFFFFFF); // white 10%

  // Controls on colored backgrounds
  static const Color controlFill = Color(0x38000000); // black 22%
  static const Color controlStroke = Color(0x40FFFFFF); // white 25%

  // Radii
  static const double radiusChip = 12;
  static const double radiusCard = 16;
  static const double radiusPill = 16;

  // Spacing
  static const double spaceXs = 6;
  static const double spaceS = 10;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXl = 32;

  // Type — iOS uses SF Rounded; Nunito is the cross-platform equivalent.
  // Weight mapping: .black=w900, .heavy=w800, .bold=w700, .medium=w500.
  static TextStyle timer(double size) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.1,
      );

  static TextStyle display([double size = 28]) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      );

  static TextStyle headline([double size = 18]) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle body([double size = 16]) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  /// Background color follows the timer PHASE (not run state).
  static Color phaseColor(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.warmup:
      case TimerPhase.cooldown:
        return phaseWarm;
      case TimerPhase.round:
        return phaseRound;
      case TimerPhase.rest:
        return phaseRest;
      case TimerPhase.finished:
        return phaseDone;
    }
  }
}

// ============================================================================
// AthleticBackground — phase color + dark vertical gradient for depth
// ============================================================================

class AthleticBackground extends StatelessWidget {
  const AthleticBackground({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          color: color,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x0D000000), // black 5%
                Color(0x61000000), // black 38%
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ============================================================================
// DSTimerDial — phase label + progress ring + large time
// ============================================================================

class DSTimerDial extends StatelessWidget {
  const DSTimerDial({
    super.key,
    required this.phaseText,
    required this.timeString,
    required this.progress,
    required this.diameter,
  });

  final String phaseText;
  final String timeString;
  final double progress;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            phaseText.toUpperCase(),
            maxLines: 1,
            style: DS.display(28).copyWith(letterSpacing: 2),
          ),
        ),
        const SizedBox(height: DS.spaceM),
        SizedBox(
          width: diameter,
          height: diameter,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: clamped, end: clamped),
            duration: const Duration(milliseconds: 500),
            curve: Curves.linear,
            builder: (context, animatedProgress, child) {
              return CustomPaint(
                painter: _DialRingPainter(progress: animatedProgress),
                child: child,
              );
            },
            child: Center(
              child: SizedBox(
                width: diameter * 0.86,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    timeString,
                    maxLines: 1,
                    style: DS.timer(math.min(94, diameter * 0.30)).copyWith(
                      shadows: const [
                        Shadow(
                          color: Color(0x40000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialRingPainter extends CustomPainter {
  const _DialRingPainter({required this.progress});

  final double progress;

  static const double _strokeWidth = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - _strokeWidth) / 2;

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = const Color(0x2EFFFFFF); // white 18%
    canvas.drawCircle(center, radius, track);

    if (progress > 0.001) {
      final Paint arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_DialRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// Controls
// ============================================================================

/// Secondary circular control (62dp, controlFill + 1.5dp controlStroke).
class DSCircleButton extends StatelessWidget {
  const DSCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Material(
        color: DS.controlFill,
        shape: const CircleBorder(
          side: BorderSide(color: DS.controlStroke, width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Big white play/pause circle (92dp, black glyph, shadow).
class DSPlayPauseButton extends StatelessWidget {
  const DSPlayPauseButton({
    super.key,
    required this.isRunning,
    required this.onPressed,
  });

  final bool isRunning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 48,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

/// White pill primary button with black bold UPPERCASE label.
/// A null [onPressed] renders the disabled style.
class DSPrimaryButton extends StatelessWidget {
  const DSPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusPill),
        child: InkWell(
          borderRadius: BorderRadius.circular(DS.radiusPill),
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Black-translucent capsule chip with white content.
class DSChip extends StatelessWidget {
  const DSChip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: DS.controlFill,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: IconTheme.merge(
        data: const IconThemeData(color: Colors.white),
        child: DefaultTextStyle.merge(
          style: DS.body().copyWith(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}

/// Dark card (config/settings/history sections).
class DSCard extends StatelessWidget {
  const DSCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(DS.spaceM),
      decoration: BoxDecoration(
        color: DS.surface,
        borderRadius: BorderRadius.circular(DS.radiusCard),
      ),
      child: child,
    );
  }
}

/// Custom segmented picker (selected = white pill with black text).
class DSSegmentedPicker<T> extends StatelessWidget {
  const DSSegmentedPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DS.surfaceHi,
        borderRadius: BorderRadius.circular(DS.radiusChip),
      ),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _segment(options[i])),
          ],
        ],
      ),
    );
  }

  Widget _segment((T, String) option) {
    final bool isSelected = option.$1 == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(option.$1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              option.$2,
              maxLines: 1,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.black : DS.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable card (full readable label; replaces cramped segmented options).
class DSSelectableCard extends StatelessWidget {
  const DSSelectableCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x33FF7A1A) : DS.surfaceHi,
          borderRadius: BorderRadius.circular(DS.radiusChip),
          border: Border.all(
            color: isSelected ? DS.accent : DS.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        // FittedBox scales the whole label down to fit one line instead of
        // wrapping — a fixed font size would force a mid-word break on long
        // translations (e.g. German "Fortgeschritten") with no space to
        // wrap at. This keeps every language on one readable line.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : DS.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Stepper row: label (white) — value+unit (secondary) — round -/+ buttons
/// with accent glyphs (ports the iOS `Stepper(...).tint(DS.accent)` row).
class DSStepperRow extends StatelessWidget {
  const DSStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DS.spaceM,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DS.body(),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$value$unit',
              textAlign: TextAlign.end,
              maxLines: 1,
              style: DS.body().copyWith(color: DS.textSecondary),
            ),
          ),
          const SizedBox(width: DS.spaceS),
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged((value - step).clamp(min, max)),
          ),
          const SizedBox(width: DS.spaceXs),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: DS.surfaceHi,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: enabled ? DS.accent : DS.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

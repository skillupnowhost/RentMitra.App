import 'dart:async';

import 'package:flutter/material.dart';

/// Generic "enter once, replay on re-activation" fade + slide-up wrapper.
///
/// Used to stagger a slide's description / feature row / product art /
/// caption in behind its headline. Driven by [active] rather than its own
/// lifecycle so it can be reused inside a [PageView] page that stays
/// mounted the whole time — it replays every time the page becomes current
/// again (including on the auto-play carousel's loop-around).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.active,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
    this.duration = const Duration(milliseconds: 520),
  });

  final bool active;
  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant FadeSlideIn old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _play();
    } else if (!widget.active && old.active) {
      _delayTimer?.cancel();
      _controller.value = 0;
    }
  }

  void _play() {
    _delayTimer?.cancel();
    if (widget.delay == Duration.zero) {
      _controller.forward(from: 0);
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// One pre-styled line of a [CinematicHeading].
class HeadlineLine {
  const HeadlineLine(this.text, this.style);

  final String text;
  final TextStyle style;
}

/// Cinematic headline: each word fades and lifts into place in a short
/// left-to-right stagger, replaying whenever [active] flips from false to
/// true (including the carousel's loop-around) — the "letter reveal /
/// smooth fade-up" entrance called for by the design brief, scoped to
/// whole words rather than individual glyphs so it stays cheap on real
/// devices (no per-character layout/paint).
class CinematicHeading extends StatefulWidget {
  const CinematicHeading({
    super.key,
    required this.active,
    required this.lines,
    this.textAlign = TextAlign.center,
  });

  final bool active;
  final List<HeadlineLine> lines;
  final TextAlign textAlign;

  @override
  State<CinematicHeading> createState() => _CinematicHeadingState();
}

class _CinematicHeadingState extends State<CinematicHeading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CinematicHeading old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _controller.forward(from: 0);
    } else if (!widget.active && old.active) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordGroups = [for (final l in widget.lines) l.text.split(' ')];
    final totalWords = wordGroups.fold<int>(0, (a, b) => a + b.length);
    var wordIndex = 0;

    return Column(
      crossAxisAlignment: widget.textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        for (var li = 0; li < widget.lines.length; li++)
          Wrap(
            alignment: widget.textAlign == TextAlign.center
                ? WrapAlignment.center
                : WrapAlignment.start,
            spacing: 6,
            children: [
              for (final word in wordGroups[li])
                _RevealWord(
                  key: ValueKey('$li-$word-$wordIndex'),
                  word: word,
                  style: widget.lines[li].style,
                  controller: _controller,
                  start: totalWords == 0
                      ? 0.0
                      : (wordIndex++ / totalWords) * 0.55,
                ),
            ],
          ),
      ],
    );
  }
}

class _RevealWord extends StatelessWidget {
  const _RevealWord({
    super.key,
    required this.word,
    required this.style,
    required this.controller,
    required this.start,
  });

  final String word;
  final TextStyle style;
  final AnimationController controller;
  final double start;

  @override
  Widget build(BuildContext context) {
    final end = (start + 0.45).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 14),
            child: child,
          ),
        );
      },
      child: Text(word, style: style),
    );
  }
}

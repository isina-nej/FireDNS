import 'package:flutter/material.dart';

class AnimatedOverflowLabel extends StatefulWidget {
  final String label;
  final double width;
  final TextStyle style;
  const AnimatedOverflowLabel({
    required this.label,
    required this.width,
    required this.style,
  });

  @override
  State<AnimatedOverflowLabel> createState() => _AnimatedOverflowLabelState();
}

class _AnimatedOverflowLabelState extends State<AnimatedOverflowLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double textWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textPainter = TextPainter(
        text: TextSpan(text: widget.label, style: widget.style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      setState(() {
        textWidth = textPainter.width;
      });
      if (textWidth > widget.width) {
        _controller.repeat(reverse: false);
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (textWidth <= widget.width) {
      return Text(widget.label, style: widget.style);
    }
    final overflow = textWidth - widget.width;
    return SizedBox(
      width: widget.width,
      height: widget.style.fontSize! * 1.2,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final offset = -overflow * _animation.value;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.08, 0.92, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Text(
                widget.label,
                style: widget.style,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

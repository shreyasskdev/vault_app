import 'package:flutter/material.dart';

class TouchableButton extends StatefulWidget {
  final Widget? child;
  final Function? onPressed;
  final Duration? duration = const Duration(milliseconds: 50);
  final double? opacity = 0.4;
  final EdgeInsets? padding;
  final Color? color;
  final Color? highlightColor;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double? borderWidth;

  const TouchableButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.all(7),
    this.color = Colors.white,
    this.highlightColor = Colors.transparent,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.borderColor = Colors.grey,
    this.borderWidth = 1,
  });

  @override
  _TouchableButtonState createState() => _TouchableButtonState();
}

class _TouchableButtonState extends State<TouchableButton> {
  bool isDown = false;

  @override
  void initState() {
    super.initState();
    setState(() => isDown = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isDown = true),
      onTapUp: (_) => setState(() => isDown = false),
      onTapCancel: () => setState(() => isDown = false),
      onTap: () => widget.onPressed!(),
      child: Container(
        // decoration: BoxDecoration(
        //   color: widget.highlightColor,
        //   borderRadius: widget.borderRadius,
        // ),
        decoration: ShapeDecoration(
          shape: RoundedSuperellipseBorder(
            side: BorderSide(
              color: widget.borderColor!,
              width: widget.borderWidth!,
            ),
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
          ),
          color: widget.highlightColor,
        ),
        child: AnimatedOpacity(
          duration: widget.duration!,
          opacity: isDown ? widget.opacity! : 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: widget.borderColor!,
                style: BorderStyle.solid,
                width: widget.borderWidth!,
              ),
            ),
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class TouchableOpacity extends StatefulWidget {
  final Widget? child;
  final Function? onPressed;
  final Duration? duration = const Duration(milliseconds: 50);
  final double? opacity = 0.2;

  const TouchableOpacity({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  _TouchableOpacityState createState() => _TouchableOpacityState();
}

class _TouchableOpacityState extends State<TouchableOpacity> {
  bool isDown = false;

  @override
  void initState() {
    super.initState();
    setState(() => isDown = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isDown = true),
      onTapUp: (_) => setState(() => isDown = false),
      onTapCancel: () => setState(() => isDown = false),
      onTap: () => widget.onPressed!(),
      child: AnimatedOpacity(
        duration: widget.duration!,
        opacity: isDown ? widget.opacity! : 1,
        child: widget.child,
      ),
    );
  }
}

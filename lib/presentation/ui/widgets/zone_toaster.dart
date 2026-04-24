import 'dart:async';
import 'package:flutter/material.dart';

enum ZoneUiState { entered, inside, exited }

class ZoneToaster extends StatefulWidget {
  final String? message;
  final ZoneUiState state;

  const ZoneToaster({
    super.key,
    required this.message,
    required this.state,
  });

  @override
  State<ZoneToaster> createState() => _ZoneToasterState();
}

class _ZoneToasterState extends State<ZoneToaster> {
  Timer? _timer;

  String? _visibleMessage;
  ZoneUiState? _visibleState;

  @override
  void didUpdateWidget(covariant ZoneToaster oldWidget) {
    super.didUpdateWidget(oldWidget);

    //  Prevent unnecessary rebuild spam
    if (oldWidget.message == widget.message &&
        oldWidget.state == widget.state) {
      return;
    }

    if (widget.message == null) return;

    _timer?.cancel();

    setState(() {
      _visibleMessage = widget.message;
      _visibleState = widget.state;
    });

    //  Only auto-hide for ENTER / EXIT
    if (widget.state != ZoneUiState.inside) {
      _timer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;

        setState(() {
          _visibleMessage = null;
          _visibleState = null;
        });
      });
    }
  }

  Color _color() {
    switch (_visibleState) {
      case ZoneUiState.entered:
        return Colors.orange;
      case ZoneUiState.inside:
        return Colors.blue;
      case ZoneUiState.exited:
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_visibleMessage == null) return const SizedBox.shrink();

    final color = _color();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_visibleMessage),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _visibleMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
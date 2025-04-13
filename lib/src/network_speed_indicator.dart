import 'dart:async';
import 'package:flutter/material.dart';

class NetworkSpeedIndicator extends StatefulWidget {
  /// Size of the progress indicator
  final double size;

  /// Thickness of the progress bar stroke
  final double strokeWidth;

  /// The color of the progress bar
  final Color progressColor;

  /// The background color of the progress bar
  final Color backgroundColor;

  /// Test duration in milliseconds
  final int testDuration;

  /// Callback when test is complete
  final Function(double)? onTestComplete;

  /// Speed measurement in Mbps
  final double? speed;

  const NetworkSpeedIndicator({
    super.key,
    this.size = 100.0,
    this.strokeWidth = 10.0,
    this.progressColor = Colors.green,
    this.backgroundColor = Colors.grey,
    this.testDuration = 5000,
    this.onTestComplete,
    this.speed,
  });

  @override
  State<NetworkSpeedIndicator> createState() => _NetworkSpeedIndicatorState();
}

class _NetworkSpeedIndicatorState extends State<NetworkSpeedIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  Timer? _speedUpdateTimer;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.testDuration),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onTestComplete != null) {
          widget.onTestComplete!(_currentSpeed);
        }
      }
    });

    if (widget.speed != null) {
      _currentSpeed = widget.speed!;
    }
  }

  @override
  void didUpdateWidget(NetworkSpeedIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speed != oldWidget.speed && widget.speed != null) {
      setState(() {
        _currentSpeed = widget.speed!;
      });
    }
  }

  void startTest() {
    _controller.reset();
    _currentSpeed = 0.0;

    // Simulate speed test updates
    _speedUpdateTimer?.cancel();
    _speedUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          // This would be replaced with actual speed test logic
          // For now, we're simulating random speed updates
          _currentSpeed = (timer.tick * 5.0) % 100;
        });
      }
    });

    _controller.forward();
  }

  void stopTest() {
    _controller.stop();
    _speedUpdateTimer?.cancel();
  }

  @override
  void dispose() {
    _controller.dispose();
    _speedUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: widget.strokeWidth,
                    color: widget.backgroundColor,
                  ),
                  // Animated progress
                  CircularProgressIndicator(
                    value: _progressAnimation.value,
                    strokeWidth: widget.strokeWidth,
                    color: widget.progressColor,
                  ),
                  // Speed text
                  Text(
                    '${_currentSpeed.toStringAsFixed(1)} Mbps',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: startTest,
              child: const Text('Start Test'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: stopTest,
              child: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }
}

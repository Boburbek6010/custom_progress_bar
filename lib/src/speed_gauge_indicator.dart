import 'dart:async';
import 'dart:math' as math;
import 'package:internet_speed_test/callbacks_enum.dart' show SpeedUnit;
import 'package:internet_speed_test/internet_speed_test.dart';
import 'package:flutter/material.dart';

class SpeedGaugeIndicator extends StatefulWidget {
  /// Size of the gauge
  final double size;

  /// Thickness of the gauge arc
  final double arcThickness;

  /// The color gradient for the progress arc
  final List<Color> progressGradient;

  /// The background color of the gauge
  final Color backgroundColor;

  /// Max value on the scale
  final double maxValue;

  /// Test duration in milliseconds
  final int testDuration;

  /// Callback when test is complete
  final Function(double)? onTestComplete;

  /// Current speed value in Mbps
  final double? speed;

  const SpeedGaugeIndicator({
    super.key,
    this.size = 300.0,
    this.arcThickness = 30.0,
    this.progressGradient = const [
      Colors.blue,
      Colors.cyan,
      Colors.greenAccent,
    ],
    this.backgroundColor = const Color(0xFF1F2233),
    this.maxValue = 1000.0,
    this.testDuration = 8000,
    this.onTestComplete,
    this.speed,
  });

  @override
  State<SpeedGaugeIndicator> createState() => _SpeedGaugeIndicatorState();
}

class _SpeedGaugeIndicatorState extends State<SpeedGaugeIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _speedAnimation;
  Timer? _speedUpdateTimer;
  double _currentSpeed = 0.0;
  bool _isTestRunning = false;

  // Scale values for display
  final List<double> _scaleValues = [0, 5, 10, 50, 100, 250, 500, 750, 1000];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.testDuration),
    );

    _speedAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isTestRunning = false;
        });
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
  void didUpdateWidget(SpeedGaugeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speed != oldWidget.speed && widget.speed != null) {
      setState(() {
        _currentSpeed = widget.speed!;
      });
    }
  }

  void startTest() {
    if (_isTestRunning) return;

    setState(() {
      _isTestRunning = true;
    });

    _controller.reset();
    _currentSpeed = 0.0;

    final internetSpeedTest = InternetSpeedTest();

    // Cancel any existing timer
    _speedUpdateTimer?.cancel();

    // Start actual download speed test
    internetSpeedTest.startDownloadTesting(
      onDone: (double transferRate, SpeedUnit unit) {
        if (mounted) {
          setState(() {
            _isTestRunning = false;
            // Convert to Mbps if needed for consistent final result
            _currentSpeed = unit == SpeedUnit.Kbps
                ? transferRate / 1000
                : transferRate;
          });

          // Complete the animation when test is done
          if (_controller.status != AnimationStatus.completed) {
            _controller.forward(from: _controller.value);
          }
        }
      },
      onProgress: (double percent, double transferRate, SpeedUnit unit) {
        if (mounted && _isTestRunning) {
          setState(() {
            // Convert to Mbps if needed for consistent units
            _currentSpeed = unit == SpeedUnit.Kbps
                ? transferRate / 1000
                : transferRate;

            // Update controller to match progress percentage
            if (!_controller.isCompleted) {
              _controller.animateTo(percent / 100);
            }
          });
        }
      },
      onError: (String errorMessage, String speedTestError) {
        if (mounted) {
          setState(() {
            _isTestRunning = false;
          });

          // You might want to add error handling here
          print('Speed test error: $errorMessage, $speedTestError');

          // Complete the animation even on error
          if (_controller.status != AnimationStatus.completed) {
            _controller.forward(from: _controller.value);
          }
        }
      },
    );

    // Optional: Keep a backup timer in case the speed test callbacks are delayed
    // This ensures smooth animation in case of delayed callbacks
    _speedUpdateTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !_isTestRunning) {
        timer.cancel();
        return;
      }

      // This will ensure the controller progresses smoothly regardless of callback frequency
      if (!_controller.isCompleted) {
        setState(() {
          // Only update the controller position, not the speed value
          // The speed value comes from the real speed test
          double progressIncrement = 0.005; // Small increment for smooth animation
          _controller.value = math.min(1.0, _controller.value + progressIncrement);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void stopTest() {
    if (!_isTestRunning) return;

    setState(() {
      _isTestRunning = false;
    });

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
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                ),
              ),

              // Scale values
              ..._buildScaleLabels(),

              // Gauge arc
              AnimatedBuilder(
                animation: _speedAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: GaugePainter(
                      progress: _getGaugeProgress(),
                      arcThickness: widget.arcThickness,
                      progressGradient: widget.progressGradient,
                    ),
                  );
                },
              ),

              // Center speed display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentSpeed.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: widget.size * 0.15,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: Colors.greenAccent,
                        size: widget.size * 0.06,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Mbps',
                        style: TextStyle(
                          fontSize: widget.size * 0.06,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        _buildControlButton(),
      ],
    );
  }

  List<Widget> _buildScaleLabels() {
    final List<Widget> labels = [];
    final radius = widget.size / 2 - widget.arcThickness / 2;

    for (int i = 0; i < _scaleValues.length; i++) {
      final value = _scaleValues[i];
      // Calculate angle: 225° (bottom-left) to -45° (bottom-right) in radians
      final startAngle = -225 * (math.pi / 180);
      final endAngle = 75 * (math.pi / 180);
      final totalAngle = startAngle - endAngle;

      // Calculate position along the arc
      final fraction = i / (_scaleValues.length);
      final angle = startAngle - (fraction * totalAngle);

      // Calculate position
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);

      // Add some padding for the text
      final paddingFactor = 0.70;

      labels.add(
        Positioned(
          left: widget.size / 2 + x * paddingFactor - 15,
          top: widget.size / 2 + y * paddingFactor - 15,
          child: Text(
            value.toInt().toString(),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: widget.size * 0.045,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return labels;
  }

  double _getGaugeProgress() {
    // Map current speed to gauge progress (0-1)
    return math.min(1.0, _currentSpeed / widget.maxValue);
  }

  Widget _buildControlButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isTestRunning ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: _isTestRunning ? stopTest : startTest,
      child: Text(
        _isTestRunning ? 'STOP' : 'GO',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double progress;
  final double arcThickness;
  final List<Color> progressGradient;

  GaugePainter({
    required this.progress,
    required this.arcThickness,
    required this.progressGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - arcThickness / 2;

    // Define the arc angles (from bottom-left to bottom-right, covering 270 degrees)
    final startAngle = -225 * (math.pi / 180);  // 225 degrees in radians
    final fullSweepAngle = 270 * (math.pi / 180);  // 270 degrees in radians
    final currentSweepAngle = fullSweepAngle * progress;

    // Draw background arc (track)
    final trackPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweepAngle,
      false,
      trackPaint,
    );

    // Create gradient for progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: progressGradient,
        startAngle: startAngle,
        endAngle: startAngle + fullSweepAngle,
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcThickness
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.arcThickness != arcThickness;
  }
}
# Custom Progress Bar

A Flutter package providing a customizable animated circular progress indicator for network speed testing in the Move Green application.

## Features

- Animated circular progress indicator
- Real-time speed display
- Customizable appearance (size, colors, thickness)
- Start/stop test functionality
- Completion callback for test results

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  custom_progress_bar:
    git:
      url: https://github.com/yourusername/custom_progress_bar.git
      ref: main
import 'package:custom_progress_bar/custom_progress_bar.dart';

class NetworkTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: NetworkSpeedIndicator(
          size: 150,
          strokeWidth: 10,
          progressColor: Colors.green,
          backgroundColor: Colors.grey.shade300,
          testDuration: 5000,
          onTestComplete: (speed) {
            print('Network test completed: $speed Mbps');
          },
        ),
      ),
    );
  }
}
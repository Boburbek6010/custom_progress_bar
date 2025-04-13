import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'custom_progress_bar.dart';

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SpeedGaugeIndicator(
          size: 400,
          arcThickness: 40,
          progressGradient: const <Color>[
            Colors.blue,
            Colors.cyan,
            Colors.greenAccent,
          ],
          backgroundColor: const Color(0xFF1F2233), // Dark blue background
          maxValue: 700,
          testDuration: 10000,
          onTestComplete: (final double result) {
            log('Speed test complete: $result Mbps');
          },
        ),
      ),
    );
  }
}

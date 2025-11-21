// lib/step_container.dart
import 'package:flutter/material.dart';

class StepContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const StepContainer({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }
}
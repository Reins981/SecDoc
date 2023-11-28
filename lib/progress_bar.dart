import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final ValueNotifier<double> progress;

  const ProgressBar({
    Key? key,
    required this.progress}) : super(key: key);

  @override
  ProgressBarState createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.progress,
      builder: (context, value, child) {
        final normalizedProgress = value / 100; // Normalize in the range 0-1
        return LinearProgressIndicator(
          value: normalizedProgress,
          minHeight: 10,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
        );
      },
    );
  }
}

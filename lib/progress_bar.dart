import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final ValueNotifier<double> downloadProgress;

  const ProgressBar({
    Key? key,
    required this.downloadProgress}) : super(key: key);

  @override
  ProgressBarState createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.downloadProgress,
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          minHeight: 10,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

enum DashboardItemType {
  library,
  upload,
  ai,
}

class DashboardItem {
  final String id;
  final String title;
  final String description;
  final String detailedDescription;
  final String detailedDescriptionAdmin;
  final String buttonText;
  final IconData? icon;
  final dynamic itemType;

  DashboardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.detailedDescription,
    required this.detailedDescriptionAdmin,
    required this.buttonText,
    required this.icon,
    required this.itemType
  });

  /// Return the IconData from the DashboardItem as Icon with default color blue and size 128
  ///
  /// Returns: [Icon]
  Icon getIcon() {
    return Icon(
      icon, // Replace with the desired Google default icon
      size: 120, // Adjust the size as needed
      color: Colors.blue, // Change the color if required
   );
  }
}
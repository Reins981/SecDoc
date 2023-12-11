import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import 'dashboard_item.dart';
import 'dashboard_details.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DashboardSection extends StatefulWidget {

  final DocumentOperations docOperations;

  const DashboardSection({super.key, required this.docOperations});

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {

  late List<DashboardItem> dashboardItems;
  // Global Helper Instance
  final _helper = Helper();

  // Mock news data
  @override
  void initState() {
    super.initState();
    dashboardItems = [
      DashboardItem(
        id: "1",
        title: "Document Library",
        description: "Seamless Access",
        detailedDescription: "Effortlessly access, download, and seamlessly navigate through our comprehensive document library, "
            "\n ensuring easy and efficient management of all your important files.",
        detailedDescriptionAdmin: "Effortlessly access, download, and seamlessly navigate through our comprehensive document library, "
            "\n ensuring easy and efficient management of all your important files.",
        buttonText: "Access Documents Now",
        icon: Icons.folder,
        itemType: DashboardItemType.library
      ),
      DashboardItem(
        id: "2",
        title: "Document Upload",
        description: "Easy Upload",
        detailedDescription: "Empower your solar panel planning by effortlessly uploading your own documents to our cloud, "
          "\nlaying the foundation for personalized solar panel design tailored to your specific needs.",
        detailedDescriptionAdmin: "Empower customer solar panel planning by effortlessly uploading Plans and Offers to our cloud, "
            "\nlaying the foundation for personalized solar panel design tailored to customers specific needs.",
        buttonText: "Upload Documents Now",
        icon: Icons.cloud_upload,
        itemType: DashboardItemType.upload
      ),
      DashboardItem(
          id: "3",
          title: "Solar Insights",
          description: "Gain Performance Forecasts",
          detailedDescription: "Explore tailored forecasts for solar panel performance across diverse environments, configurations, and conditions. "
              "Get detailed insights that enable informed decisions about solar installations by predicting efficiency, energy output, and other critical factors crucial "
              "for optimizing solar projects. "
              "Send us your specifications for personalized forecasts!",
          detailedDescriptionAdmin: "Explore tailored forecasts for solar panel performance across diverse environments, configurations, and conditions. "
              "Get detailed insights that enable informed decisions about solar installations by predicting efficiency, energy output, and other critical factors crucial "
              "for optimizing solar projects. "
              "Send us your specifications for personalized forecasts!",
          buttonText: "Get Forecasts Now",
          icon: Icons.code,
          itemType: DashboardItemType.ai
      )
      // Add more news items as needed
    ];
  }

  int selectedDashboardIndex = 0;

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    widget.docOperations.clearProgressNotifierDict();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard", style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await _handleLogout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView (
        child: Column(
          children: [
            const SizedBox(height: 20),
            DashboardSlider(
              dashboardItems: dashboardItems,
              onDashboardSelected: (index) {
                setState(() {
                  selectedDashboardIndex = index;
                });
              },
              selectedDashboardIndex: selectedDashboardIndex,
            ),
            const SizedBox(height: 20),
            if (selectedDashboardIndex < dashboardItems.length)
              DetailedDashboardPage(
                  dashboardItem: dashboardItems[selectedDashboardIndex],
                  helper: _helper, docOperations: widget.docOperations),
          ],
        ),
      ),
    );
  }
}

class DashboardSlider extends StatelessWidget {
  final List<DashboardItem> dashboardItems;
  final Function(int) onDashboardSelected;
  final int selectedDashboardIndex;

  DashboardSlider({
    required this.dashboardItems,
    required this.onDashboardSelected,
    required this.selectedDashboardIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: CarouselSlider.builder(
        itemCount: dashboardItems.length,
        options: CarouselOptions(
          initialPage: selectedDashboardIndex,
          viewportFraction: (dashboardItems.length > 2) ? 0.5 : 0.9,
          onPageChanged: (index, _) => onDashboardSelected(index),
        ),
        itemBuilder: (context, index, _) {
          return DashboardCard(
            dashboardItem: dashboardItems[index],
          );
        },
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import 'dashboard_item.dart';
import 'dashboard_details.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

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
        description: "Access all your documents..",
        detailedDescription: "Effortlessly access, download, and seamlessly navigate through our comprehensive document library, "
            "\n ensuring easy and efficient management of all your important files.",
        buttonText: "Access your Docs",
        icon: Icons.folder,
        itemType: DashboardItemType.library
      ),
      DashboardItem(
        id: "2",
        title: "Document Upload",
        description: "Upload your documents..",
        detailedDescription: "Empower your solar panel planning by effortlessly uploading your own documents to our cloud, "
          "\nlaying the foundation for personalized solar panel design tailored to your specific needs.",
        buttonText: "Upload your Docs",
        icon: Icons.cloud_upload,
        itemType: DashboardItemType.upload
      ),
      // Add more news items as needed
    ];
  }

  int selectedDashboardIndex = 0;

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    widget.docOperations.clearProgressNotifierDict();

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginScreen(docOperations: widget.docOperations),
    ));
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

  DashboardSlider({required this.dashboardItems, required this.onDashboardSelected, required this.selectedDashboardIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dashboardItems.length,
        controller: PageController(
          initialPage: selectedDashboardIndex,
          viewportFraction: (dashboardItems.length > 2) ? 0.5: 0.9,
        ),
        onPageChanged: onDashboardSelected,
        itemBuilder: (context, index) {
          return DashboardCard(
            dashboardItem: dashboardItems[index],
          );
        },
      ),
    );
  }
}


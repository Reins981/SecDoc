import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardSection extends StatefulWidget {

  const DashboardSection({super.key});

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {

  late List<DashboardItem> dashboardItems;

  // Mock news data
  @override
  void initState() {
    super.initState();
    dashboardItems = [
      DashboardItem(
        id: "1",
        imageUrl: 'assets/news1.jpg',
        date: "10.03.2023",
      ),
      DashboardItem(
        id: "2",
        imageUrl: 'assets/news2.jpg',
        date: "04.06.2021",
      ),
      // Add more news items as needed
    ];
  }

  int selectedDashboardIndex = 0;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Dashboard", style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0)),
        centerTitle: true,
        backgroundColor: const Color(0xFFD2B48C),
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
              DetailedNewsPage(newsItem: dashboardItems[selectedDashboardIndex]),
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
      height: 200,
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


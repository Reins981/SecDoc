import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import 'dashboard_item.dart';
import 'dashboard_details.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'chat_window.dart';

class DashboardSection extends StatefulWidget {

  final DocumentOperations docOperations;

  const DashboardSection({super.key, required this.docOperations});

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> with SingleTickerProviderStateMixin {

  late List<DashboardItem> dashboardItems;
  // Global Helper Instance
  final _helper = Helper();
  late AnimationController _animationController;
  String _userName = '';
  bool _isChatVisible = false;
  int selectedDashboardIndex = 0;

  // Mock news data
  @override
  void initState() {
    super.initState();
    _initializeUser();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    dashboardItems = [
      DashboardItem(
        id: "1",
        title: "Document Library",
        description: "Seamless Access",
        detailedDescription: "Effortlessly access, download, and seamlessly navigate through our comprehensive document library, "
            "\n ensuring easy and efficient management of all your important files.",
        detailedDescriptionAdmin: "Effortlessly access, download, and seamlessly navigate through our comprehensive document library, "
            "\n ensuring easy and efficient management of all your important files.",
        buttonText: "Access Docs Now",
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
        buttonText: "Upload Docs Now",
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeUser() {
    var currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      _userName = currentUser?.displayName ?? currentUser?.email ?? 'User';
    });
  }

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
        title: Text("Dashboard", style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.yellow,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildUserBadge(), // User badge
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
          if (_isChatVisible)
            IntrinsicHeight(
              child: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: ChatWindow(docOperations: widget.docOperations),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildUserBadge() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items in row
        children: [
          Text(
            'Welcome, $_userName',
            style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 1.0
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(child: child, scale: animation);
            },
            child: IconButton(
              key: ValueKey<bool>(_isChatVisible),
              icon: _isChatVisible
                  ? const Icon(Icons.chat_bubble, size: 50, color: Colors.blue)
                  : const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.blue),
              onPressed: () {
                setState(() {
                  _isChatVisible = !_isChatVisible;
                });
              },
            ),
          ),
        ],
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



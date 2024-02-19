import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import 'dashboard_item.dart';
import 'dashboard_details.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'chat_window.dart';
import 'language_service.dart';
import 'text_contents.dart';

class DashboardSection extends StatefulWidget {

  final DocumentOperations docOperations;

  const DashboardSection({super.key, required this.docOperations});

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> with SingleTickerProviderStateMixin {

  List<DashboardItem> dashboardItems = [];
  // Global Helper Instance
  final _helper = Helper();
  late AnimationController _animationController;
  String _userName = '';
  bool _isChatVisible = false;
  int selectedDashboardIndex = 0;
  String _selectedLanguage = 'German';

  String welcomeTextGerman = getTextContentGerman("welcomeText");
  String welcomeTextEnglish = getTextContentEnglish("welcomeText");
  String dashboardTitle1German = getTextContentGerman("dashboardTitle1");
  String dashboardTitle1English = getTextContentEnglish("dashboardTitle1");
  String dashboardTitle2German = getTextContentGerman("dashboardTitle2");
  String dashboardTitle2English = getTextContentEnglish("dashboardTitle2");
  String dashboardTitle3German = getTextContentGerman("dashboardTitle3");
  String dashboardTitle3English = getTextContentEnglish("dashboardTitle3");
  String dashboardDescription1German = getTextContentGerman("dashboardDescription1");
  String dashboardDescription1English = getTextContentEnglish("dashboardDescription1");
  String dashboardDescription2German = getTextContentGerman("dashboardDescription2");
  String dashboardDescription2English = getTextContentEnglish("dashboardDescription2");
  String dashboardDescription3German = getTextContentGerman("dashboardDescription3");
  String dashboardDescription3English = getTextContentEnglish("dashboardDescription3");
  String dashboardDetailedDescription1German = getTextContentGerman("dashboardDetailedDescription1");
  String dashboardDetailedDescription1English = getTextContentEnglish("dashboardDetailedDescription1");
  String dashboardDetailedDescription2German = getTextContentGerman("dashboardDetailedDescription2");
  String dashboardDetailedDescription2English = getTextContentEnglish("dashboardDetailedDescription2");
  String dashboardDetailedDescription3German = getTextContentGerman("dashboardDetailedDescription3");
  String dashboardDetailedDescription3English = getTextContentEnglish("dashboardDetailedDescription3");
  String dashboardDetailedDescriptionAdmin1German = getTextContentGerman("dashboardDetailedDescriptionAdmin1");
  String dashboardDetailedDescriptionAdmin1English = getTextContentEnglish("dashboardDetailedDescriptionAdmin1");
  String dashboardDetailedDescriptionAdmin2German = getTextContentGerman("dashboardDetailedDescriptionAdmin2");
  String dashboardDetailedDescriptionAdmin2English = getTextContentEnglish("dashboardDetailedDescriptionAdmin2");
  String dashboardDetailedDescriptionAdmin3German = getTextContentGerman("dashboardDetailedDescriptionAdmin3");
  String dashboardDetailedDescriptionAdmin3English = getTextContentEnglish("dashboardDetailedDescriptionAdmin3");
  String dashboardButtonText1German = getTextContentGerman("dashboardButtonText1");
  String dashboardButtonText1English = getTextContentEnglish("dashboardButtonText1");
  String dashboardButtonText2German = getTextContentGerman("dashboardButtonText2");
  String dashboardButtonText2English = getTextContentEnglish("dashboardButtonText2");
  String dashboardButtonText3German = getTextContentGerman("dashboardButtonText3");
  String dashboardButtonText3English = getTextContentEnglish("dashboardButtonText3");



  // Mock news data
  @override
  void initState() {
    super.initState();
    _initializeUser();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadLanguage().then((_) {
      setState(() {
        dashboardItems = [
          DashboardItem(
            id: "1",
            title: _selectedLanguage == 'German' ? dashboardTitle1German: dashboardTitle1English,
            description: _selectedLanguage == 'German' ? dashboardDescription1German : dashboardDescription1English,
            detailedDescription: _selectedLanguage == 'German' ? dashboardDetailedDescription1German : dashboardDetailedDescription1English,
            detailedDescriptionAdmin: _selectedLanguage == 'German' ? dashboardDetailedDescriptionAdmin1German : dashboardDetailedDescriptionAdmin1English,
            buttonText: _selectedLanguage == 'German' ? dashboardButtonText1German : dashboardButtonText1English,
            icon: Icons.folder,
            itemType: DashboardItemType.library
          ),
          DashboardItem(
            id: "2",
            title: _selectedLanguage == 'German' ? dashboardTitle2German: dashboardTitle2English,
            description: _selectedLanguage == 'German' ? dashboardDescription2German : dashboardDescription2English,
            detailedDescription: _selectedLanguage == 'German' ? dashboardDetailedDescription2German : dashboardDetailedDescription2English,
            detailedDescriptionAdmin: _selectedLanguage == 'German' ? dashboardDetailedDescriptionAdmin2German : dashboardDetailedDescriptionAdmin2English,
            buttonText: _selectedLanguage == 'German' ? dashboardButtonText2German : dashboardButtonText2English,
            icon: Icons.cloud_upload,
            itemType: DashboardItemType.upload
          ),
          DashboardItem(
            id: "3",
            title: _selectedLanguage == 'German' ? dashboardTitle3German: dashboardTitle3English,
            description: _selectedLanguage == 'German' ? dashboardDescription3German : dashboardDescription3English,
            detailedDescription: _selectedLanguage == 'German' ? dashboardDetailedDescription3German : dashboardDetailedDescription3English,
            detailedDescriptionAdmin: _selectedLanguage == 'German' ? dashboardDetailedDescriptionAdmin3German : dashboardDetailedDescriptionAdmin3English,
            buttonText: _selectedLanguage == 'German' ? dashboardButtonText3German : dashboardButtonText3English,
            icon: Icons.code,
            itemType: DashboardItemType.ai
          )
        ];
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final selectedLanguage = await LanguageService.getLanguage();
    setState(() {
      _selectedLanguage = selectedLanguage;
    });
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
                if (dashboardItems.isNotEmpty)
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
                      helper: _helper, docOperations: widget.docOperations
                  ),
              ],
            ),
          ),
          if (_isChatVisible)
            Positioned(
              bottom: 0, // Adjust the position as needed
              left: 0,   // Adjust the position as needed
              right: 0,  // Adjust the position as needed
              child: SizedBox(
                height: 350, // Set the desired height
                child: ChatWindow(docOperations: widget.docOperations),
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
            _selectedLanguage == 'German' ? '$welcomeTextGerman, $_userName' : '$welcomeTextEnglish, $_userName',
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



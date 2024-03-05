import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'user.dart';
import 'language_service.dart';
import 'text_contents.dart';

class UserDetailsScreen extends StatefulWidget {
  final DocumentOperations docOperations;
  final Helper helper = Helper();

  UserDetailsScreen({super.key, required this.docOperations});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  List<UserInstance> users = [];
  List<String> domains = [];
  bool isLoading = true;
  String? errorMessage;
  String _selectedLanguage = 'German';
  // Language related content
  String userDetailsTitleGerman = getTextContentGerman("userDetailsTitle");
  String userDetailsTitleEnglish = getTextContentEnglish("userDetailsTitle");
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    // TodDo: Remove this if the server is running in the cloud!!!!
    users = widget.helper.createUserInstanceTestData();
    domains = widget.helper.createDomainListFromUsers(users);
    isLoading = false;
    /*widget.helper.fetchUsersFromServer().then((fetchedUsers) {
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    });*/
  }

  Future<void> _loadLanguage() async {
    final selectedLanguage = await LanguageService.getLanguage();
    setState(() {
      _selectedLanguage = selectedLanguage;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    widget.docOperations.clearProgressNotifierDict();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0, // Scroll to the top
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLanguage == "German" ? userDetailsTitleGerman : userDetailsTitleEnglish, style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _handleLogout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : UsersList(users, domains, widget.docOperations, _selectedLanguage, widget.helper),
      ),
    );
  }
}

class UsersList extends StatefulWidget {
  final List<UserInstance> users;
  final List<String> domainList;
  final Helper helper;
  final DocumentOperations docOperations;
  final String language;

  UsersList(this.users, this.domainList, this.docOperations, this.language, this.helper, {Key? key}) : super(key: key);

  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  List<UserInstance> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: widget.domainList.length,
        itemBuilder: (context, index) {
          String domain = widget.domainList[index];
          List<UserInstance> usersInDomain = widget.users
              .where((user) => user.domain == domain)
              .toList();

          return Card(
            elevation: 5.0,
            color: Colors.white, // Set the default color for the domain card
            margin: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Domain: $domain',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Column(
                  children: usersInDomain.map((user) {
                    bool isSelected = selectedUsers.contains(user);

                    // Determine the color based on conditions
                    Color userCardColor = user.disabled || !user.verified
                        ? Colors.red // Set to red if disabled or not verified
                        : Colors.white; // Set to white if conditions are not met

                    return GestureDetector(
                      onTap: user.disabled || !user.verified
                          ? null // Disable onTap if conditions are met
                          : () {
                        // Handle tapping on the user tile
                        print('Tapped on user: ${user.userName}');
                      },
                      child: Card(
                        elevation: 3.0,
                        margin: EdgeInsets.all(8.0),
                        color: userCardColor,
                        child: ListTile(
                          title: Text(user.userName ?? user.email),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role: ${user.role}'),
                              Text('Email: ${user.email}'),
                              Text('Disabled: ${user.disabled}'),
                              Text('Verified: ${user.verified}'),
                              // Add more subtitles as needed
                            ],
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  if (value) {
                                    selectedUsers.add(user);
                                  } else {
                                    selectedUsers.remove(user);
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Handle the selected users
            print('Selected Users: ${selectedUsers.map((user) => user.userName).toList()}');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 40,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Icon(Icons.cloud_upload, size: 90,), // Adjust the icon size
        ),
      ),
    );
  }
}




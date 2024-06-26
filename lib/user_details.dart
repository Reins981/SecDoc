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
  List<UserInstance> originalUsers = [];
  List<String> domains = [];
  bool _isLoading = true;
  String _selectedLanguage = 'German';
  // Language related content
  String userDetailsTitleGerman = getTextContentGerman("userDetailsTitle");
  String userDetailsTitleEnglish = getTextContentEnglish("userDetailsTitle");
  // Search related
  final TextEditingController searchController = TextEditingController();
  bool _isSearch = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    fetchUsersFromFirebase().then((_) {
      print("Fetch users from firebase completed!");
    });
  }

  @override
  void didChangeDependencies() {
    print("Refresh user detail screen");
    super.didChangeDependencies();
    onRefresh();
    // Perform actions that need to happen every time the dependencies change.
    _loadLanguage();
    fetchUsersFromFirebase().then((_) {
      print("Fetch users from firebase completed!");
    });
  }

  Future<void> fetchUsersFromFirebase() async {
    // TodDo: Remove this if the server is running in the cloud!!!!
    users = widget.helper.createUserInstanceTestData();
    Map<String, dynamic> userDetails = await widget.helper.getCurrentUserDetails();
    String adminDomain = userDetails['userDomain'];
    users = filterUsersByAdminDomain(adminDomain);
    originalUsers = List.from(users);
    domains = widget.helper.createDomainListFromUsers(users);
    _isLoading = false;
    _isSearch = false;

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

  void onRefresh() {
    setState(() {
      widget.docOperations.clearProgressNotifierDict();
    });
  }

  void restoreOriginalUsers() {
    users = originalUsers;
  }

  List<UserInstance> searchUsersByEmailOrDomain(String searchString) {
    List<UserInstance> filteredUsers = users
        .where((user) =>
    user.email.toLowerCase().contains(searchString.toLowerCase())
        || user.domain.toLowerCase().contains(searchString.toLowerCase()))
        .toList();

    return filteredUsers;
  }

  List<UserInstance> filterUsersByAdminDomain(String adminDomain) {
    List<UserInstance> filteredUsers = adminDomain != 'PV-ALL' ? users
        .where((user) => user.domain.toLowerCase() == adminDomain.toLowerCase())
        .toList() : users;

    return filteredUsers;
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
          IconButton(
            onPressed: () {
              setState(() {
                _isSearch = !_isSearch;
              });
            },
            icon: const Icon(Icons.search),
          ),
          // New Refresh Button
          IconButton(
            onPressed: () {
              fetchUsersFromFirebase().then((_) {
                setState(() {
                  // Update your state or perform any UI-related changes
                  print("Fetch users from firebase completed!");
                });
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        // Include the search bar when _isSearch is true
        bottom: _isSearch
            ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: searchController,
              style: const TextStyle(fontSize: 18.0),
              decoration: const InputDecoration(
                labelText: 'Search by Email or Domain',
                border: InputBorder.none,
              ),
              onChanged: (searchText) {
                // First restore the original users
                restoreOriginalUsers();
                setState(() {
                  _isSearch = searchText.isNotEmpty;
                });
                // Perform search logic here
                List<UserInstance> filteredUsers = searchUsersByEmailOrDomain(searchText);
                users = filteredUsers;
              },
            ),
          ),
        )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
  bool isUploading = false;
  String userDetailsErrorNoUsersSelectedGerman = getTextContentGerman("userDetailsErrorNoUsersSelected");
  String userDetailsErrorNoUsersSelectedEnglish = getTextContentEnglish("userDetailsErrorNoUsersSelected");
  String userDetailsErrorNoUploadMethodSelectedGerman = getTextContentGerman("userDetailsErrorNoUploadMethodSelected");
  String userDetailsErrorNoUploadMethodSelectedEnglish = getTextContentEnglish("userDetailsErrorNoUploadMethodSelected");
  String userDetailsNotVerifiedOrDisabledGerman = getTextContentGerman("userDetailsNotVerifiedOrDisabled");
  String userDetailsNotVerifiedOrDisabledEnglish = getTextContentEnglish("userDetailsNotVerifiedOrDisabled");
  String userDetailsVerifiedAndEnabledGerman = getTextContentGerman("userDetailsVerifiedAndEnabled");
  String userDetailsVerifiedAndEnabledEnglish = getTextContentEnglish("userDetailsVerifiedAndEnabled");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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

                          return GestureDetector(
                            onTap: user.disabled || !user.verified
                                ? () {
                                ScaffoldMessengerState scaffoldContext = ScaffoldMessenger.of(context);
                                String message = widget.language == 'German' ? userDetailsNotVerifiedOrDisabledGerman : userDetailsNotVerifiedOrDisabledEnglish;
                                widget.helper.showSnackBar(
                                    "'${user.userName}' $message", 'Error', scaffoldContext, duration: 2);
                            } // Disable onTap if conditions are met
                                : () {
                              ScaffoldMessengerState scaffoldContext = ScaffoldMessenger.of(context);
                              String message = widget.language == 'German' ? userDetailsVerifiedAndEnabledGerman : userDetailsVerifiedAndEnabledEnglish;
                              // Handle tapping on the user tile
                              widget.helper.showSnackBar(
                                  "'${user.userName}' $message", "Info", scaffoldContext, duration: 2);
                            },
                            child: Card(
                              elevation: 3.0,
                              margin: EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(user.userName ?? user.email),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Role: ${user.role}',
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'Email: ${user.email}',
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: user
                                            .disabled
                                            ? Colors
                                            .red
                                            : Colors
                                            .green,
                                        border: user
                                            .disabled
                                            ? Border
                                            .all(
                                          color: Colors
                                              .red,
                                          // Border color
                                          width: 1.0, // Border width
                                        )
                                            : Border
                                            .all(
                                          color: Colors
                                              .green,
                                          // Border color
                                          width: 1.0, // Border width
                                        ),
                                        borderRadius: BorderRadius
                                            .circular(
                                            4.0), // Border radius
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets
                                            .all(
                                            4.0),
                                        // Add padding inside the box
                                        child: Text(
                                          "Disabled: ${user
                                              .disabled
                                              ? 'Yes'
                                              : 'No'}",
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontStyle: FontStyle.italic,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: user
                                            .verified
                                            ? Colors
                                            .green
                                            : Colors
                                            .red,
                                        border: user
                                            .verified
                                            ? Border
                                            .all(
                                          color: Colors
                                              .green,
                                          // Border color
                                          width: 1.0, // Border width
                                        )
                                            : Border
                                            .all(
                                          color: Colors
                                              .red,
                                          // Border color
                                          width: 1.0, // Border width
                                        ),
                                        borderRadius: BorderRadius
                                            .circular(
                                            4.0), // Border radius
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets
                                            .all(
                                            4.0),
                                        // Add padding inside the box
                                        child: Text(
                                          "Verified: ${user
                                              .verified
                                              ? 'Yes'
                                              : 'No'}",
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontStyle: FontStyle.italic,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Add more subtitles as needed
                                  ],
                                ),
                                trailing: Visibility(
                                  visible: !user.disabled && user.verified,
                                  child: RoundCheckbox(
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
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Visibility(
            visible: isUploading,
            child: Align(
              alignment: Alignment.center,
              child: LinearProgressIndicator(
                minHeight: 4.0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            ScaffoldMessengerState scaffoldContext = ScaffoldMessenger.of(
                context);
            // Handle the selected users
            print('Handle upload for selected Users: ${selectedUsers.map((
            user) => user.userName).toList()}');
            if (selectedUsers.isEmpty) {
              widget.helper.showSnackBar(
                  widget.language == 'German' ? userDetailsErrorNoUsersSelectedGerman : userDetailsErrorNoUsersSelectedEnglish,
                  'Error', scaffoldContext);
              return;
            }

            // Show upload method selection menu
            String? selectedMethod = await widget.helper.showUploadMethodSelectionMenu(context);
            if (selectedMethod == null) {
              widget.helper.showSnackBar(
                  widget.language == 'German' ? userDetailsErrorNoUploadMethodSelectedGerman : userDetailsErrorNoUploadMethodSelectedEnglish,
                  'Error', scaffoldContext);
              return;
            }

            // Show category selection menu
            String? selectedCategory = selectedMethod == 'Phone'
                ? await widget.helper.showCategorySelectionMenu(context)
                : 'Images';

            if (selectedCategory != null) {
              setState(() {
                isUploading = true;
              });

              String documentId = "uploadDocIdDefaultAdmin";
              widget.docOperations.setProgressNotifierDictValue(documentId);
              List<Map<String, dynamic>> userDetails = widget.helper
                  .createUserDetailsForUserInstances(selectedUsers);
              selectedMethod == 'Phone'
                  ? await widget.docOperations.uploadDocuments(
                  documentId, null, selectedCategory, userDetails, scaffoldContext)
                  : await widget.docOperations.openCameraAndUpload(
                  documentId, selectedCategory, userDetails, scaffoldContext);

              if (mounted) {
                setState(() {
                  isUploading = false;
                });
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
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

class RoundCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  RoundCheckbox({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        if (onChanged != null) {
          onChanged!(!value);
        }
      },
      containedInkWell: true, // This property controls the splash containment
      customBorder: const CircleBorder(),
      splashColor: Colors.blue.withOpacity(0.5),
      splashFactory: InkRipple.splashFactory,
      child: SizedBox(
        width: 50.0,
        height: 50.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: value
                ? const Icon(
              Icons.check,
              size: 20.0,
              color: Colors.blue,
            )
                : Container(),
          ),
        ),
      ),
    );
  }
}







import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; // Import the async package for using StreamController
import 'package:rxdart/rxdart.dart';
import 'progress_bar.dart';
import 'package:provider/provider.dart';
import 'helpers.dart';
import 'document.dart';
import 'document_provider.dart';
import 'language_service.dart';
import 'text_contents.dart';


class DocumentLibraryScreen extends StatefulWidget {

  final DocumentOperations documentOperations;
  final Helper helper;

  DocumentLibraryScreen({
    Key? key,
    required this.documentOperations,
    required this.helper}) : super(key: key);

  @override
  _DocumentLibraryScreenState createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = 'German';

  String documentLibraryTitleGerman = getTextContentGerman("documentLibraryTitle");
  String documentLibraryTitleEnglish = getTextContentEnglish("documentLibraryTitle");
  String documentLibraryDownloadErrorGerman = getTextContentGerman("documentLibraryDownloadError");
  String documentLibraryDownloadErrorEnglish = getTextContentEnglish("documentLibraryDownloadError");
  String documentLibraryLoadingDataErrorGerman = getTextContentGerman("documentLibraryLoadingDataError");
  String documentLibraryLoadingDataErrorEnglish = getTextContentEnglish("documentLibraryLoadingDataError");
  String documentLibraryLoadingDocumentErrorGerman = getTextContentGerman("documentLibraryLoadingDocumentError");
  String documentLibraryLoadingDocumentErrorEnglish = getTextContentEnglish("documentLibraryLoadingDocumentError");
  String documentLibraryDownloadNotificationGerman = getTextContentGerman("documentLibraryDownloadNotification");
  String documentLibraryDownloadNotificationEnglish = getTextContentEnglish("documentLibraryDownloadNotification");
  String documentLibraryDownloadSuccessGerman = getTextContentGerman("documentLibraryDownloadSuccess");
  String documentLibraryDownloadSuccessEnglish = getTextContentEnglish("documentLibraryDownloadSuccess");
  String documentLibraryDeleteSuccessGerman = getTextContentGerman("documentLibraryDeleteSuccess");
  String documentLibraryDeleteSuccessEnglish = getTextContentEnglish("documentLibraryDeleteSuccess");
  String documentLibraryNoUserDataGerman = getTextContentGerman("documentLibraryNoUserData");
  String documentLibraryNoUserDataEnglish = getTextContentEnglish("documentLibraryNoUserData");
  String documentLibraryUserNotExistsGerman = getTextContentGerman("documentLibraryUserNotExists");
  String documentLibraryUserNotExistsEnglish = getTextContentEnglish("documentLibraryUserNotExists");
  String documentLibraryUserRoleNotExistsGerman = getTextContentGerman("documentLibraryUserRoleNotExists");
  String documentLibraryUserRoleNotExistsEnglish = getTextContentEnglish("documentLibraryUserRoleNotExists");
  String documentLibraryUserDomainNotExistsGerman = getTextContentGerman("documentLibraryUserDomainNotExists");
  String documentLibraryUserDomainNotExistsEnglish = getTextContentEnglish("documentLibraryUserDomainNotExists");
  String documentLibraryNoDocsGerman = getTextContentGerman("documentLibraryNoDocs");
  String documentLibraryNoDocsEnglish = getTextContentEnglish("documentLibraryNoDocs");

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    widget.helper.initializeNotifications();
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
    widget.documentOperations.clearProgressNotifierDict();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void onRefresh() {
    setState(() {
      widget.documentOperations.clearProgressNotifierDict();
    });
  }

  Future<Map<String, String>> updateDocumentViewedField(Document document, Map<String, dynamic> userDetails) async {
    String documentId = document.id;

    Map<String, String> result = await widget.documentOperations.updateDocumentFieldAsBool(userDetails, documentId, "viewed", true);
    return result;
  }

  void handleDownload(BuildContext context, Document document, String category) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    String downloadPath = await widget.documentOperations.createDownloadPathForFile(document.name);
    Map<String, dynamic> userDetails = await widget.helper.getCurrentUserDetails();
    String userRole = userDetails['userRole'];

    if (downloadPath == "Failed") {
      widget.helper.showSnackBar(_selectedLanguage == 'German' ? documentLibraryDownloadErrorGerman : documentLibraryDownloadErrorEnglish, "Error", scaffoldContext);
    } else {
      widget.documentOperations.downloadDocument(document, downloadPath).then((String status) async {
        if (status != "Success") {
          widget.helper.showSnackBar(status, "Error", scaffoldContext);
        } else {
          // Update the 'viewed' field
          Map<String, String> result = {
            'status': 'Success',
            'message': ""
          };
          // Update the viewable field only in client mode and for certain categories
          if (immutableCategories.contains(category) && userRole == 'client') {
            result = await updateDocumentViewedField(document, userDetails);
            if (result['status'] == 'Error') {
              String? errorMessage = result['message'];
              // widget.helper.showSnackBar(errorMessage ?? "Default Error Message", 'Error', scaffoldContext);
              print(errorMessage);
            }
          }

          String successMessage = _selectedLanguage == 'German' ? "Dokument ${document.name}$documentLibraryDownloadSuccessGerman" : "Document ${document.name}$documentLibraryDownloadSuccessEnglish";
          await widget.helper.showCustomNotificationAndroid(
          _selectedLanguage == 'German' ? documentLibraryDownloadNotificationGerman : documentLibraryDownloadNotificationEnglish, // Notification title
          successMessage, // Notification content
          downloadPath
          );
        }
      });
    }
  }

  Future<String> handleDelete(BuildContext context, Document document) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    String collectionPath = 'documents_${document.domain.toLowerCase()}';

    try {
      String status = await widget.documentOperations.deleteDocument(document.id, document, collectionPath);
      if (status != "Success") {
        widget.helper.showSnackBar(status, "Error", scaffoldContext);
        return 'Failed';
      } else {
        String successMessage = _selectedLanguage == 'German' ? "${document.name}$documentLibraryDeleteSuccessGerman" : "${document.name}$documentLibraryDeleteSuccessEnglish";
        widget.helper.showSnackBar(successMessage, "Success", scaffoldContext);
        return 'Success';
      }
    } catch (e) {
      widget.helper.showSnackBar('$e', "Error", scaffoldContext);
      return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<IdTokenResult>(
      future: widget.helper.getIdTokenResult(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
                _selectedLanguage == 'German' ? '$documentLibraryLoadingDataErrorGerman: ${snapshot.error}' : '$documentLibraryLoadingDataErrorEnglish: ${snapshot.error}',
                style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.black,
                letterSpacing: 1.0,
              ),
            )
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(
              _selectedLanguage == 'German' ? documentLibraryNoUserDataGerman : documentLibraryNoUserDataEnglish,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.black,
                letterSpacing: 1.0,
              ),
            )
          );
        }

        final idTokenResult = snapshot.data!;
        final customClaims = idTokenResult.claims;

        final userRole = customClaims?['role'];
        final userDomain = customClaims?['domain'];

        FirebaseAuth auth = FirebaseAuth.instance;
        User? user = auth.currentUser;
        final userUid = user?.uid;

        if (user == null) {
          return Center(child: Text(_selectedLanguage == 'German' ? documentLibraryUserNotExistsGerman : documentLibraryUserNotExistsEnglish));
        }

        if (userRole == null) {
          final String errorMessage = _selectedLanguage == 'German' ? '$documentLibraryUserRoleNotExistsGerman ($userUid)' : '$documentLibraryUserRoleNotExistsEnglish ($userUid)';
          return Center(
            child: Text(
              errorMessage,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.black,
                letterSpacing: 1.0,
              ),
            )
          );
        }

        if (userDomain == null) {
          final String errorMessage = _selectedLanguage == 'German' ? '$documentLibraryUserDomainNotExistsGerman ($userDomain)' : '$documentLibraryUserDomainNotExistsEnglish ($userDomain)';
          return Center(
            child: Text(
              errorMessage,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.black,
                letterSpacing: 1.0,
              ),
            )
          );
        }

        return FutureBuilder<dynamic>(
          future: widget.documentOperations.fetchDocuments(userRole, userDomain, userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                )
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  _selectedLanguage == 'German' ? documentLibraryNoDocsGerman : documentLibraryNoDocsEnglish,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                )
              );
            }

            final data = snapshot.data;

            dynamic mergedData;
            if (data is List<Stream<QuerySnapshot>>) {
              mergedData = CombineLatestStream.list(data);
            } else {
              mergedData = data;
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(_selectedLanguage == 'German' ? documentLibraryTitleGerman : documentLibraryTitleEnglish, style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
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
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: DocumentListWidget(
                    language: _selectedLanguage,
                    mergedData: mergedData,
                    handleLogout: _handleLogout,
                    searchController: _searchController,
                    documentOperations: widget.documentOperations,
                    callbackDownload: handleDownload,
                    callbackDelete: handleDelete,
                    onRefresh: onRefresh,
                    origStream: data,
                    helper: widget.helper,
                    userRole: userRole,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DocumentListWidget extends StatefulWidget {
  final String language;
  final Stream<dynamic> mergedData;
  final Function(BuildContext) handleLogout;
  final TextEditingController searchController;
  final DocumentOperations documentOperations;
  final void Function(BuildContext, Document, String) callbackDownload;
  final Future<String> Function(BuildContext, Document) callbackDelete;
  final void Function() onRefresh;
  final dynamic origStream;
  final Helper helper;
  final String userRole;

  const DocumentListWidget({super.key,
    required this.language,
    required this.mergedData,
    required this.handleLogout,
    required this.searchController,
    required this.documentOperations,
    required this.callbackDownload,
    required this.callbackDelete,
    required this.onRefresh,
    required this.origStream,
    required this.helper,
    required this.userRole,
  });

  @override
  _DocumentListWidgetState createState() => _DocumentListWidgetState();
}

class _DocumentListWidgetState extends State<DocumentListWidget> {
  bool _isInitialized = false;
  bool _isSearch = false;
  bool _isServerUpdate = false;
  List<DocumentSnapshot> displayDocuments = [];
  List<DocumentSnapshot> allDocumentsOrig = []; // Store all documents here

  String documentLibraryLoadingDocumentErrorGerman = getTextContentGerman("documentLibraryLoadingDocumentError");
  String documentLibraryLoadingDocumentErrorEnglish = getTextContentEnglish("documentLibraryLoadingDocumentError");
  String documentLibraryNoDocsGerman = getTextContentGerman("documentLibraryNoDocs");
  String documentLibraryNoDocsEnglish = getTextContentEnglish("documentLibraryNoDocs");

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context, listen: true);

    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(8.0),
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
                  offset: const Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.searchController,
              style: const TextStyle(fontSize: 18.0), // Adjust font size
              decoration: InputDecoration(
                labelText: 'Document, Status, User, Email, Category, ..',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh), // Reset filter icon
                  onPressed: () {
                    widget.searchController.text = '';
                    _isSearch = false;
                    _isServerUpdate = false;
                    _isInitialized = false;
                    widget.onRefresh();
                  },
                ),
              ),
              onChanged: (searchText) {
                setState(() {
                  _isSearch = searchText.isNotEmpty;
                });
                documentProvider.delaySearch(searchText, allDocumentsOrig, widget.userRole);
              },
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<dynamic>(
            stream: widget.mergedData,
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                String errorMessageDefault = widget.language == 'German' ? documentLibraryLoadingDocumentErrorGerman : documentLibraryLoadingDocumentErrorEnglish;
                String errorMessage = snapshot.error?.toString() ??
                    errorMessageDefault;
                return Center(
                  child: Text(
                    errorMessage,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  )
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Text(widget.language == 'German' ? documentLibraryNoDocsGerman : documentLibraryNoDocsEnglish,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  )
                );
              }

              // Create the original document list and the display document list initially
              displayDocuments =
                  createDocumentListForDisplayFromSnapshot(snapshot, widget.origStream);

              if (!_isInitialized) {
                final groupedDocuments = widget.documentOperations.groupDocuments(displayDocuments, widget.userRole);
                _isInitialized = true;

                return CustomListWidget(
                    language: widget.language,
                    groupedDocuments: groupedDocuments,
                    documentOperations: widget.documentOperations,
                    callbackDownload: widget.callbackDownload,
                    callbackDelete: widget.callbackDelete,
                    isSearch: _isSearch,
                    isServerUpdate: _isServerUpdate,
                    documentProvider: documentProvider,
                    helper: widget.helper,
                    userRole: widget.userRole,
                );

              } else {
                print("Invoking Consumer");
                if (documentProvider.groupedDocuments == null || _isSearch == false) {
                  documentProvider.groupAndSetDocuments(displayDocuments, widget.userRole, notifyL: false);
                  _isServerUpdate = true;
                }

                return Consumer<DocumentProvider>(
                  builder: (context, documentProvider, _) {
                    final groupedDocuments = documentProvider.groupedDocuments;
                    return CustomListWidget(
                        language: widget.language,
                        groupedDocuments: groupedDocuments!,
                        documentOperations: widget.documentOperations,
                        callbackDownload: widget.callbackDownload,
                        callbackDelete: widget.callbackDelete,
                        isSearch: _isSearch,
                        isServerUpdate: _isServerUpdate,
                        documentProvider: documentProvider,
                        helper: widget.helper,
                        userRole: widget.userRole,
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  List<DocumentSnapshot> createDocumentListForDisplayFromSnapshot(AsyncSnapshot<dynamic> snapshot, dynamic origStream) {
    List<DocumentSnapshot> displayDocuments = [];
    if (origStream is List<Stream<QuerySnapshot>>) {
      final querySnapshotList = snapshot.data!;
      _fillOrigDocumentsFromQuerySnapshotList(querySnapshotList);
    } else {
      allDocumentsOrig = snapshot.data!.docs;
    }

    displayDocuments = allDocumentsOrig;

    return displayDocuments;
  }

  void _fillOrigDocumentsFromQuerySnapshotList(List<dynamic> querySnapshotList) {
    allDocumentsOrig.clear();
    querySnapshotList.forEach((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        allDocumentsOrig.add(doc);
      });
    });
  }
}

class CustomListWidget extends StatelessWidget {
  final String language;
  final Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>> groupedDocuments;
  final DocumentOperations documentOperations;
  final void Function(BuildContext, Document, String) callbackDownload;
  final Future<String> Function(BuildContext, Document) callbackDelete;
  final bool isSearch;
  final bool isServerUpdate;
  final DocumentProvider documentProvider;
  final Helper helper;
  final String userRole;

  final String documentLibraryDomainGerman = getTextContentGerman("documentLibraryDomain");
  final String documentLibraryDomainEnglish = getTextContentEnglish("documentLibraryDomain");
  final String documentLibraryYearGerman = getTextContentGerman("documentLibraryYear");
  final String documentLibraryYearEnglish = getTextContentEnglish("documentLibraryYear");
  final String documentLibraryCategoryGerman = getTextContentGerman("documentLibraryCategory");
  final String documentLibraryCategoryEnglish = getTextContentEnglish("documentLibraryCategory");
  final String documentLibraryPrefixFromGerman = getTextContentGerman("documentLibraryPrefixFrom");
  final String documentLibraryPrefixFromEnglish = getTextContentEnglish("documentLibraryPrefixFrom");
  final String documentLibraryPrefixForGerman = getTextContentGerman("documentLibraryPrefixFor");
  final String documentLibraryPrefixForEnglish = getTextContentEnglish("documentLibraryPrefixFor");
  final String documentLibraryCategoryCustomerAdminEnglish = getTextContentEnglish("documentLibraryCategoryCustomerAdmin");
  final String documentLibraryCategoryCustomerClientEnglish = getTextContentEnglish("documentLibraryCategoryCustomerClient");

  CustomListWidget({super.key,
    required this.language,
    required this.groupedDocuments,
    required this.documentOperations,
    required this.callbackDownload,
    required this.callbackDelete,
    required this.isSearch,
    required this.isServerUpdate,
    required this.documentProvider,
    required this.helper,
    required this.userRole,
  });

  List<dynamic> modifyDisplayCategoryBasedOnCategory(String currentCategory, String expectedCategory) {
    List<dynamic> results = [];
    String prefix = "";

    if ((userRole == "admin" || userRole == "super_admin") && currentCategory == expectedCategory) {
      currentCategory = documentLibraryCategoryCustomerAdminEnglish;
      prefix = language == 'German' ? "$documentLibraryPrefixFromGerman: " : "$documentLibraryPrefixFromEnglish: ";
    } else {
      // No language change
      if (userRole == "client" && immutableCategories.contains(currentCategory)) {
        prefix = language == 'German' ? "$documentLibraryPrefixFromGerman: " : "$documentLibraryPrefixFromEnglish: ";
      } else if ((userRole == "admin" || userRole == "super_admin") && immutableCategories.contains(currentCategory)) {
        prefix = language == 'German' ? "$documentLibraryPrefixForGerman: " : "$documentLibraryPrefixForEnglish: ";
      }
    }
    results.add(currentCategory);
    results.add(prefix);
    return results;
  }

  @override
  Widget build(BuildContext context) {
    // Use groupedDocuments to build your custom UI here
    // ...
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
      ),
      child: ListView.builder(
        itemCount: groupedDocuments.length,
        itemBuilder: (context, index) {
          final domain = groupedDocuments.keys.elementAt(
              index);
          final yearMap = groupedDocuments[domain]!;
          final yearList = yearMap.keys.toList();

          return ExpansionTile(
            initiallyExpanded: isSearch || isServerUpdate,
            title: Text(
              language == 'German' ? '$documentLibraryDomainGerman: $domain' : '$documentLibraryDomainEnglish: $domain',
              style: GoogleFonts.lato(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            children: yearList.map((year) {
              final categoryMap = yearMap[year]!;
              final categoryList = categoryMap.keys
                  .toList();

              return ExpansionTile(
                initiallyExpanded: isSearch || isServerUpdate,
                title: Text(
                  language == 'German' ? '$documentLibraryYearGerman: $year' : '$documentLibraryYearEnglish: $year',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                children: categoryList.map((category) {
                  String prefix = language == 'German' ? "$documentLibraryPrefixForGerman: " : "$documentLibraryPrefixForEnglish: ";
                  final userMap = categoryMap[category]!;
                  final userList = userMap.keys
                      .toList();
                  // Expected client category based on language;
                  String expectedCategory = documentLibraryCategoryCustomerClientEnglish;
                  List<dynamic> results = modifyDisplayCategoryBasedOnCategory(category, expectedCategory);
                  category = results[0];
                  prefix = results[1];

                  return ExpansionTile(
                    initiallyExpanded: isSearch || isServerUpdate,
                    title: Text(
                      language == 'German' ? '$documentLibraryCategoryGerman: $category' : '$documentLibraryCategoryEnglish: $category',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    children: userList.map((user) {
                      final documentRepo = userMap[user]!;
                      return ExpansionTile(
                        initiallyExpanded: isSearch || isServerUpdate,
                        title: Text(
                          user = '$prefix$user',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: documentRepo
                                .documents.length,
                            itemBuilder: (context,
                                index) {
                              final document = documentRepo
                                  .documents[index];
                              return Padding(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 8.0),
                                child: Card(
                                  elevation: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      ListTile(
                                        onTap: () async {
                                          DocumentDetailScreen screen = DocumentDetailScreen(
                                            document: document,
                                            docOperations: documentOperations,
                                            helper: helper,
                                          );
                                          Navigator
                                              .push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (
                                                  context) => screen,
                                            ),
                                          );
                                          // If there is no error, go ahead
                                          if (screen.getError().isEmpty) {
                                            // Update the viewed field
                                            Map<String,
                                                dynamic> userDetails = await helper
                                                .getCurrentUserDetails();
                                            Map<String,
                                                String> result = await documentOperations
                                                .updateDocumentFieldAsBool(
                                                userDetails, document.id,
                                                "viewed", true);
                                            if (result['status'] == 'Error') {
                                              String? errorMessage = result['message'];
                                              print(errorMessage);
                                            }
                                          }
                                        },
                                        title: Text(
                                          document.name,
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              "Last Update: ${document.lastUpdate?.toDate()}",
                                              style: GoogleFonts.lato(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: document
                                                    .isNew
                                                    ? Colors
                                                    .yellow
                                                    : Colors
                                                    .transparent,
                                                border: document
                                                    .isNew
                                                    ? Border
                                                    .all(
                                                  color: Colors
                                                      .yellow,
                                                  // Border color
                                                  width: 1.0, // Border width
                                                )
                                                    : null,
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
                                                  "Status: ${document
                                                      .isNew
                                                      ? 'New'
                                                      : 'Updated'}",
                                                  style: GoogleFonts.lato(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontStyle: FontStyle.italic,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: (userRole == "admin" || userRole == "super_admin") && immutableCategories.contains(category),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: document
                                                      .viewed
                                                      ? Colors
                                                      .orange
                                                      : Colors
                                                      .transparent,
                                                  border: document
                                                      .viewed
                                                      ? Border
                                                      .all(
                                                    color: Colors
                                                        .orange,
                                                    // Border color
                                                    width: 1.0, // Border width
                                                  )
                                                      : null,
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
                                                    "Viewed: ${document
                                                        .viewed
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
                                            ),
                                          ],
                                        ),
                                      ),
                                      ButtonBar(
                                        alignment: MainAxisAlignment
                                            .spaceBetween,
                                        children: [
                                          ElevatedButton
                                              .icon(
                                            onPressed: () async {
                                              callbackDownload(context, document, category);
                                            },
                                            icon: const Icon(
                                                Icons
                                                    .download),
                                            label: Text(
                                              'Download',
                                              style: GoogleFonts.lato(
                                                fontSize: 16,
                                                color: Colors.black,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton
                                              .icon(
                                            onPressed: () async {
                                              // Avoid uninitialized groupedDocuments from the Provider
                                              documentProvider.setGroupedDocuments(groupedDocuments);
                                              String status = await callbackDelete(context, document);
                                              if (status == 'Success') {
                                                documentProvider
                                                    .removeDocumentWithId(
                                                    document);
                                              }
                                            },
                                            icon: const Icon(
                                                Icons
                                                    .delete),
                                            label: Text(
                                              'Delete',
                                              style: GoogleFonts.lato(
                                                fontSize: 16,
                                                color: Colors.black,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ProgressBar(
                                        progress: documentOperations
                                            .getProgressNotifierDict()[document.id],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}


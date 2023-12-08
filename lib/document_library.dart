import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Import the async package for using StreamController
import 'package:rxdart/rxdart.dart';
import 'progress_bar.dart';
import 'package:provider/provider.dart';
import 'helpers.dart';
import 'document.dart';
import 'document_provider.dart';


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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.helper.initializeNotifications();
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

  void handleDownload(BuildContext context, Document document) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    String downloadPath = await widget.documentOperations.createDownloadPathForFile(document.name);

    if (downloadPath == "Failed") {
      widget.helper.showSnackBar("Could not access download directory", "Error", scaffoldContext);
    } else {
      widget.documentOperations.downloadDocument(document, downloadPath).then((String status) async {
        if (status != "Success") {
          widget.helper.showSnackBar(status, "Error", scaffoldContext);
        } else {
          await widget.helper.showCustomNotificationAndroid(
              'Download Complete', // Notification title
              'Document ${document.name} downloaded successfully', // Notification content
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
        widget.helper.showSnackBar("${document.name} deleted successfully", "Success", scaffoldContext);
        return 'Success';
      }
    } catch (e) {
      widget.helper.showSnackBar('Error: $e', "Error", scaffoldContext);
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
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No user data available'));
        }

        final idTokenResult = snapshot.data!;
        final customClaims = idTokenResult.claims;

        final userRole = customClaims?['role'];
        final userDomain = customClaims?['domain'];

        FirebaseAuth auth = FirebaseAuth.instance;
        User? user = auth.currentUser;
        final userUid = user?.uid;

        if (user == null) {
          return const Center(child: Text('The user does not exist.'));
        }

        if (userRole == null) {
          final String errorMessage = 'User Role for user $userUid not defined.';
          return Center(child: Text(errorMessage));
        }

        if (userDomain == null) {
          final String errorMessage = 'User Domain for user $userUid not defined.';
          return Center(child: Text(errorMessage));
        }

        return FutureBuilder<dynamic>(
          future: widget.documentOperations.fetchDocuments(userRole, userDomain, userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No documents available.'));
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
                title: const Text('Document Library'),
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
                    mergedData: mergedData,
                    handleLogout: _handleLogout,
                    searchController: _searchController,
                    documentOperations: widget.documentOperations,
                    callbackDownload: handleDownload,
                    callbackDelete: handleDelete,
                    onRefresh: onRefresh,
                    origStream: data,
                    helper: widget.helper,
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
  final Stream<dynamic> mergedData;
  final Function(BuildContext) handleLogout;
  final TextEditingController searchController;
  final DocumentOperations documentOperations;
  final void Function(BuildContext, Document) callbackDownload;
  final Future<String> Function(BuildContext, Document) callbackDelete;
  final void Function() onRefresh;
  final dynamic origStream;
  final Helper helper;

  const DocumentListWidget({super.key,
    required this.mergedData,
    required this.handleLogout,
    required this.searchController,
    required this.documentOperations,
    required this.callbackDownload,
    required this.callbackDelete,
    required this.onRefresh,
    required this.origStream,
    required this.helper
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
                labelText: 'Enter Document, Status, User, Email, or Category',
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
                documentProvider.delaySearch(searchText, allDocumentsOrig);
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
                String errorMessage = snapshot.error?.toString() ??
                    'Error loading documents';
                return Center(child: Text(errorMessage));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                    child: Text('No documents available.'));
              }

              // Create the original document list and the display document list initially
              displayDocuments =
                  createDocumentListForDisplayFromSnapshot(snapshot, widget.origStream);

              if (!_isInitialized) {
                final groupedDocuments = widget.documentOperations.groupDocuments(displayDocuments);
                _isInitialized = true;

                return CustomListWidget(
                    groupedDocuments: groupedDocuments,
                    documentOperations: widget.documentOperations,
                    callbackDownload: widget.callbackDownload,
                    callbackDelete: widget.callbackDelete,
                    isSearch: _isSearch,
                    isServerUpdate: _isServerUpdate,
                    documentProvider: documentProvider,
                    helper: widget.helper,
                );

              } else {
                print("Invoking Consumer");
                if (documentProvider.groupedDocuments == null || _isSearch == false) {
                  documentProvider.groupAndSetDocuments(displayDocuments, notifyL: false);
                  _isServerUpdate = true;
                }

                return Consumer<DocumentProvider>(
                  builder: (context, documentProvider, _) {
                    final groupedDocuments = documentProvider.groupedDocuments;
                    return CustomListWidget(
                        groupedDocuments: groupedDocuments!,
                        documentOperations: widget.documentOperations,
                        callbackDownload: widget.callbackDownload,
                        callbackDelete: widget.callbackDelete,
                        isSearch: _isSearch,
                        isServerUpdate: _isServerUpdate,
                        documentProvider: documentProvider,
                        helper: widget.helper
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
  final Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>> groupedDocuments;
  final DocumentOperations documentOperations;
  final void Function(BuildContext, Document) callbackDownload;
  final Future<String> Function(BuildContext, Document) callbackDelete;
  final bool isSearch;
  final bool isServerUpdate;
  final DocumentProvider documentProvider;
  final Helper helper;

  const CustomListWidget({super.key,
    required this.groupedDocuments,
    required this.documentOperations,
    required this.callbackDownload,
    required this.callbackDelete,
    required this.isSearch,
    required this.isServerUpdate,
    required this.documentProvider,
    required this.helper,
  });

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
              'Domain: $domain',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: yearList.map((year) {
              final categoryMap = yearMap[year]!;
              final categoryList = categoryMap.keys
                  .toList();

              return ExpansionTile(
                initiallyExpanded: isSearch || isServerUpdate,
                title: Text(
                  'Year: $year',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: categoryList.map((category) {
                  final userMap = categoryMap[category]!;
                  final userList = userMap.keys
                      .toList();

                  return ExpansionTile(
                    initiallyExpanded: isSearch || isServerUpdate,
                    title: Text(
                      'Category: $category',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: userList.map((user) {
                      final documentRepo = userMap[user]!;
                      return ExpansionTile(
                        initiallyExpanded: isSearch || isServerUpdate,
                        title: Text(
                          'Customer: $user',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                                        onTap: () {
                                          Navigator
                                              .push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (
                                                  context) =>
                                                  DocumentDetailScreen(
                                                      document: document,
                                                      docOperations: documentOperations,
                                                      helper: helper
                                                  ),
                                            ),
                                          );
                                        },
                                        title: Text(
                                          document.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight
                                                .w500,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              "Last Update: ${document.lastUpdate?.toDate()}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle
                                                    .italic,
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
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontStyle: FontStyle
                                                        .italic,
                                                    color: Colors
                                                        .black, // Text color
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
                                              callbackDownload(context, document);
                                            },
                                            icon: const Icon(
                                                Icons
                                                    .download),
                                            label: const Text(
                                                'Download'),
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
                                            label: const Text(
                                                'Delete'),
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


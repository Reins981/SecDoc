import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // Import the LoginScreen to navigate back after logout
import 'dart:async'; // Import the async package for using StreamController
import 'package:rxdart/rxdart.dart';
import 'progress_bar.dart';
import 'package:provider/provider.dart';
import 'helpers.dart';


class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({Key? key}) : super(key: key);

  @override
  _DocumentLibraryScreenState createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> allDocumentsOrig = []; // Store all documents here
  List<DocumentSnapshot>? _filteredDocuments = [];
  Timer? _debounceTimer;

  // Global Helper Instances
  final _helper = Helper();
  final _documentOperations = DocumentOperations();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _helper.initializeNotifications();
  }

  // Search document by document name or user name
  void _searchDocumentByNames(String searchText) {
    List<DocumentSnapshot> allDocumentsCopy = List.from(allDocumentsOrig);
    // Replace this with your logic to filter the document
    // Assuming you have a list of documents called 'documents' and 'documentName' is the search query.

    List<DocumentSnapshot> filteredDocuments = allDocumentsCopy
        .where((doc) =>
              doc['document_name']
                  .toLowerCase()
                  .contains(searchText.toLowerCase())
              ||
              doc['user_name']
                  .toLowerCase()
                  .contains(searchText.toLowerCase()))
        .toList();

    setState(() {
      if (filteredDocuments.isNotEmpty) {
        _filteredDocuments = filteredDocuments;
      } else {
        _filteredDocuments = null;
      }
    });
  }

  List<DocumentSnapshot> createDocumentListForDisplayFromSnapshot(AsyncSnapshot<dynamic> snapshot, var origStream) {
    List<DocumentSnapshot> displayDocuments = [];
    if (_filteredDocuments != null) {
      if (_filteredDocuments!.isEmpty) {
        if (origStream is List<Stream<QuerySnapshot>>) {
          final querySnapshotList = snapshot.data!;
          _fillOrigDocumentsFromQuerySnapshotList(querySnapshotList);
        } else {
          allDocumentsOrig = snapshot.data!.docs;
        }
        displayDocuments = allDocumentsOrig;
      } else {
        displayDocuments = _filteredDocuments!;
      }
    }
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

  void delaySearch(String searchText) {
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer!.cancel(); // Cancel the previous timer if it's active
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchDocumentByNames(searchText); // Perform search after a delay
    });
  }

  void showSnackBarError(String error, ScaffoldMessengerState context) {
    context.showSnackBar(
      SnackBar(
        content: Text('Error: $error'), // Show the error message in the SnackBar
      ),
    );
  }

  void handleDownload(BuildContext context, Map<String, dynamic> documentData) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    String downloadPath = await _documentOperations.createDownloadPathForFile(documentData['document_name']);

    if (downloadPath == "Failed") {
      showSnackBarError("Could not access download directory", scaffoldContext);
    } else {
      _documentOperations.downloadDocument(documentData, downloadPath).then((String status) async {
        if (status != "Success") {
          showSnackBarError(status, scaffoldContext);
        } else {
          await _helper.showCustomNotificationAndroid(
              'Download Complete', // Notification title
              'Document ${documentData['document_name']} downloaded successfully', // Notification content
              downloadPath
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
      future: _helper.getIdTokenResult(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
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
          future: _documentOperations.fetchDocuments(userRole, userDomain, userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No documents available.'));
            }

            if (snapshot.data == null) {
              String errorMessage = snapshot.error?.toString() ??
                  'No documents available.';
              return Center(child: Text(errorMessage));
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
                actions: [
                  IconButton(
                    onPressed: () async {
                      await _handleLogout(context);
                    },
                    icon: const Icon(Icons.logout),
                  ),
                  // Add the search bar within the AppBar
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Enter Document or User Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh), // Reset filter icon
                              onPressed: () {
                                setState(() {
                                  _filteredDocuments = [];
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      onChanged: (searchText) {
                        delaySearch(searchText);
                      },
                    )
                  ),
                  Expanded(
                    child: StreamBuilder<dynamic>(
                      stream: mergedData,
                      builder: (context, snapshot) {

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.data == null) {
                          String errorMessage = snapshot.error?.toString() ??
                              'No documents available.';
                          return Center(child: Text(errorMessage));
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

                        List<DocumentSnapshot> displayDocuments =
                        createDocumentListForDisplayFromSnapshot(snapshot, data);

                        final domainMap = _documentOperations.groupDocuments(displayDocuments);

                        return ListView.builder(
                          itemCount: domainMap.length,
                          itemBuilder: (context, index) {
                            final domain = domainMap.keys.elementAt(index);
                            final yearMap = domainMap[domain]!;
                            final yearList = yearMap.keys.toList();

                            return ExpansionTile(
                              title: Text(
                                'Domain: $domain',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: yearList.map((year) {
                                final categoryMap = yearMap[year]!;
                                final categoryList = categoryMap.keys.toList();

                                return ExpansionTile(
                                  title: Text(
                                    'Year: $year',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children: categoryList.map((category) {
                                    final userMap = categoryMap[category]!;
                                    final userList = userMap.keys.toList();

                                    return ExpansionTile(
                                      title: Text(
                                        'Category: $category',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      children: userList.map((user) {
                                        final documents = userMap[user]!;
                                        return ExpansionTile(
                                          title: Text(
                                            'Customer: $user',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          children: [
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics: NeverScrollableScrollPhysics(),
                                              itemCount: documents.length,
                                              itemBuilder: (context, index) {
                                                final documentData = documents[index];
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8.0),
                                                  child: Card(
                                                    elevation: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        ListTile(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (
                                                                    context) =>
                                                                    DocumentDetailScreen(
                                                                        documentData: documentData),
                                                              ),
                                                            );
                                                          },
                                                          title: Text(
                                                            documentData['document_name'],
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                            ),
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                "Last Update: ${documentData['last_update'].toDate()}",
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontStyle: FontStyle.italic,
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                  color: documentData['is_new'] ? Colors.yellow : Colors.transparent,
                                                                  border: documentData['is_new']
                                                                      ? Border.all(
                                                                          color: Colors.yellow, // Border color
                                                                          width: 1.0, // Border width
                                                                        )
                                                                      : null,
                                                                  borderRadius: BorderRadius.circular(4.0), // Border radius
                                                                ),
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(4.0), // Add padding inside the box
                                                                  child: Text(
                                                                    "Status: ${documentData['is_new'] ? 'New' : 'Updated'}",
                                                                    style: const TextStyle(
                                                                      fontSize: 14,
                                                                      fontStyle: FontStyle.italic,
                                                                      color: Colors.black, // Text color
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
                                                            ElevatedButton.icon(
                                                              onPressed: () async {
                                                                handleDownload(context, documentData);
                                                              },
                                                              icon: const Icon(
                                                                  Icons.download),
                                                              label: const Text(
                                                                  'Download'),
                                                            ),
                                                            ElevatedButton.icon(
                                                              onPressed: () {
                                                                // Implement delete logic for this document
                                                                //deleteDocument(documentData);
                                                              },
                                                              icon: const Icon(
                                                                  Icons.delete),
                                                              label: const Text(
                                                                  'Delete'),
                                                            ),
                                                          ],
                                                        ),
                                                        ProgressBar(
                                                          downloadProgress: _documentOperations.getProgressNotifierDict()[documentData['id']],
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginScreen(),
    ));
  }
}

class DocumentDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? documentData;

  const DocumentDetailScreen({Key? key, this.documentData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (documentData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Document Detail'),
        ),
        body: const Center(
          child: Text('Document data not available.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(documentData?['document_name'] ?? ''),
      ),
      body: Center(
        child: Hero(
          tag: documentData?['id'] ?? '',
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    documentData?['document_name'] ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Add more document details here
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart'; // Import the LoginScreen to navigate back after logout
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async'; // Import the async package for using StreamController

class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({Key? key}) : super(key: key);

  @override
  _DocumentLibraryScreenState createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  final StreamController<QuerySnapshot> _streamController = StreamController<QuerySnapshot>.broadcast();
  List<StreamSubscription<QuerySnapshot>> subscriptions = [];
  final TextEditingController _searchController = TextEditingController();
  late List<DocumentSnapshot> allDocuments = []; // Store all documents here
  List<DocumentSnapshot>? _filteredDocuments = [];

  @override
  void dispose() {
    _streamController.close();
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void _cancelSubscriptions() {
    // Cancel previous listener if it exists
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    // Clear the list after canceling all subscriptions
    subscriptions.clear();
  }

  void _searchDocument(String documentName) {
    // Replace this with your logic to filter the document
    // Assuming you have a list of documents called 'documents' and 'documentName' is the search query.
    List<DocumentSnapshot> filteredDocuments = allDocuments
        .where((doc) => doc['document_name'].toLowerCase().contains(documentName.toLowerCase())).toList();

    print("Filter results:");
    print(filteredDocuments);
    print(filteredDocuments.length);

    setState(() {
      if (filteredDocuments.isNotEmpty) {
        _filteredDocuments = filteredDocuments;
      } else {
        _filteredDocuments = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
      future: _getIdTokenResult(),
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
          return const Center(child: Text('User not logged in.'));
        }

        String userDomainLowerCase = userDomain?.toLowerCase() ??
            'default_domain';
        CollectionReference documentsCollection;
        Stream<QuerySnapshot> query;

        final List<String> domainArray = [
          'PV-ALL',
          'PV-IBK',
          'PV-IBK-L',
          'PV-IM',
          'PV-EXT',
        ];

        if (userRole == 'client') {
          documentsCollection = FirebaseFirestore.instance.collection(
              'documents_$userDomainLowerCase');
          query = documentsCollection.where('owner', isEqualTo: userUid)
              .snapshots();
        } else {
          List<Stream<QuerySnapshot>> domainStreams = [];

          for (String item in domainArray) {
            String itemLowerCase = item.toLowerCase();
            CollectionReference domainCollection =
            FirebaseFirestore.instance.collection('documents_$itemLowerCase');
            if (userDomain == 'PV-ALL') {
              print("super userrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr");
              print('documents_$itemLowerCase');
              domainStreams.add(
                  domainCollection.where(userRole, isEqualTo: 'admin')
                      .snapshots());
            } else {
              domainStreams.add(
                  domainCollection.where('', isEqualTo: 'admin').where(
                      userDomain, isEqualTo: item).snapshots());
            }
          }

          _cancelSubscriptions(); // Cancel previous subscriptions before creating new ones
          for (Stream<QuerySnapshot> q in domainStreams) {
            Stream<QuerySnapshot> broadcastStream = q.asBroadcastStream();
            // Set up a new listener for each domain stream
            StreamSubscription<QuerySnapshot> subscription = broadcastStream
                .listen(
                  (snapshot) {
                _streamController.add(snapshot);
              },
              onError: (error) {
                print("Listener rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr");
                print(error.toString());
              },
              onDone: () {
                print("Done processing documents for this domain");
              },
            );

            // Add the subscription to the list for later cancellation
            subscriptions.add(subscription);
          }
          query = _streamController.stream;
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
                    labelText: 'Enter Document Name',
                    suffixIcon: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            _searchDocument(_searchController.text);
                          },
                        ),
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
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: query,
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      String errorMessage = 'Loading...';
                      return Center(child: Text(errorMessage));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      String errorMessage = snapshot.error?.toString() ??
                          'Error loading documents';
                      return Center(child: Text(errorMessage));
                    }

                    if (!snapshot.hasData ||
                        snapshot.data?.docs.isEmpty == true) {
                      return const Center(
                          child: Text('No documents available.'));
                    }

                    allDocuments = _filteredDocuments!.isEmpty
                        ? snapshot.data!.docs
                        : (_filteredDocuments ?? []);
                    final domainMap = groupDocuments(allDocuments);

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
                                                      subtitle: Text(
                                                        "Status: ${documentData['is_new'] ==
                                                            true
                                                            ? 'New'
                                                            : 'Updated'}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontStyle: FontStyle
                                                              .italic,
                                                        ),
                                                      ),
                                                    ),
                                                    ButtonBar(
                                                      alignment: MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        ElevatedButton.icon(
                                                          onPressed: () {
                                                            // Implement download logic for this document
                                                            downloadDocument(
                                                                documentData);
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
  }

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginScreen(),
    ));
  }

  Future<IdTokenResult> _getIdTokenResult() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    return await user.getIdTokenResult();
  }

  Map<String, Map<int, Map<String, Map<String, List<Map<String, dynamic>>>>>> groupDocuments(
      List<DocumentSnapshot> documents) {

    final domainMap = <String, Map<int, Map<String, Map<String, List<Map<String, dynamic>>>>>>{};

    for (final document in documents) {
      final documentData =
      document.data() as Map<String, dynamic>; // Extract data from the DocumentSnapshot
      final domain = documentData['user_domain'];
      final category = documentData['category'];
      final year = documentData['year'];
      final userMail = documentData['user_email'];
      final userName = documentData['user_name'];
      String user = userMail + " (" + userName + ")";

      // Group by domain
      if (!domainMap.containsKey(domain)) {
        domainMap[domain] = {};
      }

      // Grouping by year within domain
      if (!domainMap[domain]!.containsKey(year)) {
        domainMap[domain]![year] = {};
      }

      // Grouping by category within year
      if (!domainMap[domain]![year]!.containsKey(category)) {
        domainMap[domain]![year]![category] = {};
      }

      // Grouping by user mail/name within category
      if (!domainMap[domain]![year]![category]!.containsKey(user)) {
        domainMap[domain]![year]![category]![user] = [];
      }

      domainMap[domain]![year]![category]![user]!.add(documentData);
    }

    return domainMap;
  }

  void downloadDocument(Map<String, dynamic> documentData) {
    // Implement your download logic here
    // Use the 'documentData' variable to identify the selected document and initiate the download
    print("Download initiated for document:");
    print(documentData);
    final documentName = documentData['document_name'];
    final downloadUrl = documentData['document_url'];

    // Perform the actual download using the provided URL
    // You can use libraries like 'http' or 'dio' for making network requests
    // Example:
    downloadFunction(downloadUrl, documentName);
  }

  void downloadFunction(String downloadUrl, String documentName) async {
    // Use the 'http' package to initiate the download
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode == 200) {
      // Save the downloaded file to local storage or display the downloaded content
      // You can use libraries like 'path_provider' to manage local files
      // Example:
      final appDocumentsDirectory = await getApplicationDocumentsDirectory();
      final filePath = '${appDocumentsDirectory.path}/$documentName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      print("Download completed for $documentName");
      print("File saved at: $filePath");
    } else {
      print("Download failed for $documentName");
      print(response.statusCode);
    }
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

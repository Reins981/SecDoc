import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart'; // Import the LoginScreen to navigate back after logout
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Library',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DocumentLibraryScreen(),
    );
  }
}

class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({Key? key}) : super(key: key);

  @override
  _DocumentLibraryScreenState createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
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
        final userUid = customClaims?['sub'];
        print(userRole);
        print(userDomain);
        print(userUid);


        FirebaseAuth auth = FirebaseAuth.instance;
        User? user = auth.currentUser;
        print(user?.uid);
        if (user == null) {
          return const Center(child: Text('User not logged in.'));
        }

        String userDomainLowerCase = userDomain?.toLowerCase() ?? 'default_domain';

        CollectionReference documentsCollection =
        FirebaseFirestore.instance.collection('documents_$userDomainLowerCase');

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
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: documentsCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print(snapshot.data);
                String errorMessage = snapshot.error?.toString() ?? 'Error loading documents';
                return Center(child: Text(errorMessage));
              }

              if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
                return const Center(child: Text('No documents available.'));
              }

              final List<DocumentSnapshot> documents = snapshot.data!.docs;
              final groupedDocuments = groupDocuments(documents);

              return ListView.builder(
                itemCount: groupedDocuments.length,
                itemBuilder: (context, index) {
                  final group = groupedDocuments[index];
                  final domain = group[0]['user_domain'];
                  final category = group[0]['category'];
                  final year = group[0]['year'];

                  return GestureDetector(
                    onLongPress: () => downloadDocument(group[0]),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DocumentDetailScreen(documentData: group),
                              ),
                            );
                          },
                          splashColor:
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          child: Card(
                            elevation: 2,
                            child: ExpansionTile(
                              title: Text(
                                'Domain: $domain, Category: $category, Year: $year',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: group.length,
                                  itemBuilder: (context, index) {
                                    final documentData = group[index];
                                    return ListTile(
                                      title: Text(
                                        documentData['document_name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Status: ${documentData['is_new'] == true ? 'New' : 'Updated'}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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

  List<List<Map<String, dynamic>>> groupDocuments(
      List<DocumentSnapshot> documents) {
    final groupedDocuments = <List<Map<String, dynamic>>>[];
    final tempMap = <String, List<Map<String, dynamic>>>{};

    for (final document in documents) {
      final documentData =
      document.data() as Map<String, dynamic>; // Extract data from the DocumentSnapshot
      final domain = documentData['user_domain'];
      final category = documentData['category'];
      final year = documentData['year'];

      final key = '$domain-$category-$year';
      tempMap.putIfAbsent(key, () => []);
      tempMap[key]!.add(documentData); // Add the extracted document data to the map
    }

    tempMap.forEach((key, value) {
      groupedDocuments.add(value);
    });

    return groupedDocuments;
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
  final List<Map<String, dynamic>>? documentData;

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
        title: Text(documentData?[0]['document_name'] ?? ''),
      ),
      body: Center(
        child: Hero(
          tag: documentData?[0]['id'] ?? '',
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    documentData?[0]['document_name'] ?? '',
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


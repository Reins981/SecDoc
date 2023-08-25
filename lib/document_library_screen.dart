import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // Import the LoginScreen to navigate back after logout

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

class DocumentLibraryScreen extends StatelessWidget {
  const DocumentLibraryScreen({Key? key}) : super(key: key);

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
                return const Center(child: Text('Error loading documents.'));
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

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DocumentDetailScreen(documentData: documentData),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
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

  List<List<Map<String, dynamic>>> groupDocuments(List<DocumentSnapshot> documents) {
    final groupedDocuments = <List<Map<String, dynamic>>>[];
    final tempMap = <String, List<Map<String, dynamic>>>{};

    for (final document in documents) {
      final documentData = document.data() as Map<String, dynamic>;
      final domain = documentData['user_domain'];
      final category = documentData['category'];
      final year = documentData['year'];

      final key = '$domain-$category-$year';
      tempMap.putIfAbsent(key, () => []);
      tempMap[key]!.add(documentData);
    }

    tempMap.forEach((key, value) {
      groupedDocuments.add(value);
    });

    return groupedDocuments;
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

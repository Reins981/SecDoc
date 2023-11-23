import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart'; // Import the LoginScreen to navigate back after logout
import 'dart:io';
import 'dart:async'; // Import the async package for using StreamController
import 'package:rxdart/rxdart.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'progress_bar.dart';


class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({Key? key}) : super(key: key);

  @override
  _DocumentLibraryScreenState createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  final StreamController<QuerySnapshot> _streamController = StreamController<QuerySnapshot>.broadcast();
  List<StreamSubscription<QuerySnapshot>> subscriptions = [];
  final TextEditingController _searchController = TextEditingController();
  late List<DocumentSnapshot> allDocumentsOrig = []; // Store all documents here
  List<DocumentSnapshot>? _filteredDocuments = [];
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late Map<String, dynamic> _progressNotifierDict = {};
  Timer? _debounceTimer;

  @override
  void dispose() {
    _streamController.close();
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void _openFile(String filePath) {
    // You'll need to use platform-specific code to open the file
    // For Android, you can use plugins like 'open_file' or 'android_intent'
    // For iOS, you might use 'open_file' or 'url_launcher'

    // Example for opening a file on Android using the 'open_file' plugin
    print("Open file triggered");
    OpenFile.open(filePath);
  }

  // Handle the notification tap event
  void onSelectNotification(notification) async {
    print("onSelectNotification callback triggered");
    print(notification.payload);
    if (notification.payload != null) {
      // Open the file using the saved directory path (payload)
      // Example: Use platform-specific file opening mechanisms
      // For Android:
      // Open the file from the saved directory using the platform's file opener
      // For iOS:
      // Use iOS-specific file opening mechanisms
      _openFile(notification.payload);
    }
  }

  Future<void> initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );
  }

  Future<void> showCustomNotification(
      String title, String content, String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'document_download',
      'download_channel',
      channelDescription: 'Download Channel',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Unique ID for the notification
      title,
      content,
      notificationDetails,
      payload: filePath,
    );
  }

  void _cancelSubscriptions() {
    // Cancel previous listener if it exists
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    // Clear the list after canceling all subscriptions
    subscriptions.clear();
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

  Future<dynamic> fetchDocuments(String? userRole, String? userDomain, String? userUid) async {

    dynamic result = await _fetchDocuments(userRole, userDomain, userUid);
    return result;

  }

  Future<dynamic> _fetchDocuments(String? userRole, String? userDomain, String? userUid) async {

    String userDomainLowerCase = userDomain?.toLowerCase() ??
        'default_domain';
    CollectionReference documentsCollection;
    var result;

    final List<String> domainArray = [
      'PV-ALL',
      'PV-IBK',
      'PV-IBK-L',
      'PV-IM',
      'PV-EXT',
    ];

    // First fetch the documents based on the user domain for clients and domain admins
    // Fetch all documents regardless of the domain for super admins
    if (userRole == 'client' || (userRole == 'admin' && userDomain != 'PV-ALL')) {
      documentsCollection = FirebaseFirestore.instance.collection(
          'documents_$userDomainLowerCase');

      // Clients can only access their own documents, admins all of them
      if (userRole == 'client') {
        result = documentsCollection
            .where('owner', isEqualTo: userUid)
            .snapshots();
      } else {
        result = documentsCollection
            .where('user_domain', isEqualTo: userDomain)
            .snapshots();
      }
    } else {

      List<Stream<QuerySnapshot>> domainStreams = [];

      for (String item in domainArray) {
        String domainLowerCase = item.toLowerCase();
        CollectionReference domainCollection =
        FirebaseFirestore.instance.collection('documents_$domainLowerCase');
        domainStreams.add(domainCollection.snapshots());
      }

      result = domainStreams;

    }

    return result;
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
          future: fetchDocuments(userRole, userDomain, userUid),
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

                        List<DocumentSnapshot> displayDocuments = [];
                        if (_filteredDocuments != null) {
                          if (_filteredDocuments!.isEmpty) {
                            if (data is List<Stream<QuerySnapshot>>) {
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

                        final domainMap = groupDocuments(displayDocuments);

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
                                                        ProgressBar(
                                                          downloadProgress: _progressNotifierDict[documentData['id']],
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
      // Add the unique id to the document data
      documentData['id'] = document.id;
      final domain = documentData['user_domain'];
      final category = documentData['category'];
      final year = documentData['year'];
      final userMail = documentData['user_email'];
      final userName = documentData['user_name'];
      String user = userMail + " (" + userName + ")";

      // Create and assign a ValueNotifier for the current document
      _progressNotifierDict[document.id] = ValueNotifier<double>(0.0);

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
    final documentId = documentData['id'];

    // Perform the actual download using the provided URL
    // Capture the context before the async call
    final scaffoldContext = ScaffoldMessenger.of(context);
    _downloadFunction(downloadUrl, documentName, documentId, scaffoldContext);
  }

  void _downloadFunction(
      String downloadUrl,
      String documentName,
      String documentId,
      ScaffoldMessengerState context) async {

    // First Rest the Progress Bar
    _progressNotifierDict[documentId].value = 0;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        // Check and request storage permission if needed
        if (!(await Permission.storage.isGranted)) {
          await Permission.storage.request();
        }
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        context.showSnackBar(
          const SnackBar(
            content: Text('Error: Could not access download directory'),
          ),
        );
        return;
      }

      final savedDir = directory.path;
      final filePath = '$savedDir/$documentName';
      print("Saving document $documentName to dir: $savedDir");

      final dio = Dio();
      final response = await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          print("In onReceiveProgress");
          if (total != -1) {
              double progress = (received / total) * 100;
              _progressNotifierDict[documentId].value = progress;

          }
        },
      );

      // Act on the result
      switch (response.statusCode) {
        case 200:
          // Show a custom notification indicating successful download
          await showCustomNotification(
              'Download Complete', // Notification title
              'Document $documentName downloaded successfully', // Notification content
              filePath
          );
        default:
          String errorMessage = '${response.statusMessage} - Status Code: ${response.statusCode}';
          context.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
            ),
          );
      }

    } on PlatformException catch (e) {
      // Handle platform exceptions (e.g., missing permission, platform-specific issues)
      // Show a SnackBar for the error
      context.showSnackBar(
        SnackBar(
          content: Text('Error: $e'), // Show the error message in the SnackBar
        ),
      );
    } catch (e) {
      // Handle other potential exceptions during download
      // Show a SnackBar for the error
      context.showSnackBar(
        SnackBar(
          content: Text('Error: $e'), // Show the error message in the SnackBar
        ),
      );
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

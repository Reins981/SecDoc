import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async'; // Import the async package for using StreamController
import 'package:dio/dio.dart';
import 'document.dart';


class Helper {

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

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

  Future<void> showCustomNotificationAndroid(
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

  Future<IdTokenResult> getIdTokenResult() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    return await user.getIdTokenResult();
  }
}


class DocumentOperations {

  late Map<String, dynamic> _progressNotifierDict = {};
  late String downloadPath;

  Map<String, dynamic> getProgressNotifierDict() {
    return _progressNotifierDict;
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

  Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>> groupDocuments(
      List<DocumentSnapshot> documents) {

    final domainMap = <String, Map<int, Map<String, Map<String, DocumentRepository>>>>{};

    for (final document in documents) {
      final documentData =
      document.data() as Map<String, dynamic>; // Extract data from the DocumentSnapshot
      // Add the unique id to the document data
      final id = document.id;
      final domain = documentData['user_domain'];
      final category = documentData['category'];
      final year = documentData['year'];
      final userMail = documentData['user_email'];
      final userName = documentData['user_name'];
      final name = documentData['document_name'];
      final owner = documentData['owner'];
      final lastUpdate = documentData['last_update'];
      final isNew= documentData['is_new'];
      final deletedAt = documentData['deleted_at'];
      final documentUrl = documentData['document_url'];
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
        domainMap[domain]![year]![category]![user] = DocumentRepository();
      }

      // Create a new Document
      Document newDoc = Document(
          id: id,
          name: name,
          owner: owner,
          lastUpdate: lastUpdate,
          isNew: isNew,
          deletedAt: deletedAt,
          documentUrl: documentUrl,
          domain: domain,
          category: category,
          year: year,
          userMail: userMail,
          userName: userName);

      domainMap[domain]![year]![category]![user]!.addDocument(newDoc);
    }

    return domainMap;
  }

  Future<String> createDownloadPathForFile(String fileName) async {
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
      return "Failed";
    }

    final savedDir = directory.path;

    return '$savedDir/$fileName';

  }

  Future<String> downloadDocument(Document document, String downloadPath) async {
    // Implement your download logic here
    // Use the 'documentData' variable to identify the selected document and initiate the download
    final documentName = document.name;
    final downloadUrl = document.documentUrl;
    final documentId = document.id;

    // Perform the actual download using the provided URL
    return _downloadFunction(downloadUrl, documentName, documentId, downloadPath);
  }

  Future<String> _downloadFunction(
      String downloadUrl,
      String documentName,
      String documentId,
      String downloadPath) async {

    // First Reset the Progress Bar
    _progressNotifierDict[documentId].value = 0.0;
    late String errorMessage;

    try {
      final dio = Dio();
      final response = await dio.download(
        downloadUrl,
        downloadPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total) * 100;
            _progressNotifierDict[documentId].value = progress;
          }
        },
      );

      // Act on the result
      switch (response.statusCode) {
        case 200:
          return 'Success';
        default:
          errorMessage = '${response.statusMessage} - Status Code: ${response.statusCode}';
          return errorMessage;
      }

    } on PlatformException catch (e) {
      // Handle platform exceptions (e.g., missing permission, platform-specific issues)
      errorMessage = '$e';
      return errorMessage;

    } catch (e) {
      // Handle other potential exceptions during download
      errorMessage = '$e';
      return errorMessage;
    }
  }

}


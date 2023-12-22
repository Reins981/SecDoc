import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:randomstring_dart/randomstring_dart.dart';
import 'dart:convert';
import 'user.dart';

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

  String getRandomString() {
    final rs = RandomString();
    return rs.getRandomString(
      lowersCount: 10,
      uppersCount: 10,
      numbersCount: 2,
      specialsCount: 3,
      specials: '_%&?!}[]{<>-',
      canSpecialRepeat: false,
    );
  }

  Future<Map<String, String>> getSignedUrl(String documentPath, String token) async {
    const String serverUrl = 'YOUR_FLASK_SERVER_URL/get_signed_url';
    Map<String, String> result = {};

    Map<String, dynamic> requestData = {'document_path': documentPath};

    final response = await http.post(
      Uri.parse(serverUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String signedUrl = jsonResponse['signed_url']; // Extracting the signed URL
      return {
        'status': 'Success',
        'signedUrl': signedUrl,
        'error': ""
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 'Failed',
        'signedUrl': "",
        'error': "The Client token either is invalid or does not exist"
      };
    } else {
      return {
        'status': 'Failed',
        'signedUrl': "",
        'error': "The server responded with Status Code: ${response.statusCode.toString()}"
      };
    }
  }

  Future<int> getTotalBytes(List<File> files) async {
    int totalBytes = 0;
    for (File file in files) {
      int size = await file.length();
      totalBytes += size;
    }
    return totalBytes;
  }

  void showSnackBar(String message, String messageType, ScaffoldMessengerState context, {int duration = 4}) {
    Color backgroundColor = messageType == "Error" ? Colors.red : Colors.yellow;
    Color fontColor = messageType == "Error" ? Colors.white : Colors.black;

    context.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: fontColor,
            letterSpacing: 1.0,
          ),
        ),
        duration: Duration(seconds: duration),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        elevation: 6,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Center showStatus(String status) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          status,
          style: GoogleFonts.lato(
            fontSize: 10,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
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

  Future<List<UserInstance>> fetchUsersFromServer() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      String? idToken;

      if (user != null) {
        idToken = await user.getIdToken();
      }

      final response = await http.get(
          headers: <String, String>{
            'Authorization': 'Bearer $idToken',
          },
          Uri.parse('https://127.0.0.1:5000/get_all_users')
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body)['users'];
        return usersJson.map((json) => UserInstance.fromJson(json)).toList();
      } else {
        throw 'Failed to fetch users: ${response.statusCode}';
      }
    } catch (e) {
      throw '$e';
    }
  }

  Future<void> sendPushNotificationRequestToServer(String userId) async {

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    String? idToken;

    if (user != null) {
      idToken = await user.getIdToken();
    }

    try {
      final response = await http.post(
        Uri.parse('https://127.0.0.1:5000/push_notification'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(<String, String>{
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('Psu notification sent to server successfully');
      } else {
        print('Failed to send Push notification to server: ${response.body}');
      }
    } catch (e) {
      print('Error sending Push notification to server: $e');
    }
  }

  Future<IdTokenResult> getIdTokenResult(User? thisUser) async {
    final User? user = thisUser ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not signed in!');
    }

    return await user.getIdTokenResult();
  }

  Future<Map<String, dynamic>> getCurrentUserDetails() async {

    try {
      IdTokenResult idTokenResult = await getIdTokenResult(null);

      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      final userUid = user!.uid;
      final userEmail = user.email;
      final userName = user.displayName;

      final token = idTokenResult.token;
      final customClaims = idTokenResult.claims;
      final userRole = customClaims?['role'];
      final userDomain = customClaims?['domain'];
      final disabled = customClaims?['disabled'];
      final verified = customClaims?['verified'];

      return {
        'userUid': userUid,
        'userEmail': userEmail,
        'userName': userName,
        'userRole': userRole,
        'userDomain': userDomain,
        'token': token,
        'disabled': disabled,
        'verified': verified
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserDetails(List<Map<String, dynamic>> users) async {

    List<Map<String, dynamic>> userDetails = [];
    for (Map<String, dynamic> user in users) {
      try {
        final userUid = user['uid'];
        final userEmail = user['email'];
        final userName = user['display_name'];

        final userRole = user['customClaims']['role'];
        final userDomain = user['customClaims']['domain'];
        final disabled = user['customClaims']['disabled'];
        final verified = user['customClaims']['verified'];

        userDetails.add( {
          'userUid': userUid,
          'userEmail': userEmail,
          'userName': userName,
          'userRole': userRole,
          'userDomain': userDomain,
          'disabled': disabled,
          'verified': verified
        });
      } catch (e) {
        rethrow;
      }
    }
    return userDetails;
  }

}


class DocumentOperations {

  late Map<String, dynamic> _progressNotifierDict = {};
  late String downloadPath;

  Map<String, dynamic> getProgressNotifierDict() {
    return _progressNotifierDict;
  }

  void setProgressNotifierDictValue(String documentId) {
    if (!_progressNotifierDict.containsKey(documentId)) {
      _progressNotifierDict[documentId] = ValueNotifier<double>(0.0);
    }
  }

  void resetProgressNotifierDictValue(String documentId) {
    if (_progressNotifierDict.containsKey(documentId)) {
      _progressNotifierDict[documentId].value = 0.0;
    }
  }

  void clearProgressNotifierDict() {
    _progressNotifierDict.clear();
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
      List<DocumentSnapshot> documents, String userRole) {

    final domainMap = <String, Map<int, Map<String, Map<String, DocumentRepository>>>>{};

    for (final document in documents) {
      final documentData =
      document.data() as Map<String, dynamic>; // Extract data from the DocumentSnapshot
      // Add the unique id to the document data
      final id = document.id;
      final domain = documentData['user_domain'];
      final category = documentData['category'];
      final year = documentData['year'];
      final userMail = userRole == 'client' ? documentData['from_email'] : documentData['user_email'];
      final userName = userRole == 'client' ? documentData['from_user_name'] : documentData['user_name'];
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

  bool isImage(String documentUrl) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.ico', '.svg'];
    final lowerCaseUrl = documentUrl.toLowerCase();
    return imageExtensions.any((ext) => lowerCaseUrl.endsWith(ext));
  }

  bool isText(String documentUrl) {
    final textExtensions = ['.txt'];
    final lowerCaseUrl = documentUrl.toLowerCase();
    return textExtensions.any((ext) => lowerCaseUrl.endsWith(ext));
  }

  bool isPdf(String documentUrl) {
    final pdfExtensions = ['.pdf'];
    final lowerCaseUrl = documentUrl.toLowerCase();
    return pdfExtensions.any((ext) => lowerCaseUrl.endsWith(ext));
  }

  Future<String> deleteDocument(String documentId, Document document, String collectionPath) async {
    try {
      final CollectionReference collectionReference =
      FirebaseFirestore.instance.collection(collectionPath);

      // Delete the document
      await collectionReference.doc(documentId).delete();

      String status = await deleteFileFromStorage(document);

      return status == 'Success' ? 'Success' : status;
    } catch (e) {
      String errorMessage = '$e';
      return errorMessage;
    }
  }

  Future<String> deleteFileFromStorage(Document document) async {

    String userDomain = document.domain.toLowerCase();
    String userName = document.userName;
    int year = document.year;
    String category = document.category;
    String owner = document.owner;
    String documentName = document.name;

    String documentPath =
        '$userDomain/'
        '$category/'
        '$year/'
        '$owner/'
        '$userName/'
        '$documentName';
    print(documentPath);

    try {
      final Reference ref = FirebaseStorage.instance.ref().child(documentPath);
      await ref.delete();
      return 'Success';
    } catch (e) {
      String errorMessage = '$e';
      return errorMessage;
    }
  }


  Future<Map<String, dynamic>> fetchDocumentContent(String documentUrl, String documentName) async {
    bool isDocPdf = isPdf(documentName);
    bool isImg = isImage(documentName);
    bool isTxt = isText(documentName);

    String downloadPath = await createDownloadPathForFile(documentName);

    try {
      final response = await http.get(Uri.parse(documentUrl));

      if (response.statusCode == 200) {

        dynamic content;
        if (isDocPdf || isImg) {
          Uint8List bytes = response.bodyBytes;
          content = bytes;
        } else if (isTxt) {
          content = response.body.toString();
        } else {
          content = null;
        }

        return {
          'content': content, // Document content
          'isPdf': isDocPdf, // Boolean indicating if it's a PDF
          'isImg': isImg,
          'isTxt': isTxt,
        };
      } else {
        return {'bytes': null, 'isPdf': false, 'isImg': false, 'isTxt': false}; // Return null bytes and false for error cases
      }
    } catch (e) {
      return {'bytes': null, 'isPdf': false, 'isImg': false, 'isTxt': false}; // Return null bytes and false for error cases
    }
  }

  Future<List<File>> selectDocumentsForUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    List<File> files = [];

    if (result != null) {
      files = result.files.map((file) => File(file.path!)).toList();
    }
    return files;
  }

  Future<Map<String, String>> _addDocument(
      Reference ref,
      Map<String, dynamic> userDetails,
      String documentName,
      String category,
      ) async {
    String userDomain = userDetails['userDomain'];
    String userRole = userDetails['userRole'];
    String userDomainLowerCase = userDomain.toLowerCase();
    DateTime expirationTime = DateTime.now().add(const Duration(days: 365)); // 1 year from now
    String downloadURL = await ref.getDownloadURL();
    String errorMessage = "";
    bool isError = false;

    try {
      // Check if the document exists
      QuerySnapshot existingDocs = userRole == 'client'
          ? await FirebaseFirestore.instance
            .collection('documents_$userDomainLowerCase')
            .where('owner', isEqualTo: userDetails['userUid'])
            .where('category', isEqualTo: category)
            .where('document_name', isEqualTo: documentName)
            .where('user_domain', isEqualTo: userDomain)
            .get()
          : await FirebaseFirestore.instance
          .collection('documents_$userDomainLowerCase')
          .where('owner', isEqualTo: userDetails['userUid'])
          .where('category', isEqualTo: category)
          .where('document_name', isEqualTo: documentName)
          .where('user_domain', isEqualTo: userDomain)
          .get() ;

      if (existingDocs.docs.isNotEmpty) {
        print('Updating existing document...: $documentName');
        // Update the existing document
        String docId = existingDocs.docs[0].id;
        DocumentReference documentRef =
        FirebaseFirestore.instance.collection('documents_$userDomainLowerCase').doc(
            docId);

        await documentRef.update({
          "last_update": FieldValue.serverTimestamp(),
          "is_new": false
          // Add fields to update here as needed
        });

        print('Updated existing document: $documentName');
      } else {
        print('Adding new document: $documentName');
        print('documents_$userDomainLowerCase');
        // Create a new document
        await FirebaseFirestore.instance.collection('documents_$userDomainLowerCase')
            .add({
          "from_email": userDetails['userEmail'],
          "from_user_name": userDetails['userName'],
          "from_role": userDetails['userRole'],
          "user_name": userDetails['userName'],
          "user_email": userDetails['userEmail'],
          "owner": userDetails['userUid'],
          "category": category,
          "user_domain": userDomain,
          "document_name": documentName,
          "document_url": downloadURL,
          "year": DateTime
              .now()
              .year,
          "deleted_at": null,
          "last_update": FieldValue.serverTimestamp(),
          "is_new": true,
        });

        print('Added new document...: $documentName');
      }
    } catch (e) {
      errorMessage = '$e';
      isError = true;
    }

    return isError ? {
      'status': 'Error',
      'message': errorMessage
    } : {
      'status': 'Success',
      'message': ""
    };
  }

  Future<void> uploadDocuments(String? documentId, File? specificFile, ScaffoldMessengerState context) async {
    Helper _helper = Helper();
    List<File> files = [];
    if (specificFile == null) {
      files = await selectDocumentsForUpload();
    } else {
      files = [specificFile];
    }

    String? errorMessage;
    if (files.isEmpty) {
      errorMessage = "No Documents available for upload";
      _helper.showSnackBar(errorMessage, 'Error', context);
      return;
    }

    if (documentId == null) {
      errorMessage = "Document Id must not be null";
      _helper.showSnackBar(errorMessage, 'Error', context);
      return;
    }

    int totalBytes = await _helper.getTotalBytes(files);
    int totalBytesTransferred = 0;

    Completer<void> uploadCompleter = Completer(); // Create a Completer
    int filesCount = files.length; // Count the total number of files
    int uploadedFilesCount = 0; // Counter for uploaded files

    try {
      Map<String, dynamic> userDetails = await _helper.getCurrentUserDetails();
      String category = "MyDocs";
      int year = DateTime.now().year;
      String userDomain = userDetails['userDomain'].toLowerCase();
      String token = userDetails['token'];

      // First Reset the Progress Bar
      _progressNotifierDict[documentId].value = 0.0;
      double progress = 0.0;

      for (File file in files) {
        String documentName = file.path.split('/').last; // Get the document name
        String documentPath =
            '$userDomain/'
            '$category/'
            '$year/'
            '${userDetails['userUid']}/'
            '${userDetails['userName']}/'
            '$documentName';

        //Map<String, dynamic> result = await _helper.getSignedUrl(documentPath, token);

        // TODO and use this instead of getDownloadURL
        /*if (result['status'] == 'Failed') {
          return result['error'];
        }
        signedUrl = result['signedUrl'];
         */

        Reference ref = FirebaseStorage.instance.ref().child(documentPath);
        try {
          ref.putFile(file).snapshotEvents.listen((taskSnapshot) async {
            switch (taskSnapshot.state) {
              case TaskState.running:
                totalBytesTransferred += taskSnapshot.bytesTransferred;
                // Might happen if the event is triggered several times for the same file
                if (totalBytesTransferred >= totalBytes) {
                  progress = 100.0;
                } else {
                  progress = (totalBytesTransferred / totalBytes) * 100.0;
                }
                _progressNotifierDict[documentId].value = progress;
                break;
              case TaskState.paused:
                String errorMessage = "Upload task is paused for $documentName";
                _helper.showSnackBar(errorMessage, 'Error', context);
                break;
              case TaskState.success:
                Map<String, String> result = await _addDocument(ref, userDetails, documentName, category);
                if (result['status'] == 'Error') {
                  _progressNotifierDict[documentId].value = 0.0;
                  String? errorMessage = result['message'];
                  _helper.showSnackBar(errorMessage ?? "Default Error Message", 'Error', context);
                } else {
                  _helper.showSnackBar("Document $documentName uploaded successfully", 'Success', context);
                }
                uploadedFilesCount++;
                if (uploadedFilesCount == filesCount) {
                  uploadCompleter.complete();
                }
                break;
              case TaskState.canceled:
                String errorMessage = "Upload task is cancelled for $documentName";
                _helper.showSnackBar(errorMessage, 'Error', context);
                break;
              case TaskState.error:
                String errorMessage = "Upload task produced and error for $documentName";
                _helper.showSnackBar(errorMessage, 'Error', context);
                break;
              default:
                String errorMessage = "Upload task produced and error for $documentName";
                _helper.showSnackBar(errorMessage, 'Error', context);
                break;
            }
          });
        } catch (e) {
          _helper.showSnackBar('$e', 'Error', context);
          return;
        }
      }

      try {
        List<UserInstance> allUsers = await _helper.fetchUsersFromServer();
        // ToDo send a notifiction to the admin users
      } catch (e) {
        _helper.showSnackBar('$e', 'Error', context);
        return;
      }

    } catch (e) {
      _helper.showSnackBar('$e', 'Error', context);
      return;
    }
    return uploadCompleter.future;
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


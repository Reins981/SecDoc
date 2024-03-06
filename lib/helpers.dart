import 'dart:math';

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
import 'package:rxdart/rxdart.dart';
import 'document.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:randomstring_dart/randomstring_dart.dart';
import 'dart:convert';
import 'user.dart';
import 'mail_settings.dart';
import 'package:sendgrid_mailer/sendgrid_mailer.dart';
import 'text_contents.dart';
import 'language_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class Helper {

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String _selectedLanguage = 'German';
  String helperUserNotSignedInGerman = getTextContentGerman('helperUserNotSignedIn');
  String helperUserNotSignedInEnglish = getTextContentEnglish('helperUserNotSignedIn');

  Future<void> _loadLanguage() async {
    final selectedLanguage = await LanguageService.getLanguage();
    _selectedLanguage = selectedLanguage;
  }

  void _openFile(String filePath) {
    OpenFile.open(filePath);
  }

  List<UserInstance> createUserInstanceTestData() {
    List<UserInstance> users = [
      UserInstance(
        uid: 'yw9k4KL3X4XOH4b6ExQRusFcBPl2',
        email: 'reins981@gmail.com',
        domain: 'PV-IBK',
        userName: 'Rettung',
        role: 'client',
        disabled: false,
        verified: true,
      ),
      UserInstance(
        uid: 'P8pMj8V2pzRwEkaH4saHQu3csAr2',
        email: 'james_dean@pv.com',
        domain: 'PV-IBK',
        userName: 'james',
        role: 'admin',
        disabled: false,
        verified: true,
      ),
      UserInstance(
        uid: 'pZUGWSazwtf8ybdzESh3tTyGSQ72',
        email: 'default2402@gmail.com',
        domain: 'PV-IBK-L',
        userName: 'Polizei',
        role: 'client',
        disabled: false,
        verified: true,
      ),
      UserInstance(
        uid: 'C7OLLRGheghFM4QTcrbHMOWD4au2',
        email: 'user@mail.com',
        domain: 'PV-EXT',
        userName: 'user_test',
        role: 'client',
        disabled: false,
        verified: false,
      ),
      UserInstance(
        uid: 'E7bMBQoiFMhWUkzBjfyHD97opXT2',
        email: 'john_doe@pv.com',
        domain: 'PV-ALL',
        userName: 'john',
        role: 'super_admin',
        disabled: false,
        verified: true,
      ),
      // Add more test entries as needed
    ];

    // Use the 'users' list for testing purposes
    for (var user in users) {
      print(user.toJson());
    }

    return users;
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

  Future<void> sendNotificationMail(
      String userName,
      String fromEmailAddress,
      String toEmailAddress,
      String adminUserName,
      ) async {
    Helper helper = Helper();
    // Replace "YOUR_API_KEY" with your actual SendGrid API key
    final sendgrid = Mailer(mailPassword);

    final String name = "$userName $fromEmailAddress";
    final fromAddress = Address(mailDefaultSender, name);
    Address toAddress = Address(toEmailAddress, adminUserName);
    Content htmlContent = Content('text/html', '''
      <html>
        <body style="font-family: Arial, sans-serif; margin: 0; padding: 0;">
        <div style="background-color: #f5f5f5;">
            <div style="background-color: #ffffff; margin: 0 auto; max-width: 600px;">
                <div style="padding: 20px; text-align: center;">
                    <h1 style="color: #333333;">Welcome back to PuraVida GmbH $adminUserName</h1>
                    <p style="color: #555555;">Client "$name" has uploaded new document(s).</p>
                    <p style="color: #555555;">Please open your mobile App to access them.</p>
                </div>
                <div style="padding: 20px; background-color: #f5f5f5; text-align: center;">
                    <p style="color: #777777;">If you have any questions or need assistance, please contact our support team at <a href="mailto:support@pura_vida.com" style="color: #007bff;">support@pura_vida.com</a>.</p>
                    <p style="color: #777777;">Strasse XXX, 6021 Absam, Tirol, Austria</p>
                </div>
            </div>
        </div>
    </body>
      </html>
    ''');

    final subject = 'New Document(s) from $userName';
    Personalization personalization = Personalization([toAddress]);

    final email = Email([personalization], fromAddress, subject, content: [htmlContent]);

    try {
      await sendgrid.send(email).then((result) {
        print("Successfully sent Notification mail to $toEmailAddress");
      }).catchError((e) {
        print('$e');
      });
    } catch (e) {
        print('$e');
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
        print('Push notification sent to server successfully');
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
      _loadLanguage();
      String errorMessage = _selectedLanguage == 'German' ? helperUserNotSignedInGerman: helperUserNotSignedInEnglish;
      throw Exception(errorMessage);
    }

    return await user.getIdTokenResult();
  }

  List<Map<String, dynamic>> createUserDetailsForUserInstances(List<UserInstance> users) {
    List<Map<String, dynamic>> userDetails = [];
    for (UserInstance user in users) {
      final userUid = user.uid;
      final userEmail = user.email;
      final userName = user.userName;
      const token = null;
      final userRole = user.role;
      final userDomain = user.domain;
      final disabled = user.disabled;
      final verified = user.verified;
      userDetails.add({
        'userUid': userUid,
        'userEmail': userEmail,
        'userName': userName,
        'userRole': userRole,
        'userDomain': userDomain,
        'token': token,
        'disabled': disabled,
        'verified': verified
      });
    }
    return userDetails;
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

  List<String> createDomainListFromUsers(List<UserInstance> users) {
    List<String> domains = [];
    for (UserInstance user in users) {
      if (!domains.contains(user.domain)) {
        domains.add(user.domain);
      }
    }
    return domains;
  }

  Future<List<Map<String, dynamic>>> getUserDetails(List<UserInstance> users) async {

    List<Map<String, dynamic>> userDetails = [];
    for (UserInstance user in users) {
      try {
        final userUid = user.uid;
        final userEmail = user.email;
        final userName = user.userName;

        final userRole = user.role;
        final userDomain = user.domain;
        final disabled = user.disabled;
        final verified = user.verified;

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
  String _selectedLanguage = 'German';
  final String documentLibraryCategoryCustomerClientEnglish = getTextContentEnglish("documentLibraryCategoryCustomerClient");
  final String docOperationsNoDocsGerman = getTextContentGerman("docOperationsNoDocs");
  final String docOperationsNoDocsEnglish = getTextContentEnglish("docOperationsNoDocs");
  final String docOperationsUploadSuccessGerman = getTextContentGerman("docOperationsUploadSuccess");
  final String docOperationsUploadSuccessEnglish = getTextContentEnglish("docOperationsUploadSuccess");

  Future<void> _loadLanguage() async {
    final selectedLanguage = await LanguageService.getLanguage();
    _selectedLanguage = selectedLanguage;
  }

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
        // Create two separate streams for each query
        Stream<QuerySnapshot> stream1 = documentsCollection.where('owner', isEqualTo: userUid).snapshots();
        Stream<QuerySnapshot> stream2 = documentsCollection.where('selected_user', isEqualTo: userUid).snapshots();

        // Combine the streams using merge
        result = Rx.merge([stream1, stream2]);
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
      final selectedUser = documentData['selected_user'];
      final lastUpdate = documentData['last_update'];
      final isNew = documentData['is_new'];
      final viewed = documentData['viewed'];
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
          selectedUser: selectedUser,
          lastUpdate: lastUpdate,
          isNew: isNew,
          viewed: viewed,
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
    String selectedUser = document.selectedUser;
    String documentName = document.name;

    String documentPath =
        '$userDomain/'
        '$category/'
        '$year/'
        '$selectedUser/'
        '$userName/'
        '$documentName';

    print('Deleting $documentPath');

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

  Future<Map<String, String>> updateDocumentFieldAsBool(
      Map<String, dynamic> userDetails,
      String docId,
      String fieldName,
      bool fieldValue
      ) async {

    String userDomain = userDetails['userDomain'];
    String userDomainLowerCase = userDomain.toLowerCase();
    String errorMessage = "";
    bool isError = false;

    try {
      print('Updating existing document...: $docId for documents_$userDomainLowerCase');
      // Update the existing document
      DocumentReference documentRef =
      FirebaseFirestore.instance.collection('documents_$userDomainLowerCase')
          .doc(
          docId);

      await documentRef.update({
        fieldName: fieldValue
      });
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
            .where('selected_user', isEqualTo: userDetails['userUid'])
            .where('category', isEqualTo: category)
            .where('document_name', isEqualTo: documentName)
            .where('user_domain', isEqualTo: userDomain)
            .get()
          : await FirebaseFirestore.instance
          .collection('documents_$userDomainLowerCase')
          .where('owner', isEqualTo: userDetails['userUid'])
          .where('selected_user', isEqualTo: userDetails['userUid'])
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
          "is_new": false,
          "viewed": false
          // Add fields to update here as needed
        });
      } else {
        print('Adding new document: $documentName');
        // Create a new document
        await FirebaseFirestore.instance.collection('documents_$userDomainLowerCase')
            .add({
          "from_email": userDetails['userEmail'],
          "from_user_name": userDetails['userName'],
          "from_role": userDetails['userRole'],
          "user_name": userDetails['userName'],
          "user_email": userDetails['userEmail'],
          "owner": userDetails['userUid'],
          "selected_user": userDetails['userUid'],
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
          "viewed": false
        });
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

  String addTimestampToDocumentName(String documentName) {
    DateTime now = DateTime.now();
    String timestamp = now.toIso8601String(); // Use ISO8601 format for a unique timestamp
    String extension = documentName.split('.').last;  // Get the extension
    documentName = path.basenameWithoutExtension(documentName); // Extract the basename
    // Concatenate timestamp and extension to the original document name
    String newDocumentName = '${documentName}_$timestamp.$extension';

    return newDocumentName;
  }

  File changeDocumentName(File file, String newDocumentName) {
    String directory = file.parent.path;
    String newPath = '$directory/$newDocumentName';

    File renamedFile = file.renameSync(newPath);
    return renamedFile;
  }

  // Function to open the camera and upload the photo to Firebase
  Future<void> openCameraAndUpload(String? documentId, ScaffoldMessengerState context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // Upload the image to Firebase Cloud Storage
      File filePathAbs = File(pickedFile.path);
      String documentNameOrig = filePathAbs.path.split('/').last;
      String extensionOrig = documentNameOrig.split('.').last;
      // Change the document name to a new one
      String newDocumentName = "SolarSnapshot.$extensionOrig";
      newDocumentName = addTimestampToDocumentName(newDocumentName);
      File renamedFile = changeDocumentName(filePathAbs, newDocumentName);
      await uploadDocuments(documentId, File(renamedFile.path), null, null, context);
    }
  }

  Future<void> uploadDocuments(String? documentId, File? specificFile, String? category, List<Map<String, dynamic>>? userDetails, ScaffoldMessengerState context) async {
    Helper _helper = Helper();
    _loadLanguage();

    // Upload a specific file or select the files for the upload routine
    List<File> files = [];
    if (specificFile == null) {
      files = await selectDocumentsForUpload();
    } else {
      files = [specificFile];
    }

    // Decide if the upload routine was triggered from a client or admin
    List<Map<String, dynamic>> userDetailsList = [];
    Map<String, dynamic> currentUserDetails = await _helper.getCurrentUserDetails();
    late String uploadTriggeredFrom;
    if (userDetails == null) {
      userDetailsList.add(currentUserDetails);
      uploadTriggeredFrom = 'client';
    } else {
      userDetailsList = userDetails;
      uploadTriggeredFrom = 'admin';
    }

    String? errorMessage;
    if (files.isEmpty) {
      errorMessage = _selectedLanguage == 'German' ? docOperationsNoDocsGerman : docOperationsNoDocsEnglish;
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
      category ??= documentLibraryCategoryCustomerClientEnglish;
      int year = DateTime.now().year;

      // First Reset the Progress Bar
      setProgressNotifierDictValue(documentId);
      _progressNotifierDict[documentId].value = 0.0;
      double progress = 0.0;

      for (File file in files) {
        String documentName = file.path.split('/').last; // Get the document name
        for (Map<String, dynamic> userDetails in userDetailsList) {
          String userDomain = userDetails['userDomain'].toLowerCase();
          String userName = userDetails['userName'];
          String userUid = userDetails['userUid'];
          String documentPath =
              '$userDomain/'
              '$category/'
              '$year/'
              '$userUid/'
              '$userName/'
              '$documentName';
          print("Uploading Document for: $documentPath");

          //Map<String, dynamic> result = await _helper.getSignedUrl(documentPath, token);

          // TODO and use this instead of getDownloadURL
          /*if (result['status'] == 'Failed') {
            return result['error'];
          }
          signedUrl = result['signedUrl'];
           */

          Reference ref = FirebaseStorage.instance.ref().child(documentPath);
          try {
            ref
                .putFile(file)
                .snapshotEvents
                .listen((taskSnapshot) async {
              switch (taskSnapshot.state) {
                case TaskState.running:
                  totalBytesTransferred += taskSnapshot.bytesTransferred;
                  // Might happen if the event is triggered several times for the same file
                  if (totalBytesTransferred >= totalBytes) {
                    progress = 100.0;
                  } else {
                    progress = (totalBytesTransferred / totalBytes) * 100.0;
                  }
                  if (_progressNotifierDict.containsKey(documentId) &&
                      _progressNotifierDict[documentId] != null) {
                    _progressNotifierDict[documentId]!.value = progress;
                  }
                  break;
                case TaskState.paused:
                  String errorMessage = "Upload task is paused for $documentName";
                  _helper.showSnackBar(errorMessage, 'Error', context);
                  break;
                case TaskState.success:
                  Map<String, String> result = await _addDocument(
                      ref, userDetails, documentName, category!);
                  if (result['status'] == 'Error') {
                    if (_progressNotifierDict.containsKey(documentId) &&
                        _progressNotifierDict[documentId] != null) {
                      _progressNotifierDict[documentId]!.value = 0.0;
                    }
                    String? errorMessage = result['message'];
                    _helper.showSnackBar(
                        errorMessage ?? "Default Error Message", 'Error',
                        context);
                  } else {
                    String successMessage = _selectedLanguage == 'German'
                        ? "Dokument $documentName$docOperationsUploadSuccessGerman"
                        : "Document $documentName$docOperationsUploadSuccessEnglish";
                    _helper.showSnackBar(successMessage, 'Success', context);
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
            return uploadCompleter.future;
          }
        }
      }

      // Notification Part
      if (uploadTriggeredFrom == 'client') {
        List<UserInstance> allUsers = await _helper.fetchUsersFromServer();
        String userDomain = userDetailsList[0]['userDomain'].toLowerCase();
        String userName = userDetailsList[0]['userName'];
        String userEmail = userDetailsList[0]['userEmail'];

        try {
          for (UserInstance user in allUsers) {
            // Search the corresponding super_admin or admin for the particular client based on its domain
            if (user.role == 'super_admin' || (user.role == 'admin' &&
                user.domain.toLowerCase() == userDomain)) {
              print("Sending Push notification from $userEmail($userName) to ${user.email}(${user.userName})");
              await _helper.sendPushNotificationRequestToServer(user.uid);
              await _helper.sendNotificationMail(
                  userName, userEmail, user.email, user.userName!);
            }
          }
        } catch (e) {
          print('$e');
          return uploadCompleter.future;
        }
      } else {
        String adminEmail = currentUserDetails['userEmail'];
        String adminName = currentUserDetails['userName'];

        for (Map<String, dynamic> userDetails in userDetailsList) {
          String userName = userDetails['userName'];
          String userEmail = userDetails['userEmail'];
          String userUid = userDetails['userUid'];

          print("Sending Push notification from $adminEmail($adminName) to $userEmail($userName)");
          try {
            await _helper.sendPushNotificationRequestToServer(userUid);
            await _helper.sendNotificationMail(
                adminName, adminEmail, userEmail, userName);
          } catch (e) {
            print('$e');
            return uploadCompleter.future;
          }
        }
      }
    } catch (e) {
      _helper.showSnackBar('$e', 'Error', context);
      return uploadCompleter.future;
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


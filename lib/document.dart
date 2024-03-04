import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sec_doc/helpers.dart';
import 'language_service.dart';
import 'text_contents.dart';


class Document {
  final String id;
  final String name;
  final String owner;
  final Timestamp? lastUpdate;
  final bool isNew;
  final bool viewed;
  final Timestamp? deletedAt;
  final String documentUrl;
  final String domain;
  final String category;
  final int year;
  final String userMail;
  final String userName;

  Document({
    required this.id,
    required this.name,
    required this.owner,
    required this.lastUpdate,
    required this.isNew,
    required this.viewed,
    required this.deletedAt,
    required this.documentUrl,
    required this.domain,
    required this.category,
    required this.year,
    required this.userMail,
    required this.userName});
}

// Your DocumentRepository containing the list of documents
class DocumentRepository {
  List<Document> documents = [];

  void addDocument(Document document) {
    documents.add(document);
  }
}

class DocumentDetailScreen extends StatefulWidget {
  final Document document;
  final DocumentOperations docOperations;
  final Helper helper;

  const DocumentDetailScreen({
    Key? key,
    required this.document,
    required this.docOperations,
    required this.helper
  }) : super(key: key);

  @override
  _DocumentDetailScreenState createState() => _DocumentDetailScreenState();

  String getError() {
    // Access the 'errorMessage' variable from the state
    return (key as _DocumentDetailScreenState).errorMessage;
  }
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late Future<Map<String, dynamic>> _documentContent;
  String errorMessage = "";

  String _selectedLanguage = 'German';

  String documentErrorLoadingGerman = getTextContentGerman("documentErrorLoading");
  String documentErrorLoadingEnglish = getTextContentEnglish("documentErrorLoading");
  String documentErrorShowGerman = getTextContentGerman("documentErrorShow");
  String documentErrorShowEnglish = getTextContentEnglish("documentErrorShow");
  String documentErrorFormatGerman = getTextContentGerman("documentErrorFormat");
  String documentErrorFormatEnglish = getTextContentEnglish("documentErrorFormat");

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _documentContent = fetchDocument(widget.document.documentUrl, widget.document.name);
  }

  Future<void> _loadLanguage() async {
    final selectedLanguage = await LanguageService.getLanguage();
    setState(() {
      _selectedLanguage = selectedLanguage;
    });
  }

  Future<Map<String, dynamic>> fetchDocument(String documentUrl, String documentName) async {
    Map<String, dynamic> response = await widget.docOperations.fetchDocumentContent(documentUrl, documentName);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name,  style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.yellow,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _documentContent,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(
                child: Text(
                  _selectedLanguage == 'German' ? documentErrorLoadingGerman : documentErrorLoadingEnglish,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                )
            );
          } else {
            var data = snapshot.data!;
            dynamic content = data['content'];
            bool isPdf = data['isPdf'];
            bool isImg = data['isImg'];
            bool isTxt = data['isTxt'];

            if (content == null) {
              errorMessage = "Content is null";
              return widget.helper.showStatus(_selectedLanguage == 'German' ? documentErrorShowGerman : documentErrorShowEnglish);
            }

            if (isPdf) {
              // Display the PDF using a PDF viewer
              try {
                return PDFView(
                  filePath: null, // Use null as a placeholder
                  pdfData: content,
                );
              } catch (e) {
                errorMessage = '$e';
                return widget.helper.showStatus('$e');
              }
            } else if (isImg) {
              // Handle other types of documents (e.g., images)
              // Display the data as needed
              try {
                return Image.memory(content);
              }
              catch (e) {
                errorMessage = '$e';
                return widget.helper.showStatus('$e');
              }
            } else if (isTxt) {
              try {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    content,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                );
              }
              catch (e) {
                errorMessage = '$e';
                return widget.helper.showStatus('$e');
              }
            } else {
              errorMessage = _selectedLanguage == 'German' ? documentErrorFormatGerman : documentErrorFormatEnglish;
              return widget.helper.showStatus(_selectedLanguage == 'German' ? documentErrorFormatGerman : documentErrorFormatEnglish);
            }
          }
        },
      ),
    );
  }
}

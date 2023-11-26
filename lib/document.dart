import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:sec_doc/helpers.dart';

class Document {
  final String id;
  final String name;
  final String owner;
  final Timestamp lastUpdate;
  final bool isNew;
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
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late Future<Map<String, dynamic>> _documentContent;

  @override
  void initState() {
    super.initState();
    _documentContent = fetchDocument(widget.document.documentUrl, widget.document.name);
  }

  Future<Map<String, dynamic>> fetchDocument(String documentUrl, String documentName) async {
    Map<String, dynamic> response = await widget.docOperations.fetchDocumentContent(documentUrl, documentName);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _documentContent,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Error loading document'));
          } else {
            var data = snapshot.data!;
            dynamic bytes = data['bytes'];
            bool isPdf = data['isPdf'];
            bool isImg = data['isImg'];
            bool isTxt = data['isTxt'];

            if (bytes == null) {
              return widget.helper.showStatus("Unable to show document");
            }

            if (isPdf) {
              // Display the PDF using a PDF viewer
              try {
                return PDFView(
                  filePath: null, // Use null as a placeholder
                  pdfData: bytes,
                );
              } catch (e) {
                return widget.helper.showStatus('$e');
              }
            } else if (isImg) {
              // Handle other types of documents (e.g., images)
              // Display the data as needed
              try {
                return Image.memory(bytes);
              }
              catch (e) {
                return widget.helper.showStatus('$e');
              }
            } else if (isTxt) {
              try {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    bytes,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                );
              }
              catch (e) {
                return widget.helper.showStatus('$e');
              }
            } else {
              return widget.helper.showStatus('Unsupported document format');
            }
          }
        },
      ),
    );
  }
}

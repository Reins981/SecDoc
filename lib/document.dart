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
  final String? deletedAt;
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

  const DocumentDetailScreen({
    Key? key,
    required this.document,
    required this.docOperations,
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

  Center showDocumentStatus(String status) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          status,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
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
            Uint8List? bytes = data['bytes'];
            bool isPdf = data['isPdf'];
            bool isImg = data['isImg'];

            if (bytes == null) {
              return showDocumentStatus("Unable to show document");
            }

            if (isPdf) {
              // Display the PDF using a PDF viewer
              try {
                return PDFView(
                  filePath: null, // Use null as a placeholder
                  pdfData: bytes,
                );
              } catch (e) {
                return showDocumentStatus('$e');
              }
            } else if (isImg) {
              // Handle other types of documents (e.g., images)
              // Display the data as needed
              try {
                return Image.memory(bytes);
              }
              catch (e) {
                return showDocumentStatus('$e');
              }
            } else {
              return showDocumentStatus('Unsupported document format');
            }
          }
        },
      ),
    );
  }
}

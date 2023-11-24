import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ffi';

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

class DocumentDetailScreen extends StatelessWidget {
  final Document document;

  const DocumentDetailScreen({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.name),
      ),
      body: Center(
        child: Hero(
          tag: document.id,
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    document.name,
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

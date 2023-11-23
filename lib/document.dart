import 'package:cloud_firestore/cloud_firestore.dart';
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
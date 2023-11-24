import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sec_doc/helpers.dart';
import 'document.dart'; // Import your DocumentRepository class here

class DocumentProvider extends ChangeNotifier {
  late Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>> _groupedDocuments;
  Timer? _debounceTimer;

  Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>> get groupedDocuments => _groupedDocuments;

  final DocumentOperations docOperations;

  DocumentProvider({required this.docOperations});

  void groupAndSetDocuments(List<DocumentSnapshot> documents) {
    _groupedDocuments = docOperations.groupDocuments(documents);
    print(_groupedDocuments);
    print("Notify listeners");
    notifyListeners();
  }

  void delaySearch(String searchText, List<DocumentSnapshot> documentsOrig) {
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer!.cancel(); // Cancel the previous timer if it's active
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchDocumentByNames(searchText, documentsOrig); // Perform search after a delay
    });
  }

  // Search document by document name or user name
  void _searchDocumentByNames(String searchText, List<DocumentSnapshot> documentsOrig) {
    List<DocumentSnapshot> allDocumentsCopy = List.from(documentsOrig);
    // Replace this with your logic to filter the document
    // Assuming you have a list of documents called 'documents' and 'documentName' is the search query.
    print("InFilter");
    print("Documents Orig are:");
    print(documentsOrig);
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

    if (filteredDocuments.isNotEmpty) {
      print("Filter results received");
      groupAndSetDocuments(filteredDocuments);
    } else {
      _groupedDocuments = {};
      notifyListeners();
    }

  }

}
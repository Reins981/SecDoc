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

  // Setter for groupedDocuments
  setGroupedDocuments(Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>> newGroupedDocuments) {
    // Perform any operations here before setting the value
    // For example, validation, transformation, etc.
    // ...

    // Assign the new value to the private variable
    _groupedDocuments = newGroupedDocuments;
  }

  void removeDocumentWithId(Document document) {
    _removeDocumentWithId(document.id);
  }

  void groupAndSetDocuments(List<DocumentSnapshot> documents) {
    _groupedDocuments = docOperations.groupDocuments(documents);
    print(_groupedDocuments);
    print("Notify listeners");
    notifyListeners();
  }

  void _removeDocumentWithId(String documentId) {
    _groupedDocuments.forEach((domain, yearMap) {
      yearMap.forEach((year, categoryMap) {
        categoryMap.forEach((category, userMap) {
          userMap.forEach((user, documentRepo) {
            documentRepo.documents.removeWhere((document) => document.id == documentId);
            notifyListeners();
          });
        });
      });
    });
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
    // Logic to filter documents by the given Text Input
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
            .contains(searchText.toLowerCase())
        ||
        doc['user_email']
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
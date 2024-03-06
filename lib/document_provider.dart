import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sec_doc/helpers.dart';
import 'document.dart';
import 'text_contents.dart';

class DocumentProvider extends ChangeNotifier {
  Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>>? _groupedDocuments;
  Timer? _debounceTimer;
  final String documentLibraryCategoryCustomerAdminGerman = getTextContentGerman("documentLibraryCategoryCustomerAdmin");
  final String documentLibraryCategoryCustomerAdminEnglish = getTextContentEnglish("documentLibraryCategoryCustomerAdmin");
  final String documentLibraryCategoryCustomerClientGerman = getTextContentGerman("documentLibraryCategoryCustomerClient");
  final String documentLibraryCategoryCustomerClientEnglish = getTextContentEnglish("documentLibraryCategoryCustomerClient");

  Map<String, Map<int, Map<String, Map<String, DocumentRepository>>>>? get groupedDocuments => _groupedDocuments;

  final DocumentOperations docOperations;
  final String language;

  DocumentProvider({required this.docOperations, required this.language});

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

  void groupAndSetDocuments(List<DocumentSnapshot> documents, String userRole, {bool notifyL=true}) {
    _groupedDocuments = docOperations.groupDocuments(documents, userRole);
    if (notifyL) {
      notifyListeners();
    }
  }

  void _removeDocumentWithId(String documentId) {
    _groupedDocuments!.forEach((domain, yearMap) {
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



  void delaySearch(String searchText, List<DocumentSnapshot> documentsOrig, String userRole) {
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer!.cancel(); // Cancel the previous timer if it's active
    }

    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      _searchDocumentByNames(searchText, documentsOrig, userRole); // Perform search after a delay
    });
  }

  // Search document by document name or user name
  void _searchDocumentByNames(String searchText, List<DocumentSnapshot> documentsOrig, String userRole) {

    String? documentStatus;
    if (searchText.toLowerCase() == "new") {
      documentStatus = "true";
    } else if (searchText.toLowerCase() == "updated") {
      documentStatus = "false";
    }
    String expectedCategory = language == 'German' ? documentLibraryCategoryCustomerAdminGerman : documentLibraryCategoryCustomerAdminEnglish;
    if (searchText.toLowerCase() == expectedCategory && userRole.contains("admin")) {
      searchText = language == 'German' ? documentLibraryCategoryCustomerClientGerman : documentLibraryCategoryCustomerClientEnglish;
    }

    List<DocumentSnapshot> allDocumentsCopy = List.from(documentsOrig);
    // Logic to filter documents by the given Text Input
    List<DocumentSnapshot> filteredDocuments = allDocumentsCopy
        .where((doc) =>
    doc['document_name']
        .toLowerCase()
        .contains(searchText.toLowerCase())
        ||
        doc['to_user_name']
            .toLowerCase()
            .contains(searchText.toLowerCase())
        ||
        doc['to_email']
            .toLowerCase()
            .contains(searchText.toLowerCase())
        ||
        doc['category']
            .toLowerCase()
            .contains(searchText.toLowerCase())
        ||
        documentStatus != null && doc['is_new']
            .toString()
            .contains(documentStatus.toLowerCase()))
        .toList();

    if (filteredDocuments.isNotEmpty) {
      groupAndSetDocuments(filteredDocuments, userRole);
    } else {
      _groupedDocuments = {};
      notifyListeners();
    }

  }

}
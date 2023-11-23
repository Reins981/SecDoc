
class Document {
  final String domain;
  final String category;
  final String year;
  final String userMail;
  final String userName;

  Document({
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'document_library.dart';
import 'progress_bar.dart';

class DetailedDashboardPage extends StatelessWidget {
  final DashboardItem dashboardItem;
  final Helper helper;
  final DocumentOperations docOperations;

  DetailedDashboardPage({
    required this.dashboardItem,
    required this.helper,
    required this.docOperations});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
        future: helper.getIdTokenResult(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return helper.showStatus('Error loading data: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return helper.showStatus('No user data available');
          }

          final idTokenResult = snapshot.data!;
          final customClaims = idTokenResult.claims;
          final userRole = customClaims?['role'];

          FirebaseAuth auth = FirebaseAuth.instance;
          User? user = auth.currentUser;

          if (user == null) {
            return helper.showStatus('The user does not exist.');
          }

          String documentId = "uploadDocIdDefault";
          docOperations.setProgressNotifierDictValue(documentId);

          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.yellow.withOpacity(1.0), // Adjust the opacity and colors
                                Colors.yellow.withOpacity(0.8), // to control the shade
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),

                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          )
                        ),
                        const SizedBox(height: 16),
                        Text(
                          dashboardItem.title,
                          style: GoogleFonts.lato(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dashboardItem.detailedDescription,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Visibility(
                          visible: dashboardItem.itemType == DashboardItemType.library,
                          child:
                            ElevatedButton(
                              onPressed: () {
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                                    builder: (context) => DocumentLibraryScreen(
                                        documentOperations: docOperations,
                                        helper: helper),
                                  ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow.withOpacity(1.0),
                                foregroundColor: Colors.black, // Text color
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                dashboardItem.buttonText,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                        ),
                        Visibility(
                          visible: dashboardItem.itemType == DashboardItemType.upload,
                          child:
                          ElevatedButton(
                            onPressed: () async {
                                final scaffoldContext = ScaffoldMessenger.of(context);
                                if (userRole == 'client') {
                                  await docOperations.uploadDocuments(documentId, scaffoldContext);
                                } else {
                                  await docOperations.uploadDocuments(documentId, scaffoldContext);
                                }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow.withOpacity(1.0),
                              foregroundColor: Colors.black, // Text color
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              dashboardItem.buttonText,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        dashboardItem.itemType == DashboardItemType.library ? const SizedBox(height: 8) : const SizedBox(height: 16),
                        Visibility(
                          visible: dashboardItem.itemType == DashboardItemType.upload,
                          child: ProgressBar(
                            progress: docOperations
                                .getProgressNotifierDict()[documentId],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
    );
  }
}

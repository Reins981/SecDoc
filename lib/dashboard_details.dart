import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sec_doc/text_contents.dart';
import 'dashboard_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'document_library.dart';
import 'package:url_launcher/url_launcher.dart';
import 'document_upload.dart';

class DetailedDashboardPage extends StatefulWidget {
  final DashboardItem dashboardItem;
  final Helper helper;
  final DocumentOperations docOperations;

  DetailedDashboardPage({
    required this.dashboardItem,
    required this.helper,
    required this.docOperations});

  @override
  _DetailedDashboardPageState createState() => _DetailedDashboardPageState();
}

class _DetailedDashboardPageState extends State<DetailedDashboardPage> {

  Uri solarCalcUrl = Uri.parse(solarAiUrl);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
        future: widget.helper.getCurrentUserDetails(forceRefresh: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return widget.helper.showStatus('Error loading data: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return widget.helper.showStatus('No user data available');
          }

          Map<String, dynamic> userDetails = snapshot.data!;
          final userRole = userDetails['userRole'];

          final scaffoldContext = ScaffoldMessenger.of(context);
          String documentId = "uploadDocIdDefault";
          widget.docOperations.setProgressNotifierDictValue(documentId);
          String detailedDescription = userRole == 'client'
              ? widget.dashboardItem.detailedDescription
              : widget.dashboardItem.detailedDescriptionAdmin;

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
                          widget.dashboardItem.title,
                          style: GoogleFonts.lato(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detailedDescription,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Visibility(
                          visible: widget.dashboardItem.itemType == DashboardItemType.library,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await Future.delayed(Duration.zero);
                                
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => DocumentLibraryScreen(
                                          documentOperations: widget.docOperations,
                                          helper: widget.helper
                                      ),
                                    )
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow.withOpacity(1.0),
                                foregroundColor: Colors.black, // Text color
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 40,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                widget.dashboardItem.buttonText,
                                style: GoogleFonts.lato(
                                  fontSize: 20,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: widget.dashboardItem.itemType == DashboardItemType.ai,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                /*await Future.delayed(Duration.zero);
                                Navigator.pushReplacementNamed(context, '/solar').then((_);*/

                                await Future.delayed(Duration.zero);
                                if (await canLaunchUrl(solarCalcUrl)) {
                                  await launchUrl(solarCalcUrl);
                                } else {
                                  // Handle the case where the web page could not be launched.
                                  widget.helper.showSnackBar('Could not launch URL: $solarCalcUrl', "Error", scaffoldContext);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow.withOpacity(1.0),
                                foregroundColor: Colors.black, // Text color
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 40,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                widget.dashboardItem.buttonText,
                                style: GoogleFonts.lato(
                                  fontSize: 20,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: widget.dashboardItem.itemType == DashboardItemType.upload,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (userRole == 'client') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DocumentUploadPage(
                                            cameraUpload: widget.docOperations.openCameraAndUpload,
                                            uploadDocuments: widget.docOperations.uploadDocuments,
                                            clearProgressNotifier: widget.docOperations.clearProgressNotifierDict,
                                            documentId: documentId,
                                        ),
                                    ),
                                  );
                                } else {
                                  await Future.delayed(Duration.zero);
                                  Navigator.pushReplacementNamed(context, '/details');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow.withOpacity(1.0),
                                foregroundColor: Colors.black, // Text color
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 40,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                widget.dashboardItem.buttonText,
                                style: GoogleFonts.lato(
                                  fontSize: 20,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        widget.dashboardItem.itemType == DashboardItemType.library ? const SizedBox(height: 8) : const SizedBox(height: 16),
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

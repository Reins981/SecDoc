import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentUploadPage extends StatefulWidget {
  final Function(String?, ScaffoldMessengerState) cameraUpload;
  final Function(String?, File?, String?, ScaffoldMessengerState) uploadDocuments;
  final Function() clearProgressNotifier;
  final String documentId;

  const DocumentUploadPage({
    Key? key,
    required this.cameraUpload,
    required this.uploadDocuments,
    required this.clearProgressNotifier,
    required this.documentId,
  }) : super(key: key);

  @override
  _DocumentUploadPageState createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {

  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Document Upload Page',
          style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _handleLogout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: TwoButtonWidget(
              cameraButtonPressed: () async {
                setState(() {
                  isUploading = true;
                });
                await widget.cameraUpload(widget.documentId, ScaffoldMessenger.of(context));

                if (mounted) {
                  setState(() {
                    isUploading = false;
                  });
                }
              },
              galleryButtonPressed: () async {
                setState(() {
                  isUploading = true;
                });
                await widget.uploadDocuments(widget.documentId, null, null, ScaffoldMessenger.of(context));

                if (mounted) {
                  setState(() {
                    isUploading = false;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 20), // Add spacing between TwoButtonWidget and additional widget
          Visibility(
            visible: isUploading,
            child: Align(
              alignment: Alignment.center,
              child: LinearProgressIndicator(
                minHeight: 4.0, // Adjust the thickness
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    widget.clearProgressNotifier();
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class TwoButtonWidget extends StatelessWidget {
  final Function() cameraButtonPressed;
  final Function() galleryButtonPressed;

  const TwoButtonWidget({
    Key? key,
    required this.cameraButtonPressed,
    required this.galleryButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical, // Change to vertical scrolling
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: cameraButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.withOpacity(1.0),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: 80,
                  horizontal: 100,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Icon(
                Icons.camera,
                size: 80,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10), // Add space between buttons
            ElevatedButton(
              onPressed: galleryButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(1.0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 80,
                  horizontal: 100,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Icon(
                Icons.phone_android,
                size: 80,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

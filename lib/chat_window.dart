import 'package:flutter/material.dart';
import 'helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatWindow extends StatefulWidget {
  final DocumentOperations docOperations;

  ChatWindow({Key? key, required this.docOperations}) : super(key: key);

  @override
  _ChatWindowState createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? currentUserId = '';

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(_animationController);
  }

  void _initializeUser() {
    var currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = currentUser?.uid;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String destinationUserId = "E7bMBQoiFMhWUkzBjfyHD97opXT2"; // Replace with actual value
        String destinationUserName = "john"; // Replace with actual value

        await _firestore.collection('messages').add({
          'message': _messageController.text,
          'senderId': currentUser.uid,
          'senderName': currentUser.displayName ?? currentUser.email,
          'destinationUserId': destinationUserId,
          'destinationUserName': destinationUserName,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Chat with Us",
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: MessageList(currentUserId: currentUserId),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type your message here...",
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _sendMessage,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageList extends StatelessWidget {

  final String? currentUserId;

  const MessageList({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('destinationUserId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final messages = snapshot.data!.docs;

        List<Widget> messageWidgets = [];

        for (var message in messages) {
          final messageText = message['message'] ?? '';
          final senderName = message['senderName'] ?? '';

          messageWidgets.add(
            ListTile(
              title: Text(senderName),
              subtitle: Text(messageText),
            ),
          );
        }

        return ListView(
          reverse: true,
          children: messageWidgets,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'user.dart';

String generateMessageId() {
  var uuid = Uuid();
  return uuid.v4(); // Generates a version 4 UUID
}

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
  final Helper helper = Helper();
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? currentUserId = '';
  String? email = '';
  String userRole = '';
  String userDomain = '';
  List<UserInstance> allUsers = [];
  String? _replyingToMessageId;
  bool isSending = false;

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

  void _initializeUser() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    Map<String, dynamic> userDetails = await helper.getCurrentUserDetails();
    try {
      allUsers = await helper.fetchUsersFromServer();
    } catch (e) {
      print('$e');
    }

    setState(() {
      currentUserId = currentUser?.uid;
      email = currentUser?.email;
      userRole = userDetails['userRole'];
      userDomain = userDetails['userDomain'];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(ScaffoldMessengerState context) async {
    if (_messageController.text.isNotEmpty) {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        var uuid = generateMessageId();

        if (allUsers.isEmpty) {
          helper.showSnackBar("Could not find any administrative users!", 'Error', context);
        }

        try {
          for (UserInstance user in allUsers) {
            if (user.role == 'super_admin' || (user.role == 'admin' && user.domain.toLowerCase() == userDomain)) {
              String destinationUserId = user.uid; // Replace with actual value
              String destinationUserName = user.userName!; // Replace with actual value

              await _firestore.collection('messages').add({
                'message': _messageController.text,
                'senderId': currentUser.uid,
                'senderName': currentUser.displayName,
                'senderEmail': currentUser.email,
                'destinationUserId': destinationUserId,
                'destinationUserName': destinationUserName,
                'timestamp': FieldValue.serverTimestamp(),
                'messageType': 'Request',
                'messageId': uuid,
              });

              _messageController.clear();
              await helper.sendPushNotificationRequestToServer(
                  destinationUserId);
            }
          }
        } catch (e) {
          helper.showSnackBar('$e', 'Error', context);
        }
      }
    }
  }

  Future<void> _sendReply(
      String message,
      String? senderId,
      String? senderName,
      String? senderEmail,
      String destinationId,
      String destinationName) async {
    if (message.isNotEmpty) {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        var uuid = generateMessageId();
        await _firestore.collection('messages').add({
          'message': message,
          'senderId': senderId,
          'senderName': senderName,
          'senderEmail': senderEmail,
          'destinationUserId': destinationId,
          'destinationUserName': destinationName,
          'timestamp': FieldValue.serverTimestamp(),
          'messageType': 'Reply',
          'messageId': uuid,
        });

        _messageController.clear();
        await helper.sendPushNotificationRequestToServer(destinationId);
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
                userRole == "client" ? "Chat with Us" : "Customer Chat Requests",
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: MessageList(
                  firestore: _firestore,
                  currentUserId: currentUserId,
                  currentUserEmail: email,
                  isAdmin: userRole.contains("admin"),
                  isSuperAdmin: userRole == "super_admin",
                  callback: _sendReply,
                  replyingToMessageId: _replyingToMessageId, // Pass the state
                  setReplyingToMessageId: (String? id) => setState(() => _replyingToMessageId = id)
              ),
            ),
            if (userRole == 'client')
              isSending
                  ? CircularProgressIndicator()
                  : TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message here...",
                        suffixIcon: Material(
                          color: Colors.transparent, // to maintain the original color of the IconButton
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30), // Slightly larger than the icon size for better effect
                            onTap: () {
                              setState(() {
                                isSending = true;
                              });
                              ScaffoldMessengerState scaffoldContext = ScaffoldMessenger.of(context);
                              _sendMessage(scaffoldContext);
                              if (mounted) {
                                setState(() {
                                  isSending = false;
                                });
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.all(8.0), // Padding to provide space for the ripple effect
                              child: Icon(Icons.send, color: Theme.of(context).primaryColor),
                            ),
                          ),
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

class MessageList extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String? currentUserId;
  final String? currentUserEmail;
  final bool isAdmin;
  final bool isSuperAdmin;
  final void Function(String message, String? senderId, String? senderName, String? senderEmail, String destinationId, String destinationName) callback;
  final String? replyingToMessageId;
  final Function(String?) setReplyingToMessageId;

  const MessageList({
    Key? key,
    required this.firestore,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.callback,
    required this.replyingToMessageId,
    required this.setReplyingToMessageId,
  }) : super(key: key);

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {

  final TextEditingController _replyMessageController = TextEditingController();
  Map<String, bool> _replyingLoading = {};

  String? getLabelText(QueryDocumentSnapshot<Object?> message, String senderEmail) {
    // Message recipient
    if (message['destinationUserId'] == widget.currentUserId) {
        return "From: $senderEmail";
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 365))) // Assuming a timestamp filter
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final messages = snapshot.data!.docs;

        List<Widget> messageWidgets = [];

        for (var message in messages) {
          if (message['destinationUserId'] == widget.currentUserId || message['senderId'] == widget.currentUserId) {
            bool isReplyingLoading = _replyingLoading[message.id] ?? false;
            final messageText = message['message'] ?? '';
            final messageType = message['messageType'];
            final senderEmail = message['senderEmail'];
            String? labelText = getLabelText(message, senderEmail);
            late String senderName;
            if (messageType == 'Reply' && widget.isAdmin) {
              senderName = "${message['senderName']} -> ${message['destinationUserName']}";
            } else {
              senderName = message['senderName'] ?? '';
            }

            Widget replyIcon = const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.reply, color: Colors.green),
            );

            Widget deleteIcon = IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Call function to delete the message
                _deleteMessage(message.id);
              },
            );

            Widget messageWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.isAdmin && message['destinationUserId'] == widget.currentUserId) {
                        widget.setReplyingToMessageId(message.id); // Set the current message as the one being replied to
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: message['senderId'] == widget.currentUserId ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  senderName,
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  messageText,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: Colors.black,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                if (labelText != null) ...[ // Use spread operator with list
                                  SizedBox(height: 5),
                                  Text(
                                    labelText,
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.black45,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 5),
                                Text(
                                  DateFormat('dd MMM yyyy hh:mm a').format((message['timestamp'] as Timestamp).toDate()),
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: Colors.black45,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isAdmin && messageType != "Reply") replyIcon,
                          if (message['senderId'] == widget.currentUserId) deleteIcon
                        ],
                      ),
                    ),
                  ),
                  if (widget.replyingToMessageId == message.id) // Check if this message is being replied to
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isReplyingLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TextField(
                        controller: _replyMessageController,
                        decoration: InputDecoration(
                          hintText: "Type your reply here...",
                          suffixIcon: Material(
                            color: Colors.transparent, // to maintain the original color of the IconButton
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30), // Slightly larger than the icon size for better effect
                              onTap: () {
                                setState(() {
                                  _replyingLoading[message.id] = true;
                                });
                                // Implement send reply logic using the callback
                                widget.callback(
                                  _replyMessageController.text,
                                  widget.currentUserId,
                                  message['destinationUserName'],
                                  widget.currentUserEmail, // or currentUserDisplayName based on your data
                                  message['senderId'], // newDestinationId
                                  message['senderName'], // newDestinationName
                                );

                                if (mounted) {
                                  setState(() {
                                    _replyMessageController.clear();
                                    _replyingLoading[message.id] = false;
                                    widget.setReplyingToMessageId(
                                        null); // Reset the reply state
                                  });
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(8.0), // Padding to provide space for the ripple effect
                                child: Icon(Icons.send, color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                ],
            );
            messageWidgets.add(messageWidget);
          }
        }

        return ListView(
          reverse: true,
          children: messageWidgets,
        );
      },
    );
  }

  void _deleteMessage(String messageId) {
    widget.firestore.collection('messages').doc(messageId)
        .delete()
        .then((_) {
      print('Message deleted successfully');
    }).catchError((error) {
      print('Error deleting message: $error');
    });
  }
}

class ReplyScreen extends StatefulWidget {
  final String? newSenderId;
  final String? newSenderName;
  final String? newSenderEmail;
  final String newDestinationId;
  final String newDestinationName;
  final void Function(String message,
      String? senderId,
      String? senderName,
      String? senderEmail,
      String destinationId,
      String destinationName) callback;

  ReplyScreen({
    Key? key,
    required this.newSenderId,
    required this.newDestinationId,
    required this.newSenderName,
    required this.newSenderEmail,
    required this.newDestinationName,
    required this.callback,
  }) : super(key: key);

  @override
  _ReplyScreenState createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final TextEditingController messageController = TextEditingController();
  bool isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reply Message", style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: "Your Message",
                hintText: "Type your message here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), // Set border radius here
                  borderSide: const BorderSide(
                    color: Colors.grey, // You can set the border color here
                    width: 1.0, // And the border width
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    messageController.clear();
                  },
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 20),
            isSending
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                setState(() {
                  isSending = true;
                });

                // Implement sending message logic here
                String messageToSend = messageController.text;
                print("Sending reply: $messageToSend");

                // Invoke the callback function
                widget.callback(
                    messageToSend,
                    widget.newSenderId,
                    widget.newSenderName,
                    widget.newSenderEmail,
                    widget.newDestinationId,
                    widget.newDestinationName);

                // Simulate a delay (e.g., network request)
                // Remove this in your actual implementation
                await Future.delayed(Duration(seconds: 2));

                setState(() {
                  isSending = false;
                });

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                "Send Reply",
                style: GoogleFonts.lato(
                  fontSize: 20,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


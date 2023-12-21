import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'helpers.dart';
import 'dart:convert';

class UserDetailsScreen extends StatefulWidget {
  final DocumentOperations docOperations;
  final Helper helper = Helper();

  UserDetailsScreen({super.key, required this.docOperations});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    users = [];
    fetchUsers().then((fetchedUsers) {
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    widget.docOperations.clearProgressNotifierDict();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      String? idToken;

      if (user != null) {
        idToken = await user.getIdToken();
      }

      final response = await http.get(
          headers: <String, String>{
            'Authorization': 'Bearer $idToken',
          },
          Uri.parse('https://127.0.0.1:5000/get_all_users')
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final List<Map<String, dynamic>> fetchedUsers = List<Map<String, dynamic>>.from(responseBody['users']);
        return fetchedUsers;
      } else {
        throw 'Failed to fetch users: ${response.statusCode}';
      }
    } catch (e) {
      throw '$e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customers and Admins', style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : UsersTable(users, widget.docOperations),
      ),
    );
  }
}

class UsersTable extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Helper helper = Helper();
  final DocumentOperations docOperations;

  UsersTable(this.users, this.docOperations, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: helper.getUserDetails(users),
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

        List<Map<String, dynamic>> userDetails = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Verified')),
              DataColumn(label: Text('Disabled')),
              DataColumn(label: Text('Display Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Domain')),
            ],
            rows: userDetails
                .map(
                  (user) => DataRow(
                cells: [
                  DataCell(Text(user['verified'].toString())),
                  DataCell(Text(user['disabled'].toString())),
                  DataCell(Text(user['userName'])),
                  DataCell(Text(user['userEmail'])),
                  DataCell(Text(user['userRole'])),
                  DataCell(Text(user['userDomain'])),
                ],
                onSelectChanged: (_) {
                  // Handle selecting this row - collect user info
                  print('Selected user: ${user['UserName']}');
                  // Add further logic to collect user info as needed
                },
              ),
            )
                .toList(),
          ),
        );
      },
    );
  }
}

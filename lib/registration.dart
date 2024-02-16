import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'language_service.dart';
import 'text_contents.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedDomain = 'PV-IBK'; // Initialize with a default value
  Helper _helper = Helper();
  bool registrationSuccess = false;
  bool isObscure = true;
  String _selectedLanguage = 'German';
  // Language related content
  String registrationEmptyFieldGerman = getTextContentGerman("registrationEmptyField");
  String registrationEmptyFieldEnglish = getTextContentEnglish("registrationEmptyField");
  String registrationInvalidEmailGerman = getTextContentGerman("registrationInvalidEmail");
  String registrationInvalidEmailEnglish = getTextContentEnglish("registrationInvalidEmail");
  String registrationInvalidPasswordLengthGerman = getTextContentGerman("registrationInvalidPasswordLength");
  String registrationInvalidPasswordLengthEnglish = getTextContentEnglish("registrationInvalidPasswordLength");
  String registrationInvalidPasswordCharactersGerman = getTextContentGerman("registrationInvalidPasswordCharacters");
  String registrationInvalidPasswordCharactersEnglish = getTextContentEnglish("registrationInvalidPasswordCharacters");
  String registrationUsernameGerman = getTextContentGerman("registrationUsername");
  String registrationUsernameEnglish = getTextContentEnglish("registrationUsername");
  String registrationPasswordGerman = getTextContentGerman("registrationPassword");
  String registrationPasswordEnglish = getTextContentEnglish("registrationPassword");
  String registrationDomainGerman = getTextContentGerman("registrationDomain");
  String registrationDomainEnglish = getTextContentEnglish("registrationDomain");
  String registrationExampleGerman = getTextContentGerman("registrationExample");
  String registrationExampleEnglish = getTextContentEnglish("registrationExample");
  String registrationRegisterGerman = getTextContentGerman("registrationRegister");
  String registrationRegisterEnglish = getTextContentEnglish("registrationRegister");
  String registrationSuccessGerman = getTextContentGerman("registrationSuccess");
  String registrationSuccessEnglish = getTextContentEnglish("registrationSuccess");
  String registrationNextStepsGerman = getTextContentGerman("registrationNextSteps");
  String registrationNextStepsEnglish = getTextContentEnglish("registrationNextSteps");

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final selectedLanguage = await LanguageService.getLanguage();
    setState(() {
      _selectedLanguage = selectedLanguage;
    });
  }

  String _validateForm() {
    // Check if any field is empty
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      // Show an error message or handle the validation as needed
      return _selectedLanguage == "German" ? registrationEmptyFieldGerman: registrationEmptyFieldEnglish;
    }

    // Check if the email is valid
    String email = emailController.text;
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      return _selectedLanguage == "German" ? registrationInvalidEmailGerman: registrationInvalidEmailEnglish;
    }

    // Check if the password meets criteria (at least 8 characters and one special character)
    String password = passwordController.text;
    if (password.length < 8) {
      return _selectedLanguage == "German" ? registrationInvalidPasswordLengthGerman : registrationInvalidPasswordLengthEnglish;
    }

    // Define a pattern for a special character (you can adjust this pattern based on your requirements)
    RegExp specialChar = RegExp(r'[$&+,:;=?@#|<>.^*()%!-]');

    if (!specialChar.hasMatch(password)) {
      return _selectedLanguage == "German" ? registrationInvalidPasswordCharactersGerman : registrationInvalidPasswordCharactersEnglish;
    }

    // If all validations pass, return success
    return 'success';
  }

  Widget _buildLocationInfo(String location, String domain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$location: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Text(
              domain,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
      ],
    );
  }

  // Function to delete a user
  Future<void> deleteUser(User? user) async {
    if (user != null) {
      try {
        await user.delete();
        print('User deleted successfully.');
      } catch (e) {
        print('Failed to delete user: $e');
      }
    }
  }

  Future<String> registerUser(
      String email,
      String password,
      String username,
      String role,
      String domain,
      ) async {

    String errorMessage = 'Error: ';
    User? user;
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Get the user from the UserCredential
      user = userCredential.user;
      String? idToken;

      if (user != null) {
        // Retrieve the ID token for the user
        idToken = await user.getIdToken();

        // Now you can use this idToken to send it to your Flask server or perform other operations
      } else {
        return "Error registering user $email";
      }

      // Update display name
      await user.updateDisplayName(username);

      // Prepare custom claim entries as a Map
      Map<String, dynamic> customClaims = {
        'role': role,
        'domain': domain,
        'disabled': false,
        'verified': false,
        'verification_token': null,
      };

      // Send request to Flask server with custom claim entries
      final url = 'https://127.0.0.1:5000/create_custom_claims_for_user'; // Replace with your Flask server URL
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'uid': user.uid,
          'customClaims': customClaims, // Pass the customClaims directly as a map
        }),
      );

      if (response.statusCode == 200) {
        return 'Success';
      } else {
        // Delete the user in case the user is already registered
        await deleteUser(user);
        // Handle server errors or unsuccessful response
        if (response.body.isNotEmpty) {
          // Extract error message from the response body
          errorMessage += response.body;
        } else {
          errorMessage += 'Failed with status code: ${response.statusCode}';
        }
        return errorMessage;
      }
      // Perform any additional actions after user creation if needed
    } catch (e) {
      // Delete the user in case the user is already registered
      await deleteUser(user);
      // Handle registration errors
      print('Error registering user: $e');
      // You can throw an error or handle it based on your app's logic
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLanguage == "German" ? registrationRegisterGerman : registrationRegisterEnglish, style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
          child: !registrationSuccess ?
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: _selectedLanguage == "German" ? registrationUsernameGerman : registrationUsernameEnglish,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.yellow,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.yellow,
                      prefixIcon: Icon(Icons.email),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      labelText: _selectedLanguage == "German" ? registrationPasswordGerman : registrationPasswordEnglish,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.yellow,
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLanguage == "German" ? registrationDomainGerman : registrationDomainEnglish,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLocationInfo(_selectedLanguage == "German" ? registrationExampleGerman : registrationExampleEnglish, ''),
                            _buildLocationInfo('Innsbruck', 'PV-IBK'),
                            _buildLocationInfo('Wattens', 'PV-IBK-L'),
                            _buildLocationInfo('Telfs', 'PV-IM'),
                            _buildLocationInfo('Vienna', 'PV-EXT'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: 'PV-IBK',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.yellow,
                    ),
                    items: <String>['PV-IBK', 'PV-IBK-L', 'PV-IM', 'PV-EXT']
                        .map<DropdownMenuItem<String>>(
                          (String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.black,
                              letterSpacing: 1.0,
                            ),
                          ),
                        );
                      },
                    )
                        .toList(),
                    onChanged: (newValue) {
                      selectedDomain = newValue!;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      String userName = usernameController.text;
                      String email = emailController.text;
                      String password = passwordController.text;
                      final scaffoldContext = ScaffoldMessenger.of(context);

                      String result = _validateForm();

                      if (result == 'success') {
                        try {
                          String result = await registerUser(
                              email, password, userName, "client", selectedDomain);
                          if (result == "Success") {
                            setState(() {
                              registrationSuccess = true; // Update state to show success message
                            });
                          } else {
                            _helper.showSnackBar(result, "Error", scaffoldContext);
                          }
                        } catch (e) {
                          _helper.showSnackBar('$e', "Error", scaffoldContext);
                        }
                      } else {
                        _helper.showSnackBar(result, "Error", scaffoldContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(fontSize: 18),
                      minimumSize: Size(double.infinity, 60),
                    ),
                    child: Text(
                      _selectedLanguage == "German" ? registrationRegisterGerman : registrationRegisterEnglish,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            )
              :
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Card(
              color: Colors.yellow,
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selectedLanguage == "German" ? registrationSuccessGerman : registrationSuccessEnglish,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _selectedLanguage == "German" ? registrationNextStepsGerman : registrationNextStepsEnglish,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
      ),
    );
  }
}

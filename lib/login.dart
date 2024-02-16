import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers.dart';
import 'dashboard_section.dart';
import 'biometric_service.dart';
import 'language_service.dart';
import 'text_contents.dart';

class LoginScreen extends StatefulWidget {

  final DocumentOperations docOperations;

  const LoginScreen({
    super.key,
    required this.docOperations});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Helper _helper = Helper();
  bool _biometricsEnabled = false;
  String _selectedLanguage = 'German';

  String biometricsTextGerman = getTextContentGerman("biometricsText");
  String biometricsTextEnglish = getTextContentEnglish("biometricsText");
  String forgotPasswordTextGerman = getTextContentGerman("forgotPasswordText");
  String forgotPasswordTextEnglish = getTextContentEnglish("forgotPasswordText");
  String notRegisteredTextGerman = getTextContentGerman("notRegisteredText");
  String notRegisteredTextEnglish = getTextContentEnglish("notRegisteredText");
  String resetPasswordTextGerman = getTextContentGerman("resetPasswordText");
  String resetPasswordTextEnglish = getTextContentEnglish("resetPasswordText");
  String resetPasswordHintTextGerman = getTextContentGerman("resetPasswordHintText");
  String resetPasswordHintTextEnglish = getTextContentEnglish("resetPasswordHintText");
  String resetPasswordNotificationTextGerman = getTextContentGerman("resetPasswordNotificationText");
  String resetPasswordNotificationTextEnglish = getTextContentEnglish("resetPasswordNotificationText");
  String handleLoginError1German = getTextContentGerman("handleLoginError1");
  String handleLoginError1English = getTextContentEnglish("handleLoginError1");
  String handleLoginError2German = getTextContentGerman("handleLoginError2");
  String handleLoginError2English = getTextContentEnglish("handleLoginError2");
  String handleLoginError3German = getTextContentGerman("handleLoginError3");
  String handleLoginError3English = getTextContentEnglish("handleLoginError3");
  String handleLoginErrorGeneralGerman = getTextContentGerman("handleLoginErrorGeneral");
  String handleLoginErrorGeneralEnglish = getTextContentEnglish("handleLoginErrorGeneral");

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

  // Function to show an input dialog for the email address
  Future<void> _showEmailInputDialog(BuildContext context) async {
    TextEditingController _emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedLanguage == 'German' ? resetPasswordTextGerman : resetPasswordTextEnglish),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(
                hintText: _selectedLanguage == 'German' ? resetPasswordHintTextGerman : resetPasswordHintTextEnglish,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.yellow, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.yellow, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = _emailController.text.trim();
                Navigator.of(context).pop();
                await resetPassword(email, context);
              },
              child: Text('Send',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> resetPassword(String email, BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.sendPasswordResetEmail(email: email);
      _helper.showSnackBar(_selectedLanguage == 'German' ? resetPasswordNotificationTextGerman : resetPasswordNotificationTextEnglish, "Success", scaffoldContext, duration: 6);
    } catch (e) {
      _helper.showSnackBar('$e', "Error", scaffoldContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/logo.jpg',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.blue,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          items: <String>['English', 'German'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Center(
                                child: Text(
                                  value,
                                  style: GoogleFonts.lato(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                      letterSpacing: 1.0
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLanguage = newValue;
                                LanguageService.setLanguage(newValue);
                              });
                            }
                          },
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          underline: Container(
                            height: 0,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                            ),
                          ),
                          isExpanded: true,
                          iconSize: 24.0,
                          elevation: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: 'Email',
                        fillColor: Colors.yellow,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        labelText: 'Password',
                        fillColor: Colors.yellow,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: Text(
                        _selectedLanguage == 'German' ? biometricsTextGerman : biometricsTextEnglish,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.black,
                          letterSpacing: 1.0,
                        ),
                      ),
                      value: _biometricsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _biometricsEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _biometricsEnabled
                          ? () async {
                        await _handleLogin(context, true);
                      }
                          : () async {
                        await _handleLogin(context, false);
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
                        'Login',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5, // Space between buttons
                      runSpacing: 5, // Additional space if buttons wrap to the next line
                      children: [
                        TextButton(
                          onPressed: () async {
                            await _showEmailInputDialog(context);
                          },
                          child: Text(
                            _selectedLanguage == 'German' ? forgotPasswordTextGerman : forgotPasswordTextEnglish,
                            style: GoogleFonts.lato(
                              color: Colors.black,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/registration');
                          },
                          child: Text(
                            _selectedLanguage == 'German' ? notRegisteredTextGerman : notRegisteredTextEnglish,
                            style: GoogleFonts.lato(
                              color: Colors.black,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context, bool preserveAuthenticationState) async {
    ScaffoldMessengerState scaffoldContext = ScaffoldMessenger.of(context);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        _helper.showSnackBar( _selectedLanguage == 'German' ? handleLoginError1German : handleLoginError1English,
            'Error', scaffoldContext);
        return;
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = userCredential.user!;
      Map<String, dynamic> userDetails = await _helper.getCurrentUserDetails();
      bool verified = userDetails['verified'];
      bool disabled = userDetails['disabled'];

      if (!verified) {
        String errorText = _selectedLanguage == 'German' ? "Benutzer ${user.displayName}$handleLoginError2German" : "User ${user.displayName}$handleLoginError2English";
        _helper.showSnackBar(errorText, 'Error', scaffoldContext);
        return;
      }
      if (disabled) {
        String errorText = _selectedLanguage == 'German' ? "Benutzer ${user.displayName}$handleLoginError3German" : "User ${user.displayName}$handleLoginError3English";
        _helper.showSnackBar(errorText, 'Error', scaffoldContext);
        return;
      }

      // User authentication was successful, now persist the authentication state
      if (preserveAuthenticationState) {
        print("Persist Authentication state");
        BiometricsService.setBiometricsEnabled(true);
      } else {
        print("Authentication state will not be preserved");
        BiometricsService.setBiometricsEnabled(false);
      }

      _showWelcomeAnimation(context, user.displayName!);
    } catch (e) {
      // Handle login error
      String errorMessage = _selectedLanguage == 'German' ? handleLoginErrorGeneralGerman : handleLoginErrorGeneralEnglish;
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }
      _helper.showSnackBar(errorMessage, 'Error', scaffoldContext);
    }
  }

  void _showWelcomeAnimation(BuildContext context, String displayName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _WelcomeDialog(displayName: displayName, language: _selectedLanguage, docOperations: widget.docOperations);
      },
    );
  }
}

class _WelcomeDialog extends StatefulWidget {
  final String displayName;
  final String language;
  final DocumentOperations docOperations;

  _WelcomeDialog({Key? key, required this.displayName, required this.language, required this.docOperations}) : super(key: key);

  @override
  _WelcomeDialogState createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Language related content
  String welcomeTextGerman = getTextContentGerman("welcomeText");
  String welcomeTextEnglish = getTextContentEnglish("welcomeText");
  String continueTextGerman = getTextContentGerman("continueText");
  String continueTextEnglish = getTextContentEnglish("continueText");

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: _controller.value,
          child: Opacity(
            opacity: _controller.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.language == 'German' ? "$welcomeTextGerman${widget.displayName}!" : "$welcomeTextEnglish${widget.displayName}!",
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardSection(docOperations: widget.docOperations)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        widget.language == 'German' ? continueTextGerman : continueTextEnglish,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.black,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ], // children
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
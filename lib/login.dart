import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'helpers.dart';
import 'dashboard_section.dart';
import 'biometric_service.dart';

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

  // Function to show an input dialog for the email address
  Future<void> _showEmailInputDialog(BuildContext context) async {
    TextEditingController _emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(
                hintText: 'Enter your email',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = _emailController.text.trim();
                Navigator.of(context).pop();
                await resetPassword(email, context);
              },
              child: const Text('Send'),
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
      _helper.showSnackBar("A notification has been sent to your email account", "Success", scaffoldContext, duration: 6);
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
                      title: const Text(
                        'Enable Biometrics',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.0,
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
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
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
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/registration');
                          },
                          child: const Text(
                            'Not yet registered?',
                            style: TextStyle(
                              color: Colors.black,
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
        _helper.showSnackBar('Please enter both email and password.', 'Error', scaffoldContext);
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
        _helper.showSnackBar('User ${user.displayName} is not verified. Please verify your identity first!', 'Error', scaffoldContext);
        return;
      }
      if (disabled) {
        _helper.showSnackBar('User ${user.displayName} is disabled. Please contact the support team!', 'Error', scaffoldContext);
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
      String errorMessage = 'An error occurred during login.';
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
        return _WelcomeDialog(displayName: displayName, docOperations: widget.docOperations);
      },
    );
  }
}

class _WelcomeDialog extends StatefulWidget {
  final String displayName;
  final DocumentOperations docOperations;

  _WelcomeDialog({Key? key, required this.displayName, required this.docOperations}) : super(key: key);

  @override
  _WelcomeDialogState createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
                        'Welcome, ${widget.displayName}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 18),
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
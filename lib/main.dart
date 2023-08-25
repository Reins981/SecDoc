import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that the widgets are initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accounting App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Montserrat',
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.indigo],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
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
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          labelText: 'Password',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _handleLogin(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                          minimumSize: const Size(double.infinity, 60),
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement password recovery logic
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      print(email);
      print(password);

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both email and password.')),
        );
        return;
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = userCredential.user!;
      _showWelcomeAnimation(context, user.displayName!);
    } catch (e) {
      // Handle login error
      String errorMessage = 'An error occurred during login.';
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }


  void _showWelcomeAnimation(BuildContext context, String displayName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _WelcomeDialog(displayName: displayName);
      },
    );
  }
}

class _WelcomeDialog extends StatefulWidget {
  final String displayName;

  const _WelcomeDialog({Key? key, required this.displayName}) : super(key: key);

  @override
  _WelcomeDialogState createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: _opacityAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${widget.displayName}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'helpers.dart';
import 'document_provider.dart';
import 'dashboard_section.dart';
import 'biometric_setup.dart';
import 'biometric_service.dart';
import 'registration.dart';
import 'user_details.dart';
import 'solar_ai.dart';

class AppLifecycleObserver with WidgetsBindingObserver {

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    /*if (state == AppLifecycleState.paused) {
      print('App is about to enter state $state');
    }*/
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that the widgets are initialized
  var observer = AppLifecycleObserver();
  WidgetsBinding.instance.addObserver(observer);
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DocumentOperations docOperations = DocumentOperations();
  final AppLifecycleObserver appObserver = AppLifecycleObserver();
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsEnabled();
  }

  Future<void> _checkBiometricsEnabled() async {
    // Check if biometrics are enabled for the user
    // Fetch from shared preferences
    bool biometricsEnabled = await BiometricsService.getBiometricsEnabled();

    setState(() {
      _biometricsEnabled = biometricsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DocumentProvider(docOperations: docOperations)),
        // Add other providers here as needed
      ],
      child: MaterialApp(
        title: 'PlusVida GmbH',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Montserrat',
        ),
        home: LoadingPage(biometricsEnabled: _biometricsEnabled),
        routes: {
          '/login': (context) => LoginScreen(docOperations: docOperations),
          '/dashboard': (context) => DashboardSection(docOperations: docOperations),
          '/biometric': (context) => AuthenticatedScreen(),
          '/registration': (context) => const RegistrationScreen(),
          '/details': (context) => UserDetailsScreen(docOperations: docOperations),
          '/solar': (context) => SolarDataFetcher(docOperations: docOperations),
          // ... other routes
        },
        onGenerateRoute: (settings) {
          if (settings.name == null) {
            FirebaseAuth.instance.signOut();
            // Any other cleanup tasks
          }
          return null;
        },
      ),
    );
  }
}


class LoadingPage extends StatefulWidget {

  final bool biometricsEnabled;

  LoadingPage({Key? key, required this.biometricsEnabled});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    Timer(const Duration(seconds: 2), () {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && widget.biometricsEnabled) {
        // User is signed in and biometrics have been enabled
        Navigator.pushReplacementNamed(context, '/biometric');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: const FlutterLogo(size: 150),
        ),
      ),
    );
  }
}

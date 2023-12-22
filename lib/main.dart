import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:http/http.dart' as http;
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
    if (state == AppLifecycleState.resumed) {
      print('App is about to enter state $state');
    }
  }
}

AppLifecycleObserver observer = AppLifecycleObserver();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that the widgets are initialized
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

  Future<void> checkGooglePlayServices() async {
    final GooglePlayServicesAvailability availability =
    await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();

    if (availability != GooglePlayServicesAvailability.success) {
      // Google Play Services not available or version not supported
      // Show dialog to download or enable Google Play Services
      showGooglePlayServiceNotification();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _checkBiometricsEnabled();
    checkGooglePlayServices();
  }

  void showGooglePlayServiceNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        title: Text(
          "Google Play Services Unavailable",
          style: GoogleFonts.lato(
            fontSize: 22,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          "Please install or update Google Play Services.",
          style: GoogleFonts.lato(
            fontSize: 18,
            color: Colors.black87,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.white, // Background color of the dialog
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Colors.yellow, // Button background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Button rounded corners
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.blue,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showUserNotification(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        title: Text(
          message.notification!.title ?? "New Notification",
          style: GoogleFonts.lato(
            fontSize: 22,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          message.notification!.body ?? "You have a new document!",
          style: GoogleFonts.lato(
            fontSize: 18,
            color: Colors.black87,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.white, // Background color of the dialog
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Colors.yellow, // Button background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Button rounded corners
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.blue,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Retrieve the current FCM token
      String? token = await messaging.getToken();
      print("FCM Token: $token");
      sendRegistrationToServer(token);

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print("Refreshed token: $newToken");
        sendRegistrationToServer(token);
      });

      // Subscribe to "documents" topic
      messaging.subscribeToTopic('documents').then((_) {
        print('Subscribed to "documents" topic');
      });

      // For handling the received notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Got a notification!!!!");
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          showUserNotification(message);
        }
      });
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Background message handling
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }

  Future<void> sendRegistrationToServer(String? token) async {
    if (token == null) return;

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    String? idToken;

    if (user != null) {
      idToken = await user.getIdToken();
    } else {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://127.0.0.1:5000/register_token'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(<String, String>{
          'user_id': user.uid,  // Replace with actual user ID
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('Token sent to server successfully');
      } else {
        print('Failed to send token to server: ${response.body}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
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
    WidgetsBinding.instance.removeObserver(observer);
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

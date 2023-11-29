import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'helpers.dart';

class AuthenticatedScreen extends StatefulWidget {
  @override
  _AuthenticatedScreenState createState() => _AuthenticatedScreenState();
}

class _AuthenticatedScreenState extends State<AuthenticatedScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final Helper _helper = Helper();

  Future<void> delay(int seconds) async {
    // Sleep for x seconds
    await Future.delayed(Duration(seconds: seconds));
  }

  Future<bool> _checkBiometric(ScaffoldMessengerState context) async {
    bool canCheckBiometric = false;

    try {
      canCheckBiometric = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      _helper.showSnackBar('$e', "Error", context);
    }

    if (!canCheckBiometric) {
      _helper.showSnackBar("Hardware does not support Biometrics", "Error", context);
    }

    return canCheckBiometric;
  }

  Future<bool> _getAvailableBiometric(ScaffoldMessengerState context) async {
    bool success = false;

    try {
      List<BiometricType> availableBiometric = await auth.getAvailableBiometrics();
      success = availableBiometric.isNotEmpty ? true : false;
    } on PlatformException catch (e) {
      _helper.showSnackBar('$e', "Error", context);
    }

    return success;
  }

  Future<bool> _authenticate(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);

    if (!await _checkBiometric(scaffoldContext)) {
      return false;
    }

    if (!await _getAvailableBiometric(scaffoldContext)) {
      return false;
    }

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: "Scan your finger to authenticate",
      );
    } on PlatformException catch (e) {
      _helper.showSnackBar('$e', "Error", scaffoldContext);
      return false;
    }

    if (authenticated) {
      // Navigate to another screen upon successful authentication
      _helper.showSnackBar("Biometric Authentication successful!", "Success", scaffoldContext, duration: 1);
      return true;
    } else {
      _helper.showSnackBar('Biometric Authentication failed', "Error", scaffoldContext);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _helper.getCurrentUserDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _helper.showStatus('Error loading data: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return _helper.showStatus('No user data available');
        }

        Map<String, dynamic> userDetails = snapshot.data!;
        String userName = userDetails['userName'];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome, $userName",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 36.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40.0),
                const Icon(
                  Icons.fingerprint,
                  size: 100.0,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20.0),
                const Text(
                  "Authenticate using your fingerprint instead of your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18.0,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40.0),
                ElevatedButton(
                  onPressed: () async {
                    bool success = await _authenticate(context);
                    await delay(1);
                    if (success) {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    "Authenticate",
                    style: TextStyle(color: Colors.white, fontSize: 18.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

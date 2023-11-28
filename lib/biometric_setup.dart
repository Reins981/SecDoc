import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'helpers.dart';

class BiometricSetupScreen extends StatefulWidget {
  @override
  _BiometricSetupScreenState createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final Helper _helper = Helper();
  bool _biometricsEnabled = false;

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
      _helper.showSnackBar("Biometric Setup successful! "
          "\nYou can login now using your biometric fingerprint", "Success", scaffoldContext);
      return true;
    } else {
      _helper.showSnackBar('Biometric Authentication Failed', "Error", scaffoldContext);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                "Setup",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Switch to enable/disable biometrics
            SwitchListTile(
              title: const Text(
                'Biometrics enabled',
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 50.0),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15.0),
                    child: const Text(
                      "Authenticate using your fingerprint instead of your password",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18.0,
                        height: 1.5, // Adjust line height here
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15.0),
                    width: double.infinity,
                    child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: _biometricsEnabled
                          ? () async {
                        bool success = await _authenticate(context);
                        await delay(4);
                        if (success) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                      : null, // Disable the button if biometrics are disabled
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                        child: Text(
                          "Authenticate",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

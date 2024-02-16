import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'helpers.dart';
import 'text_contents.dart';
import 'language_service.dart';

class AuthenticatedScreen extends StatefulWidget {
  @override
  _AuthenticatedScreenState createState() => _AuthenticatedScreenState();
}

class _AuthenticatedScreenState extends State<AuthenticatedScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final Helper _helper = Helper();
  String _selectedLanguage = 'German';

  String biometricSetupError1German = getTextContentGerman("biometricSetupError1");
  String biometricSetupError1English = getTextContentEnglish("biometricSetupError1");
  String biometricSetupErrorGeneralGerman = getTextContentGerman("biometricSetupErrorGeneral");
  String biometricSetupErrorGeneralEnglish = getTextContentEnglish("biometricSetupErrorGeneral");
  String biometricSetupSuccessGerman = getTextContentGerman("biometricSetupSuccess");
  String biometricSetupSuccessEnglish = getTextContentEnglish("biometricSetupSuccess");
  String localizedReasonGerman = getTextContentGerman("localizedReason");
  String localizedReasonEnglish = getTextContentEnglish("localizedReason");
  String biometricAuthMethodGerman = getTextContentGerman("biometricAuthMethod");
  String biometricAuthMethodEnglish = getTextContentEnglish("biometricAuthMethod");
  String biometricAuthGerman = getTextContentGerman("biometricAuth");
  String biometricAuthEnglish = getTextContentEnglish("biometricAuth");
  String welcomeTextGerman = getTextContentGerman("welcomeText");
  String welcomeTextEnglish = getTextContentEnglish("welcomeText");

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
      _helper.showSnackBar(_selectedLanguage == 'German' ? biometricSetupError1German : biometricSetupError1English, "Error", context);
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
        localizedReason: _selectedLanguage == 'German' ? localizedReasonGerman : localizedReasonEnglish,
      );
    } on PlatformException catch (e) {
      _helper.showSnackBar('$e', "Error", scaffoldContext);
      return false;
    }

    if (authenticated) {
      // Navigate to another screen upon successful authentication
      _helper.showSnackBar(_selectedLanguage == 'German' ? biometricSetupSuccessGerman : biometricSetupSuccessEnglish, "Success", scaffoldContext, duration: 1);
      return true;
    } else {
      _helper.showSnackBar(_selectedLanguage == 'German' ? biometricSetupErrorGeneralGerman : biometricSetupErrorGeneralEnglish, "Error", scaffoldContext);
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
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewportConstraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedLanguage == 'German' ? "$welcomeTextGerman $userName!" : "$welcomeTextEnglish $userName!",
                          style: GoogleFonts.lato(
                            fontSize: 36,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 40.0),
                        const Icon(
                          Icons.fingerprint,
                          size: 100.0,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 20.0),
                        Text(
                          _selectedLanguage == 'German' ? biometricAuthMethodGerman : biometricAuthMethodEnglish,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.grey,
                            letterSpacing: 1.0,
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
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: Text(
                            _selectedLanguage == 'German' ? biometricAuthGerman : biometricAuthEnglish,
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

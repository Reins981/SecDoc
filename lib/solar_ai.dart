import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'helpers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'solar_ai_card.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class SolarDataFetcher extends StatefulWidget {
  final DocumentOperations docOperations;

  SolarDataFetcher({super.key, required this.docOperations});

  @override
  _SolarDataFetcherState createState() => _SolarDataFetcherState();
}

class _SolarDataFetcherState extends State<SolarDataFetcher> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? solarData;
  Map<String, String> queryParams = {
    'raddatabase': 'PVGIS-SARAH',
    'peakpower': '5',
    'pvtechchoice': 'crystSi',
    'mountingplace': 'building',
    'fixed': '0',
    'twoaxis': '0',
    'vertical_axis': '0',
    'inclined_axis': '0',
    'inclinedaxisangle': '0',
    'verticalaxisangle': '0',
    'angle': '0',
    'aspect': '0',
    'loss': '15',
    'usehorizon' : '0',
    'lifetime': '25',
    'outputformat': 'json',
  };
  Map<String, String> queryParamsOffGrid = {
    'raddatabase': 'PVGIS-SARAH',
    'peakpower': '5',
    'usehorizon' : '0',
    'batterysize': '50',
    'cutoff': '50',
    'angle': '0',
    'aspect': '0',
    'consumptionday': '200',
    'outputformat': 'json',
  };
  String documentId = "solarAIDocument";
  String selectedSystemType = 'Grid-connected & Tracking PV systems'; // Default value
  bool showForm = true;
  String selectedRadDatabase = 'PVGIS-SARAH'; // Default value
  String selectedPvTechChoice = 'crystSi'; // Default value
  int selectedTrackingType = 0; // Default value
  String selectedMountingPlace = 'building'; // Default value
  String maxBudget = '0';
  String lifetime = '25';
  String peakPower = '5';
  String capacity = '50';
  String cutOff = '50';
  String consumptionDaily = '200';
  String loss = '15';
  String angle = '30';
  String aspect = '180';
  bool useHorizon = false; // Default value
  bool optimalinclination = false; // Default value
  bool optimalangles = false; // Default value
  bool inclined_axis = false;
  bool inclined_optimum = false;
  bool inclinedaxisangle = false;
  bool vertical_axis = false;
  bool vertical_optimum = false;
  bool verticalaxisangle = false;
  bool twoaxis = false;
  bool fixed = false;
  bool calcButtonEnabled = false;
  bool isLoading = false;
  bool isUploading = false;
  Helper helper = Helper();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    widget.docOperations.clearProgressNotifierDict();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void resetQueryParams() {
    queryParams = {
      'raddatabase': 'PVGIS-SARAH',
      'peakpower': '5',
      'pvtechchoice': 'crystSi',
      'mountingplace': 'building',
      'fixed': '0',
      'twoaxis': '0',
      'vertical_axis': '0',
      'inclined_axis': '0',
      'inclinedaxisangle': '0',
      'verticalaxisangle': '0',
      'angle': '0',
      'aspect': '0',
      'loss': '15',
      'usehorizon' : '0',
      'lifetime': '25',
      'outputformat': 'json',
    };
    queryParamsOffGrid = {
      'raddatabase': 'PVGIS-SARAH',
      'peakpower': '5',
      'usehorizon' : '0',
      'batterysize': '50',
      'cutoff': '50',
      'angle': '0',
      'aspect': '0',
      'consumptionday': '200',
      'outputformat': 'json',
    };
    // Reset individual state variables
    selectedSystemType = 'Grid-connected & Tracking PV systems'; // Default value
    selectedRadDatabase = 'PVGIS-SARAH'; // Default value
    selectedPvTechChoice = 'crystSi'; // Default value
    selectedMountingPlace = 'building'; // Default value
    maxBudget = '0';
    lifetime = '25';
    peakPower = '5';
    capacity = '50';
    cutOff = '50';
    consumptionDaily = '200';
    loss = '15';
    angle = '0';
    aspect = '0';
    useHorizon = false; // Default value
    optimalinclination = false; // Default value
    optimalangles = false; // Default value
    inclined_axis = false;
    inclined_optimum = false;
    inclinedaxisangle = false;
    vertical_axis = false;
    vertical_optimum = false;
    verticalaxisangle = false;
    twoaxis = false;
    fixed = false;
    calcButtonEnabled = false;
    isUploading = false;
  }

  bool isAtLeastOneSwitchEnabled() {
    return fixed || inclined_axis || vertical_axis || twoaxis;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solar Data',  style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
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
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            child: isLoading ? Container() : showForm ? buildForm() : buildResult(),
          ),
          if (isLoading)
            Container(
              color: Colors.white, // Adjust opacity and color as needed
              child: const Center(
                child: CircularProgressIndicator(color: Colors.yellow), // Loading indicator
              ),
            ),
          Positioned(
            bottom: 80, // Position above the bottom button
            right: 16,
            child: FloatingActionButton(
              heroTag: 'vertical_align_top',
              mini: true,
              child: Icon(Icons.vertical_align_top), // Icon indicating upwards scrolling
              onPressed: () {
                _scrollToTop();
              },
            ),
          ),
          Positioned(
            bottom: 16, // Adjust the position as needed
            right: 16, // Adjust the position as needed
            child: FloatingActionButton(
              heroTag: 'vertical_align_bottom',
              mini: true, // Makes the button smaller
              child: Icon(Icons.vertical_align_bottom), // Icon for the button
              onPressed: () {
                _scrollToBottom();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0, // Scroll to the top
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> generateAndPreviewPdf(Map<String, dynamic> solarData, ScaffoldMessengerState context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Solar Data Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.Text('Overview', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('Maximum Budget: ${solarData['Maximum Budget']} Euros'
                '\nMaximum Lifetime: ${solarData['Maximum Lifetime']} Years'
                '\nTechnology: ${solarData['Technology']}'
                '\nPeak Power: ${solarData['Peak Power']} kW'
                '\nSystem Loss: ${solarData['System Loss']} %'
                '\nDatabase: ${solarData['Radiation Database']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Location Data', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('Latitude: ${solarData['Location Data']['Latitude']},'
                '\nLongitude: ${solarData['Location Data']['Longitude']},'
                '\nElevation: ${solarData['Location Data']['Elevation']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Mounting System', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (solarData['Mounting System'].containsKey('Type'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('Type: ${solarData['Mounting System']['Type']}'
                  '\nSlope: ${solarData['Mounting System']['Slope']} °'
                  '\nSlope is Optimal: ${solarData['Mounting System']['Slope is Optimal']}'
                  '\nOrientation Angle: ${solarData['Mounting System']['Orientation Angle']} °'
                  '\nOrientation Angle is Optimal: ${solarData['Mounting System']['Orientation Angle is Optimal']}'),
            ),
          if (solarData['Mounting System'].containsKey('Inclined Axis'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('Slope: ${solarData['Mounting System']['Inclined Axis']['Slope']} °'
                  '\nSlope is Optimal: ${solarData['Mounting System']['Inclined Axis']['Slope is Optimal']}'
                  '\nOrientation Angle: ${solarData['Mounting System']['Inclined Axis']['Orientation Angle']} °'
                  '\nOrientation Angle is Optimal: ${solarData['Mounting System']['Inclined Axis']['Orientation Angle is Optimal']}'),
            ),
          if (solarData['Mounting System'].containsKey('Vertical Axis'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('Slope: ${solarData['Mounting System']['Vertical Axis']['Slope']} °'
                  '\nSlope is Optimal: ${solarData['Mounting System']['Vertical Axis']['Slope is Optimal']}'
                  '\nOrientation Angle: ${solarData['Mounting System']['Vertical Axis']['Orientation Angle']} °'
                  '\nOrientation Angle is Optimal: ${solarData['Mounting System']['Vertical Axis']['Orientation Angle is Optimal']}'),
            ),
          if (solarData['Mounting System'].containsKey('Two Axis'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('Slope: ${solarData['Mounting System']['Two Axis']['Slope']} °'
                  '\nSlope is Optimal: ${solarData['Mounting System']['Two Axis']['Slope is Optimal']}'
                  '\nOrientation Angle: ${solarData['Mounting System']['Two Axis']['Orientation Angle']} °'
                  '\nOrientation Angle is Optimal: ${solarData['Mounting System']['Two Axis']['Orientation Angle is Optimal']}'),
            ),
          pw.SizedBox(height: 20),
          _buildMonthlyDataTable(solarData),
        ],
      ),
    );

    Map<String, dynamic> currentUserDetails = await helper.getCurrentUserDetails();
    String role = currentUserDetails['userRole'];

    if (role == 'client') {
      setState(() {
        isUploading = true;
      });
      // Save the PDF file locally
      String fileName = 'SolarDataReport_${DateTime.now().millisecondsSinceEpoch}.pdf';
      String filePath = await widget.docOperations.createDownloadPathForFile(fileName);

      if (filePath == "Failed") {
        helper.showSnackBar("Could not access directory for saving file $fileName", "Error", context);
      } else {
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        // Upload the PDF file
        await widget.docOperations.uploadDocuments(documentId, file, context);
        setState(() {
          isUploading = false;
        });
      }
    } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
    }
  }

  Future<void> generateAndPreviewPdfOffGrid(Map<String, dynamic> solarData, ScaffoldMessengerState context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Solar Data Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.Text('Overview', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('Maximum Budget: ${solarData['Maximum Budget']} Euros'
                '\nPeak Power: ${solarData['Peak Power']} kW'
                '\nBattery Capacity: ${solarData['Battery Capacity (Wh)']} Wh'
                '\nBattery Discharge Cutoff Limit: ${solarData['Battery Discharge Cutoff Limit (%)']} %'
                '\nDaily Energy Consumption: ${solarData['Daily Energy Consumption (Wh)']} Wh'
                '\nDatabase: ${solarData['Radiation Database']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Location Data', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('Latitude: ${solarData['Location Data']['Latitude']},'
                '\nLongitude: ${solarData['Location Data']['Longitude']},'
                '\nElevation: ${solarData['Location Data']['Elevation']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Mounting System', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('Slope: ${solarData['Mounting System']['Slope']} °'
                '\nSlope is Optimal: ${solarData['Mounting System']['Slope is Optimal']}'
                '\nOrientation Angle: ${solarData['Mounting System']['Orientation Angle']} °'
                '\nOrientation Angle is Optimal: ${solarData['Mounting System']['Orientation Angle is Optimal']}'),
          ),
          pw.SizedBox(height: 20),
          _buildMonthlyDataTableOffGrid(solarData),
        ],
      ),
    );

    Map<String, dynamic> currentUserDetails = await helper.getCurrentUserDetails();
    String role = currentUserDetails['userRole'];

    if (role == 'client') {
      setState(() {
        isUploading = true;
      });
      // Save the PDF file locally
      String fileName = 'SolarDataReport_${DateTime.now().millisecondsSinceEpoch}.pdf';
      String filePath = await widget.docOperations.createDownloadPathForFile(fileName);

      if (filePath == "Failed") {
        helper.showSnackBar("Could not access directory for saving file $fileName", "Error", context);
      } else {
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        // Upload the PDF file
        await widget.docOperations.uploadDocuments(documentId, file, context);

        setState(() {
          isUploading = false;
        });
      }
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  pw.Widget _buildMonthlyDataTable(Map<String, dynamic> solarData) {
    return pw.TableHelper.fromTextArray(
      headers: ['Month', 'Daily Energy', 'Monthly Energy', 'Daily Irradiance', 'Monthly Irradiance', 'Sunshine Duration'],
      data: List<List<String>>.generate(12, (index) {
        final monthData = solarData['Month ${index + 1}'] ?? {};
        return [
          'Month ${index + 1}',
          '${monthData['Daily Energy (kWh/m²)'] ?? '-'} kWh/m²',
          '${monthData['Monthly Energy (kWh/m²)'] ?? '-'} kWh/m²',
          '${monthData['Daily Horizontal Irradiance (kWh/m²)'] ?? '-'} kWh/m²',
          '${monthData['Monthly Horizontal Irradiance (kWh/m²)'] ?? '-'} kWh/m²',
          '${monthData['Monthly sunshine duration (hours)'] ?? '-'} hours',
        ];
      }),
    );
  }

  pw.Widget _buildMonthlyDataTableOffGrid(Map<String, dynamic> solarData) {
    return pw.TableHelper.fromTextArray(
      headers: ['Month', 'Daily Energy', 'Energy lost Per Day', 'Fill Factor', 'Factor Of Efficiency'],
      data: List<List<String>>.generate(12, (index) {
        final monthData = solarData['Month ${index + 1}'] ?? {};
        return [
          'Month ${index + 1}',
          '${monthData['Daily Energy (kWh/m²)'] ?? '-'} kWh/m²',
          '${monthData['Energy lost Per Day (kWh/m²)'] ?? '-'} kWh/m²',
          '${monthData['Fill Factor (%)'] ?? '-'} %',
          '${monthData['Factor Of Efficiency (%)'] ?? '-'} %',
        ];
      }),
    );
  }

  Future<bool> fetchLocation(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle permission denied scenario
        helper.showSnackBar('Location data permission error.\n'
            'Please enable location permissions for this App in your phone settings', "Error", scaffoldContext);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      helper.showSnackBar('Permanent Location data permission error', "Error", scaffoldContext);
      return false;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (selectedSystemType == 'Grid-connected & Tracking PV systems') {
        queryParams['lat'] = position.latitude.toString();
        queryParams['lon'] = position.longitude.toString();
      } else {
        queryParamsOffGrid['lat'] = position.latitude.toString();
        queryParamsOffGrid['lon'] = position.longitude.toString();
      }
    } catch (e) {
      helper.showSnackBar('Error fetching location: $e', "Error", scaffoldContext);
      return false;
    }
    return true;
  }

  Future<void> fetchSolarData(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    bool success = await fetchLocation(context);

    if (!success) {
      return;
    }

    setState(() {
      isLoading = true; // Set isLoading to true when starting the fetch
    });

    String apiUrl = "";
    Map<String, String> queryParamsInUse = {};
    if (selectedSystemType == 'Grid-connected & Tracking PV systems') {
      apiUrl = 'https://re.jrc.ec.europa.eu/api/PVcalc';
      queryParamsInUse = queryParams;
    } else {
      apiUrl = "https://re.jrc.ec.europa.eu/api/SHScalc";
      queryParamsInUse = queryParamsOffGrid;
    }
    Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParamsInUse);

    try {
      http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        setState(() {
          solarData = selectedSystemType == 'Grid-connected & Tracking PV systems' ? extractImportantData(jsonData) : extractImportantDataOffGrid(jsonData);
          showForm = false;
          isLoading = false;
        });
      } else {
        // Attempt to decode response body to get the error message
        String errorMessage;
        try {
          var responseData = json.decode(response.body);
          errorMessage = responseData['error'] ?? 'Error: ${response.reasonPhrase}';
        } catch (e) {
          // If decoding fails, use the HTTP status message
          errorMessage = 'Error: ${response.reasonPhrase}';
        }
        helper.showSnackBar('Failed to fetch solar data. Status Code: $errorMessage', "Error", scaffoldContext);
        setState(() {
          isLoading = false; // Set isLoading to false after receiving the response
        });
      }
    } catch (error) {
      helper.showSnackBar('Error fetching solar data: $error', "Error", scaffoldContext);
      setState(() {
        isLoading = false; // Set isLoading to false after receiving the response
      });
    }
  }

  Map<String, dynamic> extractImportantData(Map<String, dynamic> jsonData) {
    Map<String, dynamic> extractedData = {};

    extractedData['Maximum Budget (Euros)'] = maxBudget;
    extractedData['Peak Power (kW)'] = peakPower;
    extractedData['System Loss (%)'] = loss;
    extractedData['Maximum Lifetime (Years)'] = lifetime;

    if (jsonData.containsKey('inputs')) {
      Map<String, dynamic> inputs = jsonData['inputs'];
      if (inputs.containsKey('location')) {
        Map<String, dynamic> location = inputs['location'];
        extractedData['Location Data'] = {
          'Latitude': location['latitude'],
          'Longitude': location['longitude'],
          'Elevation': location['elevation']
        };
      }
      if (inputs.containsKey('meteo_data')) {
        Map<String, dynamic> meteoData = inputs['meteo_data'];
        extractedData['Radiation Database'] = meteoData['radiation_db'];
      }
      if (inputs.containsKey('pv_module')) {
        Map<String, dynamic> pvModule = inputs['pv_module'];
        extractedData['Technology'] = pvModule['technology'];
        extractedData['Peak Power (kW)'] = pvModule['peak_power'];
      }
      if (inputs.containsKey('mounting_system')) {
        Map<String, dynamic> mountingSystem = inputs['mounting_system'];
        extractedData['Mounting System'] = {};
        if (mountingSystem.containsKey('fixed')) {
          Map<String, dynamic> fixedParameters = mountingSystem['fixed'];
          if (fixedParameters.containsKey('type')) {
            extractedData['Mounting System']['Type'] = fixedParameters['type'];
          }
          if (fixedParameters.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = fixedParameters['slope'];
            extractedData['Mounting System']['Slope (°)'] = slopeParameters['value'];
            extractedData['Mounting System']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (fixedParameters.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = fixedParameters['azimuth'];
            extractedData['Mounting System']['Orientation Angle (°)'] = orientationAngle['value'];
            extractedData['Mounting System']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
        if (mountingSystem.containsKey('vertical_axis')) {
          Map<String, dynamic> verticalAxis = mountingSystem['vertical_axis'];
          extractedData['Mounting System']['Vertical Axis'] = {};
          if (verticalAxis.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = verticalAxis['slope'];
            extractedData['Mounting System']['Vertical Axis']['Slope (°)'] = slopeParameters['value'];
            extractedData['Mounting System']['Vertical Axis']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (verticalAxis.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = verticalAxis['azimuth'];
            extractedData['Mounting System']['Vertical Axis']['Orientation Angle (°)'] = orientationAngle['value'];
            extractedData['Mounting System']['Vertical Axis']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
        if (mountingSystem.containsKey('inclined_axis')) {
          Map<String, dynamic> inclinedAxis = mountingSystem['inclined_axis'];
          extractedData['Mounting System']['Inclined Axis'] = {};
          if (inclinedAxis.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = inclinedAxis['slope'];
            extractedData['Mounting System']['Inclined Axis']['Slope (°)'] = slopeParameters['value'];
            extractedData['Mounting System']['Inclined Axis']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (inclinedAxis.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = inclinedAxis['azimuth'];
            extractedData['Mounting System']['Inclined Axis']['Orientation Angle (°)'] = orientationAngle['value'];
            extractedData['Mounting System']['Inclined Axis']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
        if (mountingSystem.containsKey('two_axis')) {
          Map<String, dynamic> twoAxis = mountingSystem['two_axis'];
          extractedData['Mounting System']['Two Axis'] = {};
          if (twoAxis.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = twoAxis['slope'];
            extractedData['Mounting System']['Two Axis']['Slope (°)'] = slopeParameters['value'];
            extractedData['Mounting System']['Two Axis']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (twoAxis.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = twoAxis['azimuth'];
            extractedData['Mounting System']['Two Axis']['Orientation Angle (°)'] = orientationAngle['value'];
            extractedData['Mounting System']['Two Axis']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
      }
    }
    if (jsonData.containsKey('outputs')) {
      Map<String, dynamic> outputs = jsonData['outputs'];
      if (outputs.containsKey('monthly')) {
        List<dynamic>? monthlyData;
        if (outputs['monthly'].containsKey('fixed')) {
          monthlyData = outputs['monthly']['fixed'];
        } else if (outputs['monthly'].containsKey('two_axis')) {
          monthlyData = outputs['monthly']['two_axis'];
        } else if (outputs['monthly'].containsKey('vertical_axis')) {
          monthlyData = outputs['monthly']['vertical_axis'];
        } else if (outputs['monthly'].containsKey('inclined_axis')) {
          monthlyData = outputs['monthly']['inclined_axis'];
        }

        if (monthlyData != null) {
          monthlyData.forEach((data) {
            int month = data['month'];
            extractedData['Month $month'] = {
              'Daily Energy (kWh/m²)': data['E_d'],
              'Monthly Energy (kWh/m²)': data['E_m'],
              'Daily Horizontal Irradiance (kWh/m²)': data['H(i)_d'],
              'Monthly Horizontal Irradiance (kWh/m²)': data['H(i)_m'],
              'Monthly sunshine duration (hours)': data['SD_m'],
            };
          });
        }
      }
    }
    return extractedData;
  }

  Map<String, dynamic> extractImportantDataOffGrid(Map<String, dynamic> jsonData) {
    Map<String, dynamic> extractedData = {};

    extractedData['Maximum Budget (Euros)'] = maxBudget;
    extractedData['Peak Power (kW)'] = peakPower;
    extractedData['Battery Capacity (Wh)'] = capacity;
    extractedData['Battery Discharge Cutoff Limit (%)'] = cutOff;
    extractedData['Daily Energy Consumption (Wh)'] = consumptionDaily;

    if (jsonData.containsKey('inputs')) {
      Map<String, dynamic> inputs = jsonData['inputs'];
      if (inputs.containsKey('location')) {
        Map<String, dynamic> location = inputs['location'];
        extractedData['Location Data'] = {
          'Latitude': location['latitude'],
          'Longitude': location['longitude'],
          'Elevation': location['elevation']
        };
      }
      if (inputs.containsKey('meteo_data')) {
        Map<String, dynamic> meteoData = inputs['meteo_data'];
        extractedData['Radiation Database'] = meteoData['radiation_db'];
      }
      if (inputs.containsKey('pv_module')) {
        Map<String, dynamic> pvModule = inputs['pv_module'];
        extractedData['Peak Power (kW)'] = pvModule['peak_power'];
      }
      if (inputs.containsKey('battery')) {
        Map<String, dynamic> batteryDetails = inputs['battery'];
        extractedData['Battery Capacity (Wh)'] = batteryDetails['capacity'];
        extractedData['Battery Discharge Cutoff Limit (%)'] = batteryDetails['discharge_cutoff_limit'];
      }
      if (inputs.containsKey('consumption')) {
        Map<String, dynamic> consumptionDetails = inputs['consumption'];
        extractedData['Daily Energy Consumption (Wh)'] = consumptionDetails['daily'];
      }

      if (inputs.containsKey('mounting_system')) {
        Map<String, dynamic> mountingSystem = inputs['mounting_system'];
        extractedData['Mounting System'] = {};

        if (mountingSystem.containsKey('fixed')) {
          Map<String, dynamic> fixedParameters = mountingSystem['fixed'];
          if (fixedParameters.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = fixedParameters['slope'];
            extractedData['Mounting System']['Slope (°)'] = slopeParameters['value'];
            extractedData['Mounting System']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (fixedParameters.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = fixedParameters['azimuth'];
            extractedData['Mounting System']['Orientation Angle (°)'] = orientationAngle['value'];
            extractedData['Mounting System']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
      }
    }
    if (jsonData.containsKey('outputs')) {
      Map<String, dynamic> outputs = jsonData['outputs'];
      if (outputs.containsKey('monthly')) {
        List<dynamic>? monthlyData;
        monthlyData = outputs['monthly'];

        if (monthlyData != null) {
          monthlyData.forEach((data) {
            int month = data['month'];
            extractedData['Month $month'] = {
              'Daily Energy (kWh/m²)': data['E_d'],
              'Energy lost Per Day (kWh/m²)': data['E_lost_d'],
              'Fill Factor (%)': data['f_f'],
              'Factor Of Efficiency (%)': data['f_e'],
            };
          });
        }
      }
    }
    return extractedData;
  }

  Widget buildCards(String title, dynamic data) {
    List<Widget> subCards = [];

    if (data is Map<dynamic, dynamic>) {
      subCards = data.entries.expand((entry) {
        if (entry.value is Map<dynamic, dynamic>) {
          // If the value is a map, recursively generate sub-cards
          return buildSubCards(entry.key.toString(), entry.value);
        } else {
          return [buildCard(entry.key.toString(), entry.value.toString())];
        }
      }).toList();
    } else {
      subCards.add(buildCard(title, data.toString()));
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 8),
            ...subCards, // Include the generated sub-cards in the Column
          ],
        ),
      ),
    );
  }

  List<Widget> buildSubCards(String title, Map<dynamic, dynamic> data) {
    List<Widget> subCards = [];

    data.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        // If the value is a map, recursively generate sub-cards
        subCards.addAll(buildSubCards(key.toString(), value));
      } else {
        subCards.add(buildCard(key.toString(), value.toString()));
      }
    });

    return [
      Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 8),
              ...subCards, // Include the generated sub-cards in the Column
            ],
          ),
        ),
      ),
    ];
  }

  Widget buildCard(String title, String value) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(title,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.black,
            letterSpacing: 1.0,
          ),
        ),
        subtitle: Text(value,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.black,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget buildTextFormFieldWithCard(
      String title,
      String value,
      Function(String) onChanged,
      List <TextInputFormatter>? inputFormatters,
      String bodyText,
      ) {
    return Card(
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
            labelText: title,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.yellow,
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black),
            initialValue: value,
            inputFormatters: inputFormatters ?? [],
            onChanged: onChanged,
          ),
          if (bodyText.isNotEmpty) ExpandableCard(
            titleText: title,
            bodyText: bodyText,
          ),
        ],
      ),
    );
  }

  Widget buildItemFormFieldWithCard(
      String title,
      List<String> menuItems,
      String value,
      Function(String?) onChanged,
      String bodyText,
      ) {
    return Card(
      child: Column(
        children: [
          FormField<String>(
            builder: (FormFieldState<String> state) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: title,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isDense: true,
                    onChanged: onChanged,
                    items: menuItems.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          if (bodyText.isNotEmpty) ExpandableCard(
            titleText: title,
            bodyText: bodyText,
          ),
        ],
      ),
    );
  }

  Widget buildSwitchWithCard(
      String title,
      bool value,
      Function(bool) onChanged,
      String bodyText,
      ) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 18,
                letterSpacing: 1.0,
              ),
            ),
            trailing: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
          if (bodyText.isNotEmpty) ExpandableCard(
            titleText: title,
            bodyText: bodyText,
          ),
        ],
      ),
    );
  }

  List<Widget> buildGridConnectedFields() {
    return [
      buildTextFormFieldWithCard(
        'Maximum Budget (Euros)',
        '0',
            (String newValue) {
          setState(() {
            maxBudget = newValue;
          });
        },
        null,
        'The Maximum Budget parameter allows users to input the total cost they anticipate or plan to spend on installing the entire PV system.\n\n'
            'This cost encompasses all the expenses associated with acquiring and installing the solar panels,\n '
            'inverters, mounting hardware, wiring, labor, permits, and any additional costs required for the installation of the PV system.\n\n',
      ),
      const SizedBox(height: 20),
      buildItemFormFieldWithCard(
        'Mountingplace',
        [
          'free',
          'building',
        ],
        selectedMountingPlace,
            (String? newValue) {
          setState(() {
            selectedMountingPlace = newValue!;
            queryParams['mountingplace'] = newValue;
          });
        },
        'Type of mounting of the PV modules. Choices are:\n\n'
            '"free" for free-standing\n'
            '"building" for building-integrated\n\n',
      ),
      const SizedBox(height: 20),
      Column(
        children: [
          buildSwitchWithCard(
            'Fixed',
            fixed,
                (bool newValue) {
              setState(() {
                fixed = newValue;
                queryParams['fixed'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            'Calculate a fixed mounted system.\n\n',
          ),
          const SizedBox(height: 10),
          buildSwitchWithCard(
            'Inclined Axis',
            inclined_axis,
                (bool newValue) {
              setState(() {
                inclined_axis = newValue;
                queryParams['inclined_axis'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            'Calculate a single inclined axis system.\n\n',
          ),
          const SizedBox(height: 10),
          buildSwitchWithCard(
            'Vertical Axis',
            vertical_axis,
                (bool newValue) {
              setState(() {
                vertical_axis = newValue;
                queryParams['vertical_axis'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            'Calculate a single vertical axis system.\n\n',
          ),
          const SizedBox(height: 10),
          buildSwitchWithCard(
            'Two Axis',
            twoaxis,
                (bool newValue) {
              setState(() {
                twoaxis = newValue;
                queryParams['twoaxis'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            'Calculate a two axis tracking system.\n\n',
          ),
        ],
      ),
      const SizedBox(height: 10),
      buildItemFormFieldWithCard(
          'Pvtechchoice',
          [
            'crystSi',
            'CIS',
            'CdTe',
            'Unknown',
          ],
          selectedPvTechChoice,
              (String? newValue) {
            setState(() {
              selectedPvTechChoice = newValue!;
              queryParams['pvtechchoice'] = newValue;
            });
          },
          'Solar Panel technology in use.\n\n'
              'PV technology. Choices are: "crystSi", "CIS", "CdTe" and "Unknown".\n\n'
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          'Peak Power (kW)',
          '5',
              (String newValue) {
            setState(() {
              queryParams['peakpower'] = newValue;
              peakPower = newValue;
            });
          },
          null,
          'Enter the peak power of the solar system in kilowatts.\n\n '
              'This is the maximum power that can be generated by the system under ideal conditions.\n\n'
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          'Loss (%)',
          '15',
              (String newValue) {
            int? value = int.tryParse(newValue);
            if (value != null && value >= 0 && value <= 100) {
              setState(() {
                queryParams['loss'] = newValue;
                loss = newValue;
              });
            } else {
              if (value == null) {
                queryParams['loss'] = '15';
                loss = '15';
              } else {
                final scaffoldContext = ScaffoldMessenger.of(context);
                helper.showSnackBar(
                    "Invalid Loss Value [0 - 100]", "Error",
                    scaffoldContext, duration: 2);
                setState(() {});
              }
            }
          },
          null,
          'Enter the percentage of system loss.\n\n'
              'This accounts for various losses in the system, including efficiency losses and shading.\n\n'
      ),
      const SizedBox(height: 20),
      buildItemFormFieldWithCard(
          'Raddatabase',
          [
            'PVGIS-SARAH',
            'PVGIS-NSRDB',
            'PVGIS-ERA5'
          ],
          selectedRadDatabase,
              (String? newValue) {
            setState(() {
              selectedRadDatabase = newValue!;
              queryParams['raddatabase'] = newValue;
            });
          },
          'The default DBs are PVGIS-SARAH, PVGIS-NSRDB and PVGIS-ERA5 based on the chosen location.\n\n'
      ),
      const SizedBox(height: 20),
      if (fixed || twoaxis) ...[
        buildTextFormFieldWithCard(
            'Angle (°)',
            '0',
                (String newValue) {
              int? value = int.tryParse(newValue);
              if (value != null && value >= 0 && value <= 90) {
                setState(() {
                  queryParams['angle'] = newValue;
                  angle = newValue;
                });
              } else {
                if (value == null) {
                  queryParams['angle'] = '30';
                  angle = '30';
                } else {
                  final scaffoldContext = ScaffoldMessenger.of(context);
                  helper.showSnackBar(
                      "Invalid Angle Value [0 - 90]", "Error",
                      scaffoldContext, duration: 2);
                  setState(() {});
                }
              }
            },
            null,
            'Enter the angle of inclination for the solar panels.\n\n'
                'This is the tilt angle from the horizontal plane at which the solar panels are installed.\n\n'
                '0=south, 90=west, -90=east.\n\n'
        ),
        const SizedBox(height: 20),
        buildTextFormFieldWithCard(
            'Aspect (°)',
            '0',
                (String newValue) {
              int? value = int.tryParse(newValue);
              if (value != null && value >= -180 && value <= 180) {
                setState(() {
                  queryParams['aspect'] = newValue;
                  aspect = newValue;
                });
              } else {
                if (value == null) {
                  queryParams['aspect'] = '180';
                  aspect = '180';
                } else {
                  final scaffoldContext = ScaffoldMessenger.of(context);
                  helper.showSnackBar("Invalid Aspect Value [-180 - 180]", "Error",
                      scaffoldContext, duration: 2);
                  setState(() {});
                }
              }
            },
            null,
            'Enter the aspect of the solar panels.\n\n'
                'This refers to the orientation of the panels with respect to the horizon.\n'
                'An "aspect" value of 0 implies that the panels are oriented towards the south.\n\n'
                'An aspect value of 90 represents a west-facing orientation.\n\n'
                'An aspect value of -90 implies an east-facing orientation..\n\n'
        ),
        const SizedBox(height: 20),
      ],
      buildTextFormFieldWithCard(
          'Lifetime (Years)',
          '25',
              (String newValue) {
            int? value = int.tryParse(newValue);
            if (value != null && value >= 0 && value <= 100) {
              setState(() {
                queryParams['lifetime'] = newValue;
                lifetime = newValue;
              });
            } else {
              if (value == null ) {
                queryParams['lifetime'] = '25';
                lifetime = '1';
              } else {
                final scaffoldContext = ScaffoldMessenger.of(context);
                helper.showSnackBar(
                    "Invalid Lifetime Value [0 - 100]", "Error",
                    scaffoldContext, duration: 2);
                setState(() {});
              }
            }
          },
          null,
          'Expected lifetime of the PV system in years.\n\n'
      ),
      const SizedBox(height: 20),
      buildSwitchWithCard(
        'Use Horizon',
        useHorizon,
            (bool newValue) {
          setState(() {
            useHorizon = newValue;
            queryParams['usehorizon'] = newValue ? '1' : '0';
          });
        },
        'Calculate taking into account shadows from high horizon.\n\n',
      ),
      const SizedBox(height: 20),
      if (fixed || twoaxis) ...[
        buildSwitchWithCard(
          'Optimal Inclination',
          optimalinclination,
              (bool newValue) {
            setState(() {
              optimalinclination = newValue;
              queryParams['optimalinclination'] = newValue ? '1' : '0';
            });
          },
          'Calculate the optimum inclination angle.\n\n'
              'For the fixed PV system, if this parameter is enabled, the value defined for the "Angle" parameter is ignored',
        ),
        const SizedBox(height: 20),
        buildSwitchWithCard(
            'Optimal Angles',
            optimalangles,
                (bool newValue) {
              setState(() {
                optimalangles = newValue;
                queryParams['optimalangles'] = newValue ? '1' : '0';
              });
            },
            'Calculate the optimum inclination and orientation angles.\n\n'
                'If this parameter is enabled, values defined for "Angle" and "Aspect" are ignored and therefore are not necessary'
        ),
        const SizedBox(height: 20),
      ],
      if (inclined_axis) ...[
        buildSwitchWithCard(
            'Inclined Optimum',
            inclined_optimum,
                (bool newValue) {
              setState(() {
                inclined_optimum = newValue;
                queryParams['inclined_optimum'] = newValue ? '1' : '0';
              });
            },
            'Calculate optimum angle for a single inclined axis system.\n\n'
        ),
        const SizedBox(height: 20),
        buildTextFormFieldWithCard(
            'Inclined Axis Angle (°)',
            '0',
                (String newValue) {
              setState(() {
                queryParams['inclinedaxisangle'] = newValue;
              });
            },
            null,
            'Inclination angle for a single inclined axis system.\n\n'
                'Ignored if the optimum angle should be calculated.\n\n'
        ),
        const SizedBox(height: 20),
      ],
      if (vertical_axis) ...[
        buildSwitchWithCard(
            'Vertical Optimum',
            vertical_optimum,
                (bool newValue) {
              setState(() {
                vertical_optimum = newValue;
                queryParams['vertical_optimum'] = newValue ? '1' : '0';
              });
            },
            'Calculate optimum angle for a single vertical axis system.\n\n'
        ),
        const SizedBox(height: 20),
        buildTextFormFieldWithCard(
            'Vertical Axis Angle (°)',
            '0',
                (String newValue) {
              setState(() {
                queryParams['verticalaxisangle'] = newValue;
              });
            },
            null,
            'Inclination angle for a single vertical axis system.\n\n'
                'Ignored if the optimum angle should be calculated.\n\n'
        ),
        const SizedBox(height: 20),
      ],
      if (calcButtonEnabled) ...[
        ElevatedButton(
          onPressed: () {
            fetchSolarData(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.all(20.0),
            shape: CircleBorder(),
          ),
          child: Icon(Icons.calculate, size: 80, color: Colors.white),
        ),
      ],
    ];
  }

  List<Widget> buildOffGridFields() {
    return [
      buildTextFormFieldWithCard(
        'Maximum Budget (Euros)',
        '0',
            (String newValue) {
          setState(() {
            maxBudget = newValue;
          });
        },
        null,
        'The Maximum Budget parameter allows users to input the total cost they anticipate or plan to spend on installing the entire PV system.\n\n'
            'This cost encompasses all the expenses associated with acquiring and installing the solar panels,\n '
            'inverters, mounting hardware, wiring, labor, permits, and any additional costs required for the installation of the PV system.\n\n',
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          'Peak Power (kW)',
          '5',
              (String newValue) {
            setState(() {
              queryParamsOffGrid['peakpower'] = newValue;
              peakPower = newValue;
            });
          },
          null,
          'Enter the peak power of the solar system in kilowatts.\n\n '
              'This is the maximum power that can be generated by the system under ideal conditions.\n\n'
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          'Battery Size (Wh)',
          '50',
              (String newValue) {
            int? value = int.tryParse(newValue);
            if (value == null) {
              queryParamsOffGrid['batterysize'] = '50';
              capacity = '50';
            }
            setState(() {
              queryParamsOffGrid['batterysize'] = newValue;
              capacity = newValue;
            });
          },
          null,
          'This is the size, or energy capacity, of the battery used in the off-grid system, '
              'measured in watt-hours (Wh).\n\n'
      ),
      buildTextFormFieldWithCard(
          'Battery Cutoff (%)',
          '50',
              (String newValue) {
            int? value = int.tryParse(newValue);
            if (value != null && value >= 0 && value <= 100) {
              setState(() {
                queryParamsOffGrid['cutoff'] = newValue;
                cutOff = newValue;
              });
            } else {
              if (value == null ) {
                queryParamsOffGrid['cutoff'] = '50';
                cutOff = '50';
              } else {
                final scaffoldContext = ScaffoldMessenger.of(context);
                helper.showSnackBar(
                    "Invalid Battery Cutoff Value [0 - 100]", "Error",
                    scaffoldContext, duration: 2);
                setState(() {});
              }
            }
          },
          null,
          'Batteries cutoff in %. '
              'The cutoff is imposed so that the battery charge cannot go below a certain percentage of full charge..\n\n'
      ),
      const SizedBox(height: 20),
      buildItemFormFieldWithCard(
          'Raddatabase',
          [
            'PVGIS-SARAH',
            'PVGIS-NSRDB',
            'PVGIS-ERA5',
            'PVGIS-COSMO'
          ],
          selectedRadDatabase,
              (String? newValue) {
            setState(() {
              selectedRadDatabase = newValue!;
              queryParamsOffGrid['raddatabase'] = newValue;
            });
          },
          'Name of the radiation database. '
              '"PVGIS-SARAH" for Europe, Africa and Asia or '
              '"PVGIS-NSRDB" for the Americas between 60°N and 20°S, '
              '"PVGIS-ERA5" and "PVGIS-COSMO" for Europe (including high-latitudes).\n\n'
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          'Angle (°)',
          '0',
              (String newValue) {
            int? value = int.tryParse(newValue);
            if (value != null && value >= 0 && value <= 90) {
              setState(() {
                queryParamsOffGrid['angle'] = newValue;
                angle = newValue;
              });
            } else {
              if (value == null) {
                queryParamsOffGrid['angle'] = '30';
                angle = '30';
              } else {
                final scaffoldContext = ScaffoldMessenger.of(context);
                helper.showSnackBar(
                    "Invalid Angle Value [0 - 90]", "Error",
                    scaffoldContext, duration: 2);
                setState(() {});
              }
            }
          },
          null,
          'Enter the angle of inclination for the solar panels.\n\n'
              'This is the tilt angle from the horizontal plane at which the solar panels are installed.\n\n'
              '0=south, 90=west, -90=east.\n\n'
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          'Aspect (°)',
          '0',
              (String newValue) {
            int? value = int.tryParse(newValue);
            if (value != null && value >= -180 && value <= 180) {
              setState(() {
                queryParamsOffGrid['aspect'] = newValue;
                aspect = newValue;
              });
            } else {
              if (value == null) {
                queryParamsOffGrid['aspect'] = '180';
                aspect = '180';
              } else {
                final scaffoldContext = ScaffoldMessenger.of(context);
                helper.showSnackBar("Invalid Aspect Value [-180 - 180]", "Error",
                    scaffoldContext, duration: 2);
                setState(() {});
              }
            }
          },
          null,
          'Enter the aspect of the solar panels.\n\n'
              'This refers to the orientation of the panels with respect to the horizon.\n'
              'An "aspect" value of 0 implies that the panels are oriented towards the south.\n\n'
              'An aspect value of 90 represents a west-facing orientation.\n\n'
              'An aspect value of -90 implies an east-facing orientation..\n\n'
      ),
      const SizedBox(height: 20),
      buildSwitchWithCard(
        'Use Horizon',
        useHorizon,
            (bool newValue) {
          setState(() {
            useHorizon = newValue;
            queryParamsOffGrid['usehorizon'] = newValue ? '1' : '0';
          });
        },
        'Calculate taking into account shadows from high horizon.\n\n',
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          'Consumption Per Day (Wh)',
          '200',
              (String newValue) {
            int? value = int.tryParse(newValue);
            if (value == null) {
              queryParamsOffGrid['consumptionday'] = '200';
              consumptionDaily = '200';
            }
            setState(() {
              queryParamsOffGrid['consumptionday'] = newValue;
              consumptionDaily = newValue;
            });
          },
          null,
          'Energy consumption of all the electrical equipment connected to the system during a 24 hour period (Wh).\n\n'
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          fetchSolarData(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.all(20.0),
          shape: CircleBorder(),
        ),
        child: Icon(Icons.calculate, size: 80, color: Colors.white),
      ),
    ];
  }

  Widget buildSystemTypeSelector() {
    return Card(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue, // Set the background color
          borderRadius: BorderRadius.circular(5), // Optional: add a border radius
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedSystemType,
            onChanged: (String? newValue) {
              setState(() {
                selectedSystemType = newValue!;
              });
            },
            items: <String>[
              'Grid-connected & Tracking PV systems',
              'Off-grid PV systems'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ), // Set text color to white for contrast
              );
            }).toList(),
            dropdownColor: Colors.blue, // Set the dropdown menu's background color
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 1.0,
            ), // Set the text style for the dropdown items
          ),
        ),
      ),
    );
  }

  Widget buildForm() {
    return SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildSystemTypeSelector(),
              SizedBox(height: 20),
              if (selectedSystemType == 'Grid-connected & Tracking PV systems')
                ...buildGridConnectedFields(), // Function to build fields for Grid-connected
              if (selectedSystemType == 'Off-grid PV systems')
                ...buildOffGridFields(), // Function to build fields for Off-grid
            ],
          ),
        ),
      );
    }

    Widget buildResult() {
      widget.docOperations.setProgressNotifierDictValue(documentId);
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showForm = true;
                      solarData = null;
                      resetQueryParams();
                      // First Reset the Progress Bar
                      widget.docOperations.resetProgressNotifierDictValue(documentId);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.all(20.0),
                    shape: CircleBorder(),
                  ),
                  child: Icon(Icons.refresh, size: 40, color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: () {
                    final scaffoldContext = ScaffoldMessenger.of(context);
                    selectedSystemType == 'Grid-connected & Tracking PV systems' ? generateAndPreviewPdf(solarData ?? {}, scaffoldContext) : generateAndPreviewPdfOffGrid(solarData ?? {}, scaffoldContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.all(20.0),
                    shape: CircleBorder(),
                  ),
                  child: Icon(Icons.send, size: 40, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (isUploading)
              Center(
                child: Align(
                  alignment: Alignment.center,
                  child: LinearProgressIndicator(
                    minHeight: 4.0, // Adjust the thickness
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
            SizedBox(height: 20),
            if (solarData != null)
              ...solarData!.entries.expand((entry) {
                if (entry.value is Map<dynamic, dynamic>) {
                  return buildSubCards(entry.key.toString(), entry.value);
                } else if (entry.value is String) {
                  return [
                    buildCard(entry.key.toString(), entry.value.toString()),
                  ];
                } else {
                  return [
                    buildCard(entry.key.toString(), entry.value.toString()),
                  ];
                }
              }).toList(),
          ],
        ),
      );
    }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'helpers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'solar_ai_card.dart';

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
    'loss': '15',
    'angle': '30',
    'aspect': '180',
    'usehorizon' : '0',
    'pvcalculation': '0',
    'trackingtype': '0',
    'optimalinclination': '0',
    'optimalangles': '0',
    'lifetime': '25',
    'inclined_axis': '0',
    'inclined_optimum': '0',
    'inclinedaxisangle': '0',
    'vertical_axis': '0',
    'vertical_optimum': '0',
    'verticalaxisangle': '0',
    'twoaxis': '25',
    'outputformat': 'json',
  };
  bool showForm = true;
  String selectedRaddatabase = 'PVGIS-SARAH'; // Default value
  String selectedPvtechchoice = 'crystSi'; // Default value
  String selectedMountingplace = 'building'; // Default value
  bool useHorizon = false; // Default value
  bool pvcalculation = false; // Default value
  bool optimalinclination = false; // Default value
  bool optimalangles = false; // Default value
  bool inclined_axis = false;
  bool inclined_optimum = false;
  bool inclinedaxisangle = false;
  bool vertical_axis = false;
  bool vertical_optimum = false;
  bool verticalaxisangle = false;
  bool twoaxis = false;

  bool isLoading = false;
  Helper helper = Helper();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solar Data'),
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
        children: [
          SingleChildScrollView(
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
        ],
      ),
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

      queryParams['lat'] = position.latitude.toString();
      queryParams['lon'] = position.longitude.toString();
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

    String apiUrl = 'https://re.jrc.ec.europa.eu/api/PVcalc';
    Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);
    print(uri);

    try {
      http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        print(jsonData);
        setState(() {
          solarData = extractImportantData(jsonData);
          showForm = false;
          isLoading = false;
        });
      } else {
        helper.showSnackBar('Failed to fetch solar data. Status Code: ${response.statusCode}', "Error", scaffoldContext);
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
      if (inputs.containsKey('pv_module')) {
        Map<String, dynamic> pvModule = inputs['pv_module'];
        extractedData['Technology'] = pvModule['technology'];
        extractedData['Peak Power'] = pvModule['peak_power'];
        extractedData['System Loss'] = pvModule['system_loss'];
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
            extractedData['Mounting System']['Slope'] = slopeParameters['value'];
            extractedData['Mounting System']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (fixedParameters.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = fixedParameters['azimuth'];
            extractedData['Mounting System']['Orientation Angle'] = orientationAngle['value'];
            extractedData['Mounting System']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
        if (mountingSystem.containsKey('vertical_axis')) {
          Map<String, dynamic> verticalAxis = mountingSystem['vertical_axis'];
          extractedData['Mounting System']['Vertical Axis'] = {};
          if (verticalAxis.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = verticalAxis['slope'];
            extractedData['Mounting System']['Vertical Axis']['Slope'] = slopeParameters['value'];
            extractedData['Mounting System']['Vertical Axis']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (verticalAxis.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = verticalAxis['azimuth'];
            extractedData['Mounting System']['Vertical Axis']['Orientation Angle'] = orientationAngle['value'];
            extractedData['Mounting System']['Vertical Axis']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
        if (mountingSystem.containsKey('inclined_axis')) {
          Map<String, dynamic> inclinedAxis = mountingSystem['inclined_axis'];
          extractedData['Mounting System']['Inclined Axis'] = {};
          if (inclinedAxis.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = inclinedAxis['slope'];
            extractedData['Mounting System']['Inclined Axis']['Slope'] = slopeParameters['value'];
            extractedData['Mounting System']['Inclined Axis']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (inclinedAxis.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = inclinedAxis['azimuth'];
            extractedData['Mounting System']['Inclined Axis']['Orientation Angle'] = orientationAngle['value'];
            extractedData['Mounting System']['Inclined Axis']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
        if (mountingSystem.containsKey('two_axis')) {
          Map<String, dynamic> twoAxis = mountingSystem['two_axis'];
          extractedData['Mounting System']['Two Axis'] = {};
          if (twoAxis.containsKey('slope')) {
            Map<String, dynamic> slopeParameters = twoAxis['slope'];
            extractedData['Mounting System']['Two Axis']['Slope'] = slopeParameters['value'];
            extractedData['Mounting System']['Two Axis']['Slope is Optimal'] = slopeParameters['optimal'];
          }
          if (twoAxis.containsKey('azimuth')) {
            Map<String, dynamic> orientationAngle = twoAxis['azimuth'];
            extractedData['Mounting System']['Two Axis']['Orientation Angle'] = orientationAngle['value'];
            extractedData['Mounting System']['Two Axis']['Orientation Angle is Optimal'] = orientationAngle['optimal'];
          }
        }
      }
    }
    if (jsonData.containsKey('outputs')) {
      Map<String, dynamic> outputs = jsonData['outputs'];
      if (outputs.containsKey('monthly')) {
        List<dynamic> monthlyData = outputs['monthly']['fixed'];
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
      if (outputs.containsKey('hourly')) {
        List<dynamic> hourlyData = outputs['hourly']['fixed']; // Replace 'fixed' with your specific hourly data key
        extractedData['Hourly Estimations'] = hourlyData;
      }
    }
    print("aaaaaaaaaaaaaaaa");
    print(extractedData['Mounting System']);
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget buildForm() {
    return SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Peak Power (kW)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  queryParams['peakpower'] = value;
                },
                initialValue: '5', // Default value set to 5 kW
              ),
              const SizedBox(height: 10),
              // Elevated Card describing optimalangles
              const ExpandableCard(titleText: 'Peak Power', bodyText:  'Enter the peak power of the solar system in kilowatts.\n\n '
                  'This is the maximum power that can be generated by the system under ideal conditions.\n\n'),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Loss (%)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  queryParams['loss'] = value;
                },
                initialValue: '15',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-100]')), // Allow only values from 0 to 5
                ],// Default value set to 15%
              ),
              const SizedBox(height: 10),
              // Elevated Card describing Raddatabase
              const ExpandableCard(titleText: 'Loss', bodyText:  'Enter the percentage of system loss.\n\n'
                  'This accounts for various losses in the system, including efficiency losses and shading.\n\n',),
              const SizedBox(height: 20),
              FormField<String>(
                builder: (FormFieldState<String> state) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Raddatabase',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.yellow,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRaddatabase,
                        isDense: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRaddatabase = newValue!;
                            queryParams['raddatabase'] = newValue;
                          });
                        },
                        items: <String>['PVGIS-SARAH', 'PVGIS-NSRDB', 'PVGIS-ERA5'].map((String value) {
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
              const SizedBox(height: 10),
              // Elevated Card describing optimalangles
              const ExpandableCard(titleText: 'Raddatabase', bodyText: 'The default DBs are PVGIS-SARAH, PVGIS-NSRDB and PVGIS-ERA5 based on the chosen location.\n\n'),
              const SizedBox(height: 20),
              FormField<String>(
                builder: (FormFieldState<String> state) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Pvtechchoice',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.yellow,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPvtechchoice,
                        isDense: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPvtechchoice = newValue!;
                            queryParams['pvtechchoice'] = newValue;
                          });
                        },
                        items: <String>['crystSi', 'CIS', 'CdTe', 'Unknown'].map((String value) {
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
              const SizedBox(height: 10),
              // Elevated Card describing pvtechchoice
              const ExpandableCard(titleText: 'Pvtechchoice', bodyText:  'Solar Panel technology in use.\n\n'
                  'PV technology. Choices are: "crystSi", "CIS", "CdTe" and "Unknown".\n\n',),
              const SizedBox(height: 20),
              FormField<String>(
                builder: (FormFieldState<String> state) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Mountingplace',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.yellow,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMountingplace,
                        isDense: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMountingplace = newValue!;
                            queryParams['mountingplace'] = newValue;
                          });
                        },
                        items: <String>['free', 'building'].map((String value) {
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
              const SizedBox(height: 10),
              // Elevated Card describing Mountingplace
              const ExpandableCard(titleText: 'Mountingplace', bodyText: 'Type of mounting of the PV modules. Choices are:\n\n'
                  '"free" for free-standing\n\n'
                  '"building" for building-integrated\n\n',),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Angle (°)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  queryParams['angle'] = value;
                },
                initialValue: '30',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-360]')), // Allow only values from 0 to 5
                ],// Default value set to '30' degrees
              ),
              const SizedBox(height: 10),
              // Elevated Card describing angle
              const ExpandableCard(titleText: 'Angle', bodyText:  'Enter the angle of inclination for the solar panels.\n\n'
                  'This is the tilt angle from the horizontal plane at which the solar panels are installed.\n\n'
                  '0=south, 90=west, -90=east.\n\n',),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Aspect (°)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  queryParams['aspect'] = value;
                },
                initialValue: '180',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-360]')), // Allow only values from 0 to 5
                ],// Default value set to '180'
              ),
              const SizedBox(height: 10),
              // Elevated Card describing aspect
              const ExpandableCard(titleText: 'Aspect', bodyText:  'Enter the aspect of the solar panels.\n\n'
                  'This refers to the orientation of the panels with respect to the horizon.\n'
                  'An "aspect" value of 0 implies that the panels are oriented towards the south.\n\n'
                  'An aspect value of 90 represents a west-facing orientation.\n\n'
                  'An aspect value of -90 implies an east-facing orientation..\n\n',),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Maximum Budget',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                initialValue: '0',
              ),
              const SizedBox(height: 10),
              // Elevated Card describing systemcost
              const ExpandableCard(titleText: 'Maximum Budget', bodyText:  'The Maximum Budget parameter allows users to input the total cost they anticipate or plan to spend on installing the entire PV system.\n\n'
                  'This cost encompasses all the expenses associated with acquiring and installing the solar panels,\n '
                  'inverters, mounting hardware, wiring, labor, permits, and any additional costs required for the installation of the PV system.\n\n'),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Lifetime',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  queryParams['lifetime'] = value;
                },
                initialValue: '25',
              ),
              const SizedBox(height: 10),
              // Elevated Card describing lifetime
              const ExpandableCard(titleText: 'Lifetime', bodyText: 'Expected lifetime of the PV system in years.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Horizon',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: useHorizon,
                    onChanged: (bool newValue) {
                      setState(() {
                        useHorizon = newValue;
                        queryParams['usehorizon'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Elevated Card describing usehorizon
              const ExpandableCard(titleText: 'Use Horizon', bodyText: 'Calculate taking into account shadows from high horizon.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hourly PV Production estimation',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: pvcalculation,
                    onChanged: (bool newValue) {
                      setState(() {
                        pvcalculation = newValue;
                        queryParams['pvcalculation'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Elevated Card describing pvcalculation
              const ExpandableCard(titleText: 'PV Calculation', bodyText: 'If disabled, calculate solar radiations only\n\n'
                  'If enabled, estimate the hourly PV production.\n\n'),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Tracking Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.yellow,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  queryParams['trackingtype'] = value;
                },
                initialValue: '0',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-5]')), // Allow only values from 0 to 5
                ],
              ),
              const SizedBox(height: 10),
              // Elevated Card describing trackingtype
              const ExpandableCard(titleText: 'Tracking Type', bodyText:  '0 (Fixed): Solar panels are fixed in place and do not adjust their orientation throughout the day to track the sun\'s position.\n\n'
                  '1 (Single Horizontal Axis North-South): Panels move along a single horizontal axis aligned north-south to optimize sun exposure.\n\n'
                  '2 (Two-Axis Tracking): Panels adjust along both horizontal and vertical axes to follow the sun\'s position for maximum exposure.\n\n'
                  '3 (Vertical Axis Tracking): Panels rotate around a vertical axis to track the sun\'s movement.\n\n'
                  '4 (Single Horizontal Axis East-West): Panels move along a single horizontal axis aligned east-west to optimize sun exposure.\n\n'
                  '5 (Single Inclined Axis North-South): Panels adjust along a single inclined axis aligned north-south to track the sun\'s movement at an inclined angle.',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimal Inclination',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: optimalinclination,
                    onChanged: (bool newValue) {
                      setState(() {
                        optimalinclination = newValue;
                        queryParams['optimalinclination'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Elevated Card describing optimal inclination
              const ExpandableCard(titleText: 'Optimal Inclination', bodyText: 'Calculate the optimum inclination angle.\n\n'
                  'For the fixed PV system, if this parameter is enabled, the value defined for the "Angle" parameter is ignored',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimal Angles',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: optimalangles,
                    onChanged: (bool newValue) {
                      setState(() {
                        optimalangles = newValue;
                        queryParams['optimalangles'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Elevated Card describing optimal angles
              const ExpandableCard(titleText: 'Optimal Angles', bodyText: 'Calculate the optimum inclination and orientation angles.\n\n'
                  'If this parameter is enabled, values defined for "Angle" and "Aspect" are ignored and therefore are not necessary',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inclined Axis',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: inclined_axis,
                    onChanged: (bool newValue) {
                      setState(() {
                        inclined_axis = newValue;
                        queryParams['inclined_axis'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ExpandableCard(titleText: 'Inclined Axis', bodyText: 'Calculate a single inclined axis system.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inclined Optimum',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: inclined_optimum,
                    onChanged: (bool newValue) {
                      setState(() {
                        inclined_optimum = newValue;
                        queryParams['inclined_optimum'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ExpandableCard(titleText: 'Inclined Optimum', bodyText: 'Calculate optimum angle for a single inclined axis system.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inclined Axis Angle',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: inclinedaxisangle,
                    onChanged: (bool newValue) {
                      setState(() {
                        inclinedaxisangle = newValue;
                        queryParams['inclinedaxisangle'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ExpandableCard(titleText: 'Inclined Axis Angle', bodyText: 'Inclination angle for a single inclined axis system.\n\n'
                  'Ignored if the optimum angle should be calculated.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vertical Axis',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: vertical_axis,
                    onChanged: (bool newValue) {
                      setState(() {
                        vertical_axis = newValue;
                        queryParams['vertical_axis'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ExpandableCard(titleText: 'Vertical Axis', bodyText: 'Calculate a single vertical axis system.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vertical Optimum',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: vertical_optimum,
                    onChanged: (bool newValue) {
                      setState(() {
                        vertical_optimum = newValue;
                        queryParams['vertical_optimum'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ExpandableCard(titleText: 'Vertical Optimum', bodyText: 'Calculate optimum angle for a single vertical axis system.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vertical Axis Angle',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: verticalaxisangle,
                    onChanged: (bool newValue) {
                      setState(() {
                        verticalaxisangle = newValue;
                        queryParams['verticalaxisangle'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ExpandableCard(titleText: 'Vertical Axis Angle', bodyText: 'Inclination angle for a single vertical axis system.\n\n'
                  'Ignored if the optimum angle should be calculated.\n\n',),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two Axis',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: twoaxis,
                    onChanged: (bool newValue) {
                      setState(() {
                        twoaxis = newValue;
                        queryParams['twoaxis'] = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ExpandableCard(titleText: 'Two Axis', bodyText: 'Calculate a two axis tracking system.\n\n',),
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
            ],
          ),
        ),
      );
    }

    Widget buildResult() {
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
                    // Perform the action to send results to PuraVida GmbH
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
            if (solarData != null)
              ...solarData!.entries.expand((entry) {
                if (entry.value is Map<dynamic, dynamic>) {
                  return buildSubCards(entry.key.toString(), entry.value);
                } else if (entry.value is String) {
                  return [
                    buildCard(entry.key.toString(), entry.value.toString()),
                  ];
                }
                // Add additional cases if needed (e.g., handling other data types)

                return []; // Default return empty list if no condition is met
              }).toList(),
          ],
        ),
      );
    }
}
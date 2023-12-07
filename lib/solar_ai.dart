import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class SolarDataFetcher extends StatefulWidget {
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
    'outputformat': 'json',
  };
  bool showForm = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Solar Data')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: showForm ? buildForm() : buildResult(),
      ),
    );
  }

  Future<void> fetchLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle permission denied scenario
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle permanently denied scenario
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      queryParams['lat'] = position.latitude.toString();
      queryParams['lon'] = position.longitude.toString();
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  Future<void> fetchSolarData() async {
    await fetchLocation();

    String apiUrl = 'https://re.jrc.ec.europa.eu/api/PVcalc';
    Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

    try {
      http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        setState(() {
          solarData = extractImportantData(jsonData);
          showForm = false;
        });
      } else {
        print(
            'Failed to fetch solar data. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching solar data: $error');
    }
  }

  Map<String, dynamic> extractImportantData(Map<String, dynamic> jsonData) {
    Map<String, dynamic> extractedData = {};

    if (jsonData.containsKey('inputs')) {
      Map<String, dynamic> inputs = jsonData['inputs'];
      if (inputs.containsKey('location')) {
        Map<String, dynamic> location = inputs['location'];
        extractedData['Latitude'] = location['latitude'];
        extractedData['Longitude'] = location['longitude'];
        extractedData['Elevation'] = location['elevation'];
      }
      if (inputs.containsKey('pv_module')) {
        Map<String, dynamic> pvModule = inputs['pv_module'];
        extractedData['Technology'] = pvModule['technology'];
        extractedData['Peak Power'] = pvModule['peak_power'];
        extractedData['System Loss'] = pvModule['system_loss'];
      }
    }
    if (jsonData.containsKey('outputs')) {
      Map<String, dynamic> outputs = jsonData['outputs'];
      if (outputs.containsKey('monthly')) {
        List<dynamic> monthlyData = outputs['monthly']['fixed'];
        monthlyData.forEach((data) {
          int month = data['month'];
          extractedData['Month $month - Energy (kWh/m²)'] = data['E_m'];
        });
      }
    }
    return extractedData;
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Peak Power',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.yellow,
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              queryParams['peakpower'] = value;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Loss',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.yellow,
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              queryParams['loss'] = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Raddatabase',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.yellow,
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              queryParams['raddatabase'] = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Pvtechchoice',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.yellow,
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              queryParams['pvtechchoice'] = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Mountingplace',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.yellow,
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              queryParams['mountingplace'] = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Angle',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.yellow,
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              queryParams['angle'] = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Aspect',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.yellow,
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              queryParams['aspect'] = value;
            },
          ),
          // Add other TextFormField widgets for parameters...
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                fetchSolarData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: const Text(
              "Calculate",
              style: TextStyle(color: Colors.white, fontSize: 18.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResult() {
    return Column(
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
          ...solarData!.entries.map((entry) {
            return buildCard(entry.key, entry.value.toString());
          }).toList(),
      ],
    );
  }
}
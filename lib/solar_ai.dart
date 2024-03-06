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
import 'language_service.dart';
import 'text_contents.dart';

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

  String _selectedLanguage = 'German';
  // Language related content
  String solarDataTitleGerman = getTextContentGerman("solarDataTitle");
  String solarDataTitleEnglish = getTextContentEnglish("solarDataTitle");

  String solarDataForecastGerman = getTextContentGerman("solarDataForecast");
  String solarDataForecastEnglish = getTextContentEnglish("solarDataForecast");

  String solarDataOverviewGerman = getTextContentGerman("solarDataOverview");
  String solarDataOverviewEnglish = getTextContentEnglish("solarDataOverview");

  String solarDataMaxBudgetGerman = getTextContentGerman("solarDataMaxBudget");
  String solarDataMaxBudgetEnglish = getTextContentEnglish("solarDataMaxBudget");

  String solarDataMaxLifetimeGerman = getTextContentGerman("solarDataMaxLifetime");
  String solarDataMaxLifetimeEnglish = getTextContentEnglish("solarDataMaxLifetime");

  String solarDataTechnologyGerman = getTextContentGerman("solarDataTechnology");
  String solarDataTechnologyEnglish = getTextContentEnglish("solarDataTechnology");

  String solarDataPeakPowerGerman = getTextContentGerman("solarDataPeakPower");
  String solarDataPeakPowerEnglish = getTextContentEnglish("solarDataPeakPower");

  String solarDataSystemLossGerman = getTextContentGerman("solarDataSystemLoss");
  String solarDataSystemLossEnglish = getTextContentEnglish("solarDataSystemLoss");

  String solarDataDatabaseGerman = getTextContentGerman("solarDataDatabase");
  String solarDataDatabaseEnglish = getTextContentEnglish("solarDataDatabase");

  String solarDataLocationDataGerman = getTextContentGerman("solarDataLocationData");
  String solarDataLocationDataEnglish = getTextContentEnglish("solarDataLocationData");

  String solarDataElevationGerman = getTextContentGerman("solarDataElevation");
  String solarDataElevationEnglish = getTextContentEnglish("solarDataElevation");

  String solarDataMountingSystemGerman = getTextContentGerman("solarDataMountingSystem");
  String solarDataMountingSystemEnglish = getTextContentEnglish("solarDataMountingSystem");

  String solarDataTypeGerman = getTextContentGerman("solarDataType");
  String solarDataTypeEnglish = getTextContentEnglish("solarDataType");

  String solarDataSlopeGerman = getTextContentGerman("solarDataSlope");
  String solarDataSlopeEnglish = getTextContentEnglish("solarDataSlope");

  String solarDataSlopeOptimalGerman = getTextContentGerman("solarDataSlopeOptimal");
  String solarDataSlopeOptimalEnglish = getTextContentEnglish("solarDataSlopeOptimal");

  String solarDataOrientationAngleGerman = getTextContentGerman("solarDataOrientationAngle");
  String solarDataOrientationAngleEnglish = getTextContentEnglish("solarDataOrientationAngle");

  String solarDataOrientationAngleOptimalGerman = getTextContentGerman("solarDataOrientationAngleOptimal");
  String solarDataOrientationAngleOptimalEnglish = getTextContentEnglish("solarDataOrientationAngleOptimal");

  String solarDataBatteryCapacityGerman = getTextContentGerman("solarDataBatteryCapacity");
  String solarDataBatteryCapacityEnglish = getTextContentEnglish("solarDataBatteryCapacity");

  String solarDataBatteryDischargeCutoffLimitGerman = getTextContentGerman("solarDataBatteryDischargeCutoffLimit");
  String solarDataBatteryDischargeCutoffLimitEnglish = getTextContentEnglish("solarDataBatteryDischargeCutoffLimit");

  String solarDataDailyEnergyConsumptionGerman = getTextContentGerman("solarDataDailyEnergyConsumption");
  String solarDataDailyEnergyConsumptionEnglish = getTextContentEnglish("solarDataDailyEnergyConsumption");

  String solarDataMonthGerman = getTextContentGerman("solarDataMonth");
  String solarDataMonthEnglish = getTextContentEnglish("solarDataMonth");

  String solarDataDailyEnergyGerman = getTextContentGerman("solarDataDailyEnergy");
  String solarDataDailyEnergyEnglish = getTextContentEnglish("solarDataDailyEnergy");

  String solarDataMonthlyEnergyGerman = getTextContentGerman("solarDataMonthlyEnergy");
  String solarDataMonthlyEnergyEnglish = getTextContentEnglish("solarDataMonthlyEnergy");

  String solarDataDailyIrradianceGerman = getTextContentGerman("solarDataDailyIrradiance");
  String solarDataDailyIrradianceEnglish = getTextContentEnglish("solarDataDailyIrradiance");

  String solarDataMonthlyIrradianceGerman = getTextContentGerman("solarDataMonthlyIrradiance");
  String solarDataMonthlyIrradianceEnglish = getTextContentEnglish("solarDataMonthlyIrradiance");

  String solarDataSunshineDurationGerman = getTextContentGerman("solarDataSunshineDuration");
  String solarDataSunshineDurationEnglish = getTextContentEnglish("solarDataSunshineDuration");

  String solarDataEnergyLostPerDayGerman = getTextContentGerman("solarDataEnergyLostPerDay");
  String solarDataEnergyLostPerDayEnglish = getTextContentEnglish("solarDataEnergyLostPerDay");

  String solarDataFillFactorGerman = getTextContentGerman("solarDataFillFactor");
  String solarDataFillFactorEnglish = getTextContentEnglish("solarDataFillFactor");

  String solarDataFactorOfEfficiencyGerman = getTextContentGerman("solarDataFactorOfEfficiency");
  String solarDataFactorOfEfficiencyEnglish = getTextContentEnglish("solarDataFactorOfEfficiency");

  String solarDataLocationDataPermissionErrorGerman = getTextContentGerman("solarDataLocationDataPermissionError");
  String solarDataLocationDataPermissionErrorEnglish = getTextContentEnglish("solarDataLocationDataPermissionError");

  String solarDataPermanentLocationDataPermissionErrorGerman = getTextContentGerman("solarDataPermanentLocationDataPermissionError");
  String solarDataPermanentLocationDataPermissionErrorEnglish = getTextContentEnglish("solarDataPermanentLocationDataPermissionError");

  String solarDataErrorFetchingLocationGerman = getTextContentGerman("solarDataErrorFetchingLocation");
  String solarDataErrorFetchingLocationEnglish = getTextContentEnglish("solarDataErrorFetchingLocation");

  String solarDataMaxBudgetEurosGerman = getTextContentGerman("solarDataMaxBudgetEuros");
  String solarDataMaxBudgetEurosEnglish = getTextContentEnglish("solarDataMaxBudgetEuros");

  String solarDataMaxBudgetDescriptionGerman = getTextContentGerman("solarDataMaxBudgetDescription");
  String solarDataMaxBudgetDescriptionEnglish = getTextContentEnglish("solarDataMaxBudgetDescription");

  String solarDataMountingPlaceGerman = getTextContentGerman("solarDataMountingPlace");
  String solarDataMountingPlaceEnglish = getTextContentEnglish("solarDataMountingPlace");

  String solarDataTypeDescriptionGerman = getTextContentGerman("solarDataTypeDescription");
  String solarDataTypeDescriptionEnglish = getTextContentEnglish("solarDataTypeDescription");

  String solarDataFixedGerman = getTextContentGerman("solarDataFixed");
  String solarDataFixedEnglish = getTextContentEnglish("solarDataFixed");

  String solarDataFixedDescriptionGerman = getTextContentGerman("solarDataFixedDescription");
  String solarDataFixedDescriptionEnglish = getTextContentEnglish("solarDataFixedDescription");

  String solarDataInclinedAxisGerman = getTextContentGerman("solarDataInclinedAxis");
  String solarDataInclinedAxisEnglish = getTextContentEnglish("solarDataInclinedAxis");

  String solarDataInclinedAxisDescriptionGerman = getTextContentGerman("solarDataInclinedAxisDescription");
  String solarDataInclinedAxisDescriptionEnglish = getTextContentEnglish("solarDataInclinedAxisDescription");

  String solarDataVerticalAxisGerman = getTextContentGerman("solarDataVerticalAxis");
  String solarDataVerticalAxisEnglish = getTextContentEnglish("solarDataVerticalAxis");

  String solarDataVerticalAxisDescriptionGerman = getTextContentGerman("solarDataVerticalAxisDescription");
  String solarDataVerticalAxisDescriptionEnglish = getTextContentEnglish("solarDataVerticalAxisDescription");

  String solarDataTwoAxisGerman = getTextContentGerman("solarDataTwoAxis");
  String solarDataTwoAxisEnglish = getTextContentEnglish("solarDataTwoAxis");

  String solarDataTwoAxisDescriptionGerman = getTextContentGerman("solarDataTwoAxisDescription");
  String solarDataTwoAxisDescriptionEnglish = getTextContentEnglish("solarDataTwoAxisDescription");

  String solarDataPvTechChoiceGerman = getTextContentGerman("solarDataPvTechChoice");
  String solarDataPvTechChoiceEnglish = getTextContentEnglish("solarDataPvTechChoice");

  String solarDataPvTechDescriptionGerman = getTextContentGerman("solarDataPvTechDescription");
  String solarDataPvTechDescriptionEnglish = getTextContentEnglish("solarDataPvTechDescription");

  String solarDataPeakPowerKwGerman = getTextContentGerman("solarDataPeakPowerKw");
  String solarDataPeakPowerKwEnglish = getTextContentEnglish("solarDataPeakPowerKw");

  String solarDataPeakPowerKwDescriptionGerman = getTextContentGerman("solarDataPeakPowerKwDescription");
  String solarDataPeakPowerKwDescriptionEnglish = getTextContentEnglish("solarDataPeakPowerKwDescription");

  String solarDataLossPercentageGerman = getTextContentGerman("solarDataLossPercentage");
  String solarDataLossPercentageEnglish = getTextContentEnglish("solarDataLossPercentage");

  String solarDataLossPercentageDescriptionGerman = getTextContentGerman("solarDataLossPercentageDescription");
  String solarDataLossPercentageDescriptionEnglish = getTextContentEnglish("solarDataLossPercentageDescription");

  String solarDataAngleGerman = getTextContentGerman("solarDataAngle");
  String solarDataAngleEnglish = getTextContentEnglish("solarDataAngle");

  String solarDataAngleDescriptionGerman = getTextContentGerman("solarDataAngleDescription");
  String solarDataAngleDescriptionEnglish = getTextContentEnglish("solarDataAngleDescription");

  String solarDataAspectGerman = getTextContentGerman("solarDataAspect");
  String solarDataAspectEnglish = getTextContentEnglish("solarDataAspect");

  String solarDataAspectDescriptionGerman = getTextContentGerman("solarDataAspectDescription");
  String solarDataAspectDescriptionEnglish = getTextContentEnglish("solarDataAspectDescription");

  String solarDataLifetimeYearsGerman = getTextContentGerman("solarDataLifetimeYears");
  String solarDataLifetimeYearsEnglish = getTextContentEnglish("solarDataLifetimeYears");

  String solarDataLifetimeYearsDescriptionGerman = getTextContentGerman("solarDataLifetimeYearsDescription");
  String solarDataLifetimeYearsDescriptionEnglish = getTextContentEnglish("solarDataLifetimeYearsDescription");

  String solarDataUseHorizonGerman = getTextContentGerman("solarDataUseHorizon");
  String solarDataUseHorizonEnglish = getTextContentEnglish("solarDataUseHorizon");

  String solarDataUseHorizonDescriptionGerman = getTextContentGerman("solarDataUseHorizonDescription");
  String solarDataUseHorizonDescriptionEnglish = getTextContentEnglish("solarDataUseHorizonDescription");

  String solarDataOptimalInclinationGerman = getTextContentGerman("solarDataOptimalInclination");
  String solarDataOptimalInclinationEnglish = getTextContentEnglish("solarDataOptimalInclination");

  String solarDataOptimalInclinationDescriptionGerman = getTextContentGerman("solarDataOptimalInclinationDescription");
  String solarDataOptimalInclinationDescriptionEnglish = getTextContentEnglish("solarDataOptimalInclinationDescription");

  String solarDataOptimalAnglesGerman = getTextContentGerman("solarDataOptimalAngles");
  String solarDataOptimalAnglesEnglish = getTextContentEnglish("solarDataOptimalAngles");

  String solarDataOptimalAnglesDescriptionGerman = getTextContentGerman("solarDataOptimalAnglesDescription");
  String solarDataOptimalAnglesDescriptionEnglish = getTextContentEnglish("solarDataOptimalAnglesDescription");

  String solarDataInclinedOptimumGerman = getTextContentGerman("solarDataInclinedOptimum");
  String solarDataInclinedOptimumEnglish = getTextContentEnglish("solarDataInclinedOptimum");

  String solarDataInclinedOptimumDescriptionGerman = getTextContentGerman("solarDataInclinedOptimumDescription");
  String solarDataInclinedOptimumDescriptionEnglish = getTextContentEnglish("solarDataInclinedOptimumDescription");

  String solarDataInclinedAxisAngleGerman = getTextContentGerman("solarDataInclinedAxisAngle");
  String solarDataInclinedAxisAngleEnglish = getTextContentEnglish("solarDataInclinedAxisAngle");

  String solarDataInclinedAxisAngleDescriptionGerman = getTextContentGerman("solarDataInclinedAxisAngleDescription");
  String solarDataInclinedAxisAngleDescriptionEnglish = getTextContentEnglish("solarDataInclinedAxisAngleDescription");

  String solarDataVerticalOptimumGerman = getTextContentGerman("solarDataVerticalOptimum");
  String solarDataVerticalOptimumEnglish = getTextContentEnglish("solarDataVerticalOptimum");

  String solarDataVerticalOptimumDescriptionGerman = getTextContentGerman("solarDataVerticalOptimumDescription");
  String solarDataVerticalOptimumDescriptionEnglish = getTextContentEnglish("solarDataVerticalOptimumDescription");

  String solarDataVerticalAxisAngleGerman = getTextContentGerman("solarDataVerticalAxisAngle");
  String solarDataVerticalAxisAngleEnglish = getTextContentEnglish("solarDataVerticalAxisAngle");

  String solarDataVerticalAxisAngleDescriptionGerman = getTextContentGerman("solarDataVerticalAxisAngleDescription");
  String solarDataVerticalAxisAngleDescriptionEnglish = getTextContentEnglish("solarDataVerticalAxisAngleDescription");

  String solarDataBatterySizeGerman = getTextContentGerman("solarDataBatterySize");
  String solarDataBatterySizeEnglish = getTextContentEnglish("solarDataBatterySize");

  String solarDataBatterySizeDescriptionGerman = getTextContentGerman("solarDataBatterySizeDescription");
  String solarDataBatterySizeDescriptionEnglish = getTextContentEnglish("solarDataBatterySizeDescription");

  String solarDataBatteryCutoffGerman = getTextContentGerman("solarDataBatteryCutoff");
  String solarDataBatteryCutoffEnglish = getTextContentEnglish("solarDataBatteryCutoff");

  String solarDataBatteryCutoffDescriptionGerman = getTextContentGerman("solarDataBatteryCutoffDescription");
  String solarDataBatteryCutoffDescriptionEnglish = getTextContentEnglish("solarDataBatteryCutoffDescription");

  String solarDataRadiationDatabaseGerman = getTextContentGerman("solarDataRadiationDatabase");
  String solarDataRadiationDatabaseEnglish = getTextContentEnglish("solarDataRadiationDatabase");

  String solarDataRadiationDatabaseDescriptionGerman = getTextContentGerman("solarDataRadiationDatabaseDescription");
  String solarDataRadiationDatabaseDescriptionEnglish = getTextContentEnglish("solarDataRadiationDatabaseDescription");

  String solarDataConsumptionPerDayGerman = getTextContentGerman("solarDataConsumptionPerDay");
  String solarDataConsumptionPerDayEnglish = getTextContentEnglish("solarDataConsumptionPerDay");

  String solarDataConsumptionPerDayDescriptionGerman = getTextContentGerman("solarDataConsumptionPerDayDescription");
  String solarDataConsumptionPerDayDescriptionEnglish = getTextContentEnglish("solarDataConsumptionPerDayDescription");



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
        title: Text(_selectedLanguage == 'German' ? solarDataTitleGerman : solarDataTitleEnglish,  style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0, color: Colors.black)),
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
    String maxBudget = _selectedLanguage == 'German' ? solarDataMaxBudgetGerman : solarDataMaxBudgetEnglish;
    String technology = _selectedLanguage == 'German' ? solarDataTechnologyGerman : solarDataTechnologyEnglish;
    String peakPower = _selectedLanguage == 'German' ? solarDataPeakPowerGerman : solarDataPeakPowerEnglish;
    String systemLoss = _selectedLanguage == 'German' ? solarDataSystemLossGerman : solarDataSystemLossEnglish;
    String database = _selectedLanguage == 'German' ? solarDataDatabaseGerman : solarDataDatabaseEnglish;
    String maxLifetime = _selectedLanguage == 'German' ? solarDataMaxLifetimeGerman : solarDataMaxLifetimeEnglish;
    String elevation = _selectedLanguage == 'German' ? solarDataElevationGerman : solarDataElevationEnglish;

    String type = _selectedLanguage == 'German' ? solarDataTypeGerman : solarDataTypeEnglish;
    String slope = _selectedLanguage == 'German' ? solarDataSlopeGerman : solarDataSlopeEnglish;
    String slopeIsOptimal = _selectedLanguage == 'German' ? solarDataSlopeOptimalGerman : solarDataSlopeOptimalEnglish;
    String orientationAngle = _selectedLanguage == 'German' ? solarDataOrientationAngleGerman : solarDataOrientationAngleEnglish;
    String orientationAngleIsOptimal = _selectedLanguage == 'German' ? solarDataOrientationAngleOptimalGerman : solarDataOrientationAngleEnglish;

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text(_selectedLanguage == 'German' ? solarDataForecastGerman : solarDataForecastEnglish, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.Text(_selectedLanguage == 'German' ? solarDataOverviewGerman : solarDataOverviewEnglish, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('$maxBudget ${solarData['Maximum Budget (Euros)']} Euros'
                '\n$maxLifetime ${solarData['Maximum Lifetime (Years)']} Years'
                '\n$technology ${solarData['Technology']}'
                '\n$peakPower ${solarData['Peak Power (kW)']} kW'
                '\n$systemLoss ${solarData['System Loss (%)']} %'
                '\n$database ${solarData['Radiation Database']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text(_selectedLanguage == 'German' ? solarDataLocationDataGerman : solarDataLocationDataEnglish, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('Latitude: ${solarData['Location Data']['Latitude']},'
                '\nLongitude: ${solarData['Location Data']['Longitude']},'
                '\n$elevation ${solarData['Location Data']['Elevation']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text(_selectedLanguage == 'German' ? solarDataMountingSystemGerman : solarDataMountingSystemEnglish, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (solarData['Mounting System'].containsKey('Type'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('$type ${solarData['Mounting System']['Type']}'
                  '\n$slope ${solarData['Mounting System']['Slope (°)']} °'
                  '\n$slopeIsOptimal ${solarData['Mounting System']['Slope is Optimal']}'
                  '\n$orientationAngle ${solarData['Mounting System']['Orientation Angle (°)']} °'
                  '\n$orientationAngleIsOptimal ${solarData['Mounting System']['Orientation Angle is Optimal']}'),
            ),
          if (solarData['Mounting System'].containsKey('Inclined Axis'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('$slope ${solarData['Mounting System']['Inclined Axis']['Slope (°)']} °'
                  '\n$slopeIsOptimal ${solarData['Mounting System']['Inclined Axis']['Slope is Optimal']}'
                  '\n$orientationAngle ${solarData['Mounting System']['Inclined Axis']['Orientation Angle (°)']} °'
                  '\n$orientationAngleIsOptimal ${solarData['Mounting System']['Inclined Axis']['Orientation Angle is Optimal']}'),
            ),
          if (solarData['Mounting System'].containsKey('Vertical Axis'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('$slope ${solarData['Mounting System']['Vertical Axis']['Slope (°)']} °'
                  '\n$slopeIsOptimal ${solarData['Mounting System']['Vertical Axis']['Slope is Optimal']}'
                  '\n$orientationAngle ${solarData['Mounting System']['Vertical Axis']['Orientation Angle (°)']} °'
                  '\n$orientationAngleIsOptimal ${solarData['Mounting System']['Vertical Axis']['Orientation Angle is Optimal']}'),
            ),
          if (solarData['Mounting System'].containsKey('Two Axis'))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Text('$slope ${solarData['Mounting System']['Two Axis']['Slope (°)']} °'
                  '\n$slopeIsOptimal ${solarData['Mounting System']['Two Axis']['Slope is Optimal']}'
                  '\n$orientationAngle ${solarData['Mounting System']['Two Axis']['Orientation Angle (°)']} °'
                  '\n$orientationAngleIsOptimal ${solarData['Mounting System']['Two Axis']['Orientation Angle is Optimal']}'),
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
        await widget.docOperations.uploadDocuments(documentId, file, null, null, context);
        if (mounted) {
          setState(() {
            isUploading = false; // This should be false after uploading
          });
        }
      }
    } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
    }
  }

  Future<void> generateAndPreviewPdfOffGrid(Map<String, dynamic> solarData, ScaffoldMessengerState context) async {
    final pdf = pw.Document();
    String maxBudget = _selectedLanguage == 'German' ? solarDataMaxBudgetGerman : solarDataMaxBudgetEnglish;
    String batteryCapacity = _selectedLanguage == 'German' ? solarDataBatteryCapacityGerman : solarDataBatteryCapacityEnglish;
    String peakPower = _selectedLanguage == 'German' ? solarDataPeakPowerGerman : solarDataPeakPowerEnglish;
    String batteryCutoffLimit = _selectedLanguage == 'German' ? solarDataBatteryCutoffGerman : solarDataBatteryCutoffEnglish;
    String database = _selectedLanguage == 'German' ? solarDataDatabaseGerman : solarDataDatabaseEnglish;
    String dailyEnergyConsumption = _selectedLanguage == 'German' ? solarDataDailyEnergyConsumptionGerman : solarDataDailyEnergyConsumptionEnglish;
    String elevation = _selectedLanguage == 'German' ? solarDataElevationGerman : solarDataElevationEnglish;

    String slope = _selectedLanguage == 'German' ? solarDataSlopeGerman : solarDataSlopeEnglish;
    String slopeIsOptimal = _selectedLanguage == 'German' ? solarDataSlopeOptimalGerman : solarDataSlopeOptimalEnglish;
    String orientationAngle = _selectedLanguage == 'German' ? solarDataOrientationAngleGerman : solarDataOrientationAngleEnglish;
    String orientationAngleIsOptimal = _selectedLanguage == 'German' ? solarDataOrientationAngleOptimalGerman : solarDataOrientationAngleEnglish;


    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text(_selectedLanguage == 'German' ? solarDataForecastGerman : solarDataForecastEnglish, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.Text(_selectedLanguage == 'German' ? solarDataOverviewGerman : solarDataOverviewEnglish, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('$maxBudget ${solarData['Maximum Budget (Euros)']} Euros'
                '\n$peakPower ${solarData['Peak Power (kW)']} kW'
                '\n$batteryCapacity ${solarData['Battery Capacity (Wh)']} Wh'
                '\n$batteryCutoffLimit ${solarData['Battery Discharge Cutoff Limit (%)']} %'
                '\n$dailyEnergyConsumption ${solarData['Daily Energy Consumption (Wh)']} Wh'
                '\n$database ${solarData['Radiation Database']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text(_selectedLanguage == 'German' ? solarDataLocationDataGerman : solarDataLocationDataEnglish, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('Latitude: ${solarData['Location Data']['Latitude']},'
                '\nLongitude: ${solarData['Location Data']['Longitude']},'
                '\n$elevation ${solarData['Location Data']['Elevation']}'),
          ),
          pw.SizedBox(height: 20),
          pw.Text(_selectedLanguage == 'German' ? solarDataMountingSystemGerman : solarDataLocationDataEnglish, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 10),
            child: pw.Text('$slope ${solarData['Mounting System']['Slope (°)']} °'
                '\n$slopeIsOptimal ${solarData['Mounting System']['Slope is Optimal']}'
                '\n$orientationAngle ${solarData['Mounting System']['Orientation Angle (°)']} °'
                '\n$orientationAngleIsOptimal ${solarData['Mounting System']['Orientation Angle is Optimal']}'),
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
        await widget.docOperations.uploadDocuments(documentId, file, null, null, context);

        if (mounted) {
          setState(() {
            isUploading = false; // This should be false after uploading
          });
        }
      }
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  pw.Widget _buildMonthlyDataTable(Map<String, dynamic> solarData) {
    String month = _selectedLanguage == 'German' ? solarDataMonthGerman : solarDataMonthEnglish;
    String dailyEnergy = _selectedLanguage == 'German' ? solarDataDailyEnergyGerman : solarDataDailyEnergyEnglish;
    String monthlyEnergy = _selectedLanguage == 'German' ? solarDataMonthlyEnergyGerman : solarDataMonthlyEnergyEnglish;
    String dailyIrradiance = _selectedLanguage == 'German' ? solarDataDailyIrradianceGerman : solarDataDailyIrradianceEnglish;
    String monthlyIrradiance = _selectedLanguage == 'German' ? solarDataMonthlyIrradianceGerman : solarDataMonthlyIrradianceEnglish;
    String sunshineDuration = _selectedLanguage == 'German' ? solarDataSunshineDurationGerman : solarDataSunshineDurationEnglish;

    return pw.TableHelper.fromTextArray(
      headers: [month, dailyEnergy, monthlyEnergy, dailyIrradiance, monthlyIrradiance, sunshineDuration],
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
    String month = _selectedLanguage == 'German' ? solarDataMonthGerman : solarDataMonthEnglish;
    String dailyEnergy = _selectedLanguage == 'German' ? solarDataDailyEnergyGerman : solarDataDailyEnergyEnglish;
    String energyLostPerDay = _selectedLanguage == 'German' ? solarDataEnergyLostPerDayGerman : solarDataEnergyLostPerDayEnglish;
    String fillFactor = _selectedLanguage == 'German' ? solarDataFillFactorGerman : solarDataFillFactorEnglish;
    String factorOfEfficiency = _selectedLanguage == 'German' ? solarDataFactorOfEfficiencyGerman : solarDataFactorOfEfficiencyEnglish;

    return pw.TableHelper.fromTextArray(
      headers: [month, dailyEnergy, energyLostPerDay, fillFactor, factorOfEfficiency],
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
    String errorMessagePermissionLocationError = _selectedLanguage == 'German' ? solarDataLocationDataPermissionErrorGerman : solarDataLocationDataPermissionErrorEnglish;
    String errorMessagePermanentLocationError = _selectedLanguage == 'German' ? solarDataPermanentLocationDataPermissionErrorGerman : solarDataPermanentLocationDataPermissionErrorEnglish;
    String errorMessageFetchingLocationError = _selectedLanguage == 'German' ? solarDataErrorFetchingLocationGerman : solarDataErrorFetchingLocationEnglish;
    final scaffoldContext = ScaffoldMessenger.of(context);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle permission denied scenario
        helper.showSnackBar(errorMessagePermissionLocationError, "Error", scaffoldContext);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      helper.showSnackBar(errorMessagePermanentLocationError, "Error", scaffoldContext);
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
      helper.showSnackBar('$errorMessageFetchingLocationError $e', "Error", scaffoldContext);
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
        _selectedLanguage == 'German' ? solarDataMaxBudgetEurosGerman : solarDataMaxBudgetEurosEnglish,
        '0',
            (String newValue) {
          setState(() {
            maxBudget = newValue;
          });
        },
        null,
        _selectedLanguage == 'German' ? solarDataMaxBudgetDescriptionGerman : solarDataMaxBudgetDescriptionEnglish,
      ),
      const SizedBox(height: 20),
      buildItemFormFieldWithCard(
        _selectedLanguage == 'German' ? solarDataMountingPlaceGerman : solarDataMountingPlaceEnglish,
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
        _selectedLanguage == 'German' ? solarDataTypeDescriptionGerman : solarDataTypeDescriptionEnglish,
      ),
      const SizedBox(height: 20),
      Column(
        children: [
          buildSwitchWithCard(
            _selectedLanguage == 'German' ? solarDataFixedGerman : solarDataFixedEnglish,
            fixed,
                (bool newValue) {
              setState(() {
                fixed = newValue;
                queryParams['fixed'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            _selectedLanguage == 'German' ? solarDataFixedDescriptionGerman : solarDataFixedDescriptionEnglish,
          ),
          const SizedBox(height: 10),
          buildSwitchWithCard(
            _selectedLanguage == 'German' ? solarDataInclinedAxisGerman : solarDataInclinedAxisEnglish,
            inclined_axis,
                (bool newValue) {
              setState(() {
                inclined_axis = newValue;
                queryParams['inclined_axis'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            _selectedLanguage == 'German' ? solarDataInclinedAxisDescriptionGerman : solarDataInclinedAxisDescriptionEnglish,
          ),
          const SizedBox(height: 10),
          buildSwitchWithCard(
            _selectedLanguage == 'German' ? solarDataVerticalAxisGerman : solarDataVerticalAxisEnglish,
            vertical_axis,
                (bool newValue) {
              setState(() {
                vertical_axis = newValue;
                queryParams['vertical_axis'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            _selectedLanguage == 'German' ? solarDataVerticalAxisDescriptionGerman : solarDataVerticalAxisDescriptionEnglish,
          ),
          const SizedBox(height: 10),
          buildSwitchWithCard(
            _selectedLanguage == 'German' ? solarDataTwoAxisGerman : solarDataTwoAxisEnglish,
            twoaxis,
                (bool newValue) {
              setState(() {
                twoaxis = newValue;
                queryParams['twoaxis'] = newValue ? '1' : '0';
                calcButtonEnabled = isAtLeastOneSwitchEnabled();
              });
            },
            _selectedLanguage == 'German' ? solarDataTwoAxisDescriptionGerman : solarDataTwoAxisDescriptionEnglish,
          ),
        ],
      ),
      const SizedBox(height: 10),
      buildItemFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataPvTechChoiceGerman : solarDataPvTechChoiceEnglish,
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
          _selectedLanguage == 'German' ? solarDataPvTechDescriptionGerman : solarDataPvTechDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataPeakPowerKwGerman : solarDataPeakPowerKwEnglish,
          '5',
              (String newValue) {
            setState(() {
              queryParams['peakpower'] = newValue;
              peakPower = newValue;
            });
          },
          null,
          _selectedLanguage == 'German' ? solarDataPeakPowerKwDescriptionGerman : solarDataPeakPowerKwDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataLossPercentageGerman : solarDataLossPercentageEnglish,
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
          _selectedLanguage == 'German' ? solarDataLossPercentageDescriptionGerman : solarDataLossPercentageDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildItemFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataRadiationDatabaseGerman : solarDataRadiationDatabaseEnglish,
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
        _selectedLanguage == 'German' ? solarDataRadiationDatabaseDescriptionGerman : solarDataRadiationDatabaseDescriptionEnglish
      ),
      const SizedBox(height: 20),
      if (fixed || twoaxis) ...[
        buildTextFormFieldWithCard(
            _selectedLanguage == 'German' ? solarDataAngleGerman : solarDataAngleEnglish,
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
            _selectedLanguage == 'German' ? solarDataAngleDescriptionGerman : solarDataAngleDescriptionEnglish
        ),
        const SizedBox(height: 20),
        buildTextFormFieldWithCard(
            _selectedLanguage == 'German' ? solarDataAspectGerman : solarDataAspectEnglish,
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
            _selectedLanguage == 'German' ? solarDataAspectDescriptionGerman : solarDataAspectDescriptionEnglish
        ),
        const SizedBox(height: 20),
      ],
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataLifetimeYearsGerman : solarDataLifetimeYearsEnglish,
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
          _selectedLanguage == 'German' ? solarDataLifetimeYearsDescriptionGerman : solarDataLifetimeYearsDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildSwitchWithCard(
        _selectedLanguage == 'German' ? solarDataUseHorizonGerman : solarDataUseHorizonEnglish,
        useHorizon,
            (bool newValue) {
          setState(() {
            useHorizon = newValue;
            queryParams['usehorizon'] = newValue ? '1' : '0';
          });
        },
        _selectedLanguage == 'German' ? solarDataUseHorizonDescriptionGerman : solarDataUseHorizonDescriptionEnglish,
      ),
      const SizedBox(height: 20),
      if (fixed || twoaxis) ...[
        buildSwitchWithCard(
          _selectedLanguage == 'German' ? solarDataOptimalInclinationGerman : solarDataOptimalInclinationEnglish,
          optimalinclination,
              (bool newValue) {
            setState(() {
              optimalinclination = newValue;
              queryParams['optimalinclination'] = newValue ? '1' : '0';
            });
          },
          _selectedLanguage == 'German' ? solarDataOptimalInclinationDescriptionGerman : solarDataOptimalInclinationDescriptionEnglish,
        ),
        const SizedBox(height: 20),
        buildSwitchWithCard(
            _selectedLanguage == 'German' ? solarDataOptimalAnglesGerman : solarDataOptimalAnglesEnglish,
            optimalangles,
                (bool newValue) {
              setState(() {
                optimalangles = newValue;
                queryParams['optimalangles'] = newValue ? '1' : '0';
              });
            },
            _selectedLanguage == 'German' ? solarDataOptimalAnglesDescriptionGerman : solarDataOptimalAnglesDescriptionEnglish
        ),
        const SizedBox(height: 20),
      ],
      if (inclined_axis) ...[
        buildSwitchWithCard(
            _selectedLanguage == 'German' ? solarDataInclinedOptimumGerman : solarDataInclinedOptimumEnglish,
            inclined_optimum,
                (bool newValue) {
              setState(() {
                inclined_optimum = newValue;
                queryParams['inclined_optimum'] = newValue ? '1' : '0';
              });
            },
            _selectedLanguage == 'German' ? solarDataInclinedOptimumDescriptionGerman : solarDataInclinedOptimumDescriptionEnglish
        ),
        const SizedBox(height: 20),
        buildTextFormFieldWithCard(
            _selectedLanguage == 'German' ? solarDataInclinedAxisAngleGerman : solarDataInclinedAxisAngleEnglish,
            '0',
                (String newValue) {
              setState(() {
                queryParams['inclinedaxisangle'] = newValue;
              });
            },
            null,
            _selectedLanguage == 'German' ? solarDataInclinedAxisAngleDescriptionGerman : solarDataInclinedAxisAngleDescriptionEnglish
        ),
        const SizedBox(height: 20),
      ],
      if (vertical_axis) ...[
        buildSwitchWithCard(
            _selectedLanguage == 'German' ? solarDataVerticalOptimumGerman : solarDataVerticalOptimumEnglish,
            vertical_optimum,
                (bool newValue) {
              setState(() {
                vertical_optimum = newValue;
                queryParams['vertical_optimum'] = newValue ? '1' : '0';
              });
            },
            _selectedLanguage == 'German' ? solarDataVerticalOptimumDescriptionGerman : solarDataVerticalOptimumDescriptionEnglish
        ),
        const SizedBox(height: 20),
        buildTextFormFieldWithCard(
            _selectedLanguage == 'German' ? solarDataVerticalAxisAngleGerman : solarDataVerticalAxisAngleEnglish,
            '0',
                (String newValue) {
              setState(() {
                queryParams['verticalaxisangle'] = newValue;
              });
            },
            null,
            _selectedLanguage == 'German' ? solarDataVerticalAxisAngleDescriptionGerman : solarDataVerticalAxisAngleDescriptionEnglish
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
        _selectedLanguage == 'German' ? solarDataMaxBudgetEurosGerman : solarDataMaxBudgetEurosEnglish,
        '0',
            (String newValue) {
          setState(() {
            maxBudget = newValue;
          });
        },
        null,
        _selectedLanguage == 'German' ? solarDataMaxBudgetDescriptionGerman : solarDataMaxBudgetDescriptionEnglish,
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataPeakPowerKwGerman : solarDataPeakPowerKwEnglish,
          '5',
              (String newValue) {
            setState(() {
              queryParamsOffGrid['peakpower'] = newValue;
              peakPower = newValue;
            });
          },
          null,
          _selectedLanguage == 'German' ? solarDataPeakPowerKwDescriptionGerman : solarDataPeakPowerKwDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataBatterySizeGerman : solarDataBatterySizeEnglish,
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
          _selectedLanguage == 'German' ? solarDataBatterySizeDescriptionGerman : solarDataBatterySizeDescriptionEnglish
      ),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataBatteryCutoffGerman : solarDataBatteryCutoffEnglish,
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
          _selectedLanguage == 'German' ? solarDataBatteryCutoffDescriptionGerman : solarDataBatteryCutoffDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildItemFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataRadiationDatabaseGerman : solarDataRadiationDatabaseEnglish,
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
          _selectedLanguage == 'German' ? solarDataRadiationDatabaseDescriptionGerman : solarDataRadiationDatabaseDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataAngleGerman : solarDataAngleEnglish,
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
          _selectedLanguage == 'German' ? solarDataAngleDescriptionGerman : solarDataAngleDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataAspectGerman : solarDataAspectEnglish,
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
          _selectedLanguage == 'German' ? solarDataAspectDescriptionGerman : solarDataAspectDescriptionEnglish
      ),
      const SizedBox(height: 20),
      buildSwitchWithCard(
        _selectedLanguage == 'German' ? solarDataUseHorizonGerman : solarDataUseHorizonEnglish,
        useHorizon,
            (bool newValue) {
          setState(() {
            useHorizon = newValue;
            queryParamsOffGrid['usehorizon'] = newValue ? '1' : '0';
          });
        },
        _selectedLanguage == 'German' ? solarDataUseHorizonDescriptionGerman : solarDataUseHorizonDescriptionEnglish,
      ),
      const SizedBox(height: 20),
      buildTextFormFieldWithCard(
          _selectedLanguage == 'German' ? solarDataConsumptionPerDayGerman: solarDataConsumptionPerDayEnglish,
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
          _selectedLanguage == 'German' ? solarDataConsumptionPerDayDescriptionGerman: solarDataConsumptionPerDayDescriptionEnglish
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
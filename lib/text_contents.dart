
String getTextContentGerman(String textContentType) {

  Map<String, String> textContents = {
    // Login
    "welcomeText": "Willkommen ",
    "continueText": "Weiter",
    "biometricsText": "Biometrische Daten aktivieren",
    "forgotPasswordText": "Passw. vergessen?",
    "notRegisteredText": "Nicht registriert?",
    "resetPasswordText": "Passwort zurücksetzen",
    "resetPasswordHintText": "Geben Sie Ihre Email ein",
    "resetPasswordNotificationText": "Eine Benachrichtigung wurde an Ihr E-Mail-Konto gesendet.",
    "handleLoginError1": "Bitte geben Sie sowohl Ihre E-Mail-Adresse als auch Ihr Passwort ein",
    "handleLoginError2": " ist nicht verifiziert. Bitte verifizieren Sie zuerst Ihre Identität!",
    "handleLoginError3": " ist deaktiviert. Bitte kontaktieren Sie das Support-Team!",
    "handleLoginErrorGeneral": "Ein Fehler ist während des Anmeldevorgangs aufgetreten.",

    // Biometric Setup
    "biometricSetupError1": "Die Hardware unterstützt keine Biometrische Authentifizierung!",
    "biometricSetupErrorGeneral": "Biometrische Authentifizierung fehlgeschlagen!",
    "biometricSetupSuccess": "Biometrische Authentifizierung erfolgreich!",
    "localizedReason": "Scannen Sie Ihren Finger zur Authentifizierung",
    "biometricAuthMethod": "Authentifizieren Sie sich mit Ihrem Fingerabdruck anstelle Ihres Passworts",
    "biometricAuth": "Authentifizierung",

    // Chat Window
    "chatWindowError1": "Es konnten keine administrativen Benutzer gefunden werden!",
    "chatWindowTextAdmin": "Kunden-Chat-Anfragen",
    "chatWindowTextClient": "Chatten Sie mit uns",
    "chatWindowRequestHintText": "Geben Sie Ihre Nachricht hier ein...",
    "chatWindowReplyHintText": "Geben Sie Ihre Antwort hier ein...",
    "chatWindowDeleteMessageError": "Fehler beim Löschen der Nachricht: ",
    "chatWindowReplyText": "Antwort Nachricht",
    "chatWindowYourText": "Ihre Nachricht",
    "chatWindowSendReplyText": "Sende Antwort",
    "chatWindowFromText": "Von",

    // Dashboard Section
    "dashboardTitle1": "Dokumentenbibliothek",
    "dashboardDescription1": "Nahtloser Zugang",
    "dashboardDetailedDescription1": "Greifen Sie mühelos auf unsere umfassende Dokumentenbibliothek zu, laden Sie Dokumente herunter und navigieren Sie nahtlos durch sie. "
    "Damit können Sie Ihre wichtigen Dateien einfach und effizient verwalten.",
    "dashboardDetailedDescriptionAdmin1": "Greifen Sie mühelos auf unsere umfassende Dokumentenbibliothek zu, laden Sie Dokumente herunter und navigieren Sie nahtlos durch sie. "
    "Damit können Sie Ihre wichtigen Dateien einfach und effizient verwalten.",
    "dashboardButtonText1": "Jetzt auf Dokumente zugreifen",
    "dashboardTitle2": "Dokumentenupload",
    "dashboardDescription2": "Einfaches Hochladen",
    "dashboardDetailedDescription2": "Stärken Sie Ihre Planung für Solarmodule, indem Sie mühelos Ihre eigenen Dokumente in unsere Cloud hochladen. "
    "Damit legen Sie den Grundstein für eine maßgeschneiderte Solarmodulplanung, die auf Ihre spezifischen Bedürfnisse zugeschnitten ist.",
    "dashboardDetailedDescriptionAdmin2": "Stärken Sie die Planung für Solarmodule für Ihre Kunden, indem Sie Pläne und Angebote mühelos in unsere Cloud hochladen. "
    "Damit legen Sie den Grundstein für eine maßgeschneiderte Solarmodulplanung, die auf die spezifischen Bedürfnisse Ihrer Kunden zugeschnitten ist.",
    "dashboardButtonText2": "Jetzt Dokumente hochladen",
    "dashboardTitle3": "Solar Insights",
    "dashboardDescription3": "Leistungsprognose erhalten",
    "dashboardDetailedDescription3": "Erkunden Sie maßgeschneiderte Prognosen für die Leistung von Solarmodulen in verschiedenen Umgebungen, Konfigurationen und Bedingungen. "
    "Erhalten Sie detaillierte Einblicke, die informierte Entscheidungen über Solarinstallationen ermöglichen, indem Sie Effizienz, Energieerzeugung und andere wichtige Faktoren vorhersagen, die für die Optimierung von Solarprojekten entscheidend sind. "
    "Senden Sie uns Ihre Spezifikationen für personalisierte Prognosen!",
    "dashboardDetailedDescriptionAdmin3": "Erkunden Sie maßgeschneiderte Prognosen für die Leistung von Solarmodulen in verschiedenen Umgebungen, Konfigurationen und Bedingungen. "
    "Erhalten Sie detaillierte Einblicke, die informierte Entscheidungen über Solarinstallationen ermöglichen, indem Sie Effizienz, Energieerzeugung und andere wichtige Faktoren vorhersagen, die für die Optimierung von Solarprojekten entscheidend sind. "
    "Senden Sie uns Ihre Spezifikationen für personalisierte Prognosen!",
    "dashboardButtonText3": "Jetzt Prognosen erhalten",

    // Document
    "documentErrorLoading": "Fehler beim Laden des Dokuments",
    "documentErrorShow": "Das Dokument kann nicht angezeigt werden",
    "documentErrorFormat": "Nicht unterstütztes Dokumentenformat",

    // Document Library
    "documentLibraryDownloadError": "Konnte das Download-Verzeichnis nicht erreichen",
    "documentLibraryLoadingDataError": "Fehler beim Laden von Daten",
    "documentLibraryLoadingDocumentError": "Fehler beim Laden von Dokumenten",
    "documentLibraryDownloadNotification": "Download abgeschlossen",
    "documentLibraryDownloadSuccess": " erfolgreich heruntergeladen",
    "documentLibraryDeleteSuccess": " erfolgreich gelöscht",
    "documentLibraryNoUserData": "Keine Benutzerdaten verfügbar",
    "documentLibraryUserNotExists": "Der Benutzer existiert nicht.",
    "documentLibraryUserRoleNotExists": "Benutzerrolle nicht definiert",
    "documentLibraryUserDomainNotExists": "Benutzerdomäne nicht definiert",
    "documentLibraryNoDocs": "Keine Dokumente verfügbar.",
    "documentLibraryDomain": "Domäne",
    "documentLibraryYear": "Jahr",
    "documentLibraryCategory": "Kategorie",
    "documentLibraryPrefixFrom": "Von",
    "documentLibraryPrefixFor": "Für",
    "documentLibraryCategoryCustomerAdmin": "Kundendokumente",
    "documentLibraryCategoryCustomerClient": "Meine Dokumente",

    // Helpers
    "helperUserNotSignedIn": "Benutzer ist nicht angemeldet!",

    // Document Operations
    "docOperationsNoDocs": "Keine Dokumente zum Hochladen verfügbar",
    "docOperationsUploadSuccess": " erfolgreich hochgeladen",

    // Main
    "mainGooglePlayNotAvailable": "Google Play-Dienste nicht verfügbar",
    "mainGooglePlayInstallMessage": "Bitte installieren oder aktualisieren Sie Google Play-Dienste.",
    "mainNotification": "Neue Benachrichtigung",
    "mainNewDocument": "Sie haben ein neues Dokument!",

    // Registration
    "registrationEmptyField": "Bitte füllen Sie Benutzername, E-Mail und Passwort aus",
    "registrationInvalidEmail": "Bitte geben Sie eine gültige E-Mail-Adresse ein",
    "registrationInvalidPasswordLength": "Das Passwort muss mindestens 8 Zeichen lang sein",
    "registrationInvalidPasswordCharacters": "Das Passwort muss mindestens ein Sonderzeichen enthalten",
    "registrationUsername": "Benutzername",
    "registrationPassword": "Passwort",
    "registrationDomain": "Wählen Sie Ihre Domain basierend auf Ihrem Standort:",
    "registrationExample": "Beispiele",
    "registrationRegister": "Registrieren",
    "registrationSuccess": "Benutzer erfolgreich registriert!",
    "registrationNextSteps": "Die nächsten Schritte sind:\n- Schließen Sie diese App oder kehren Sie zum Anmeldebildschirm zurück\n- Überprüfen Sie Ihre E-Mail-Adresse mit dem Verifizierungslink, den Sie per E-Mail erhalten haben\n- Melden Sie sich mit Ihrer E-Mail-Adresse und Ihrem Passwort an",

    // User Details
    "userDetailsTitle": "Kunden und Administratoren",
    "userDetailsNoUserData": "Keine Benutzerdaten verfügbar",

    // Solar AI
    "solarDataTitle": "Sonnenenergiedaten",
    "solarDataForecast": "Prognose der Sonnenenergiedaten",
    "solarDataOverview": "Übersicht",
    "solarDataMaxBudget": "Maximalbudget:",
    "solarDataMaxLifetime": "Maximale Lebensdauer:",
    "solarDataTechnology": "Technologie:",
    "solarDataPeakPower": "Spitzenleistung:",
    "solarDataSystemLoss": "Systemverluste:",
    "solarDataDatabase": "Datenbank:",
    "solarDataLocationData": "Standortdaten",
    "solarDataElevation": "Höhe:",
    "solarDataMountingSystem": "Montagesystem",
    "solarDataType": "Typ:",
    "solarDataSlope": "Neigung:",
    "solarDataSlopeOptimal": "Optimale Neigung:",
    "solarDataOrientationAngle": "Ausrichtungswinkel:",
    "solarDataOrientationAngleOptimal": "Optimaler Ausrichtungswinkel:",
    "solarDataOverview": "Übersicht",
    "solarDataBatteryCapacity": "Batteriekapazität:",
    "solarDataBatteryDischargeCutoffLimit": "Abschaltgrenze der Batterieentladung:",
    "solarDataDailyEnergyConsumption": "Täglicher Energieverbrauch:",
    "solarDataMonth": "Monat",
    "solarDataDailyEnergy": "Tägliche Energie",
    "solarDataMonthlyEnergy": "Monatliche Energie",
    "solarDataDailyIrradiance": "Tägliche Einstrahlung",
    "solarDataMonthlyIrradiance": "Monatliche Einstrahlung",
    "solarDataSunshineDuration": "Sonnenscheindauer",
    "solarDataEnergyLostPerDay": "Energieverlust pro Tag",
    "solarDataFillFactor": "Füllfaktor",
    "solarDataFactorOfEfficiency": "Wirkungsgradfaktor",
    "solarDataLocationDataPermissionError": "Standortdatenberechtigungsfehler",
    "solarDataPermanentLocationDataPermissionError": "Dauerhafter Standortdatenberechtigungsfehler",
    "solarDataErrorFetchingLocation": "Fehler beim Abrufen des Standorts:",
    "solarDataMaxBudgetEuros": "Maximalbudget (Euro)",
    "solarDataMaxBudgetDescription": 'Der Parameter "Maximalbudget" ermöglicht es Benutzern, die Gesamtkosten einzugeben, die sie für die Installation des gesamten PV-Systems antizipieren oder planen.\n\nDiese Kosten umfassen alle Ausgaben im Zusammenhang mit dem Erwerb und der Installation der Solarpaneele, Wechselrichter, Montagehardware, Verkabelung, Arbeitskosten, Genehmigungen und etwaige zusätzliche Kosten, die für die Installation des PV-Systems erforderlich sind.\n\n',
    "solarDataMountingPlace": "Montageort",
    "solarDataTypeDescription": 'Art der Montage der PV-Module. Auswahlmöglichkeiten sind:\n\n"frei" für freistehende\n"gebäude" für gebäudeintegrierte\n\n',
    "solarDataFixed": "Fixiert",
    "solarDataFixedDescription": 'Berechnen Sie ein fest installiertes System.\n\n',
    "solarDataInclinedAxis": "Geneigte Achse",
    "solarDataInclinedAxisDescription": 'Berechnen Sie ein System mit einer einzigen geneigten Achse.\n\n',
    "solarDataVerticalAxis": "Vertikale Achse",
    "solarDataVerticalAxisDescription": 'Berechnen Sie ein System mit einer einzigen vertikalen Achse.\n\n',
    "solarDataTwoAxis": 'Zwei Achsen',
    "solarDataTwoAxisDescription": 'Berechnen Sie ein System mit zwei Achsen',
    "solarDataPvTechChoice": "PV-Tech-Wahl",
    "solarDataPvTechDescription": 'Verwendete Solarmodultechnologie.\n\nPV-Technologie. Die Auswahlmöglichkeiten sind: "crystSi", "CIS", "CdTe" und "Unbekannt".\n\n',
    "solarDataPeakPowerKw": "Spitzenleistung (kW)",
    "solarDataPeakPowerKwDescription": 'Geben Sie die Spitzenleistung des Solarsystems in Kilowatt ein.\n\n Dies ist die maximale Leistung, die das System unter idealen Bedingungen erzeugen kann.\n\n',
    "solarDataLossPercentage": "Verlust (%))",
    "solarDataLossPercentageDescription": 'Geben Sie den Prozentsatz des Systemverlusts ein.\n\nDies berücksichtigt verschiedene Verluste im System, einschließlich Wirkungsgradverlusten und Verschattung.\n\n',
    "solarDataAngle": "Winkel (°)",
    "solarDataAngleDescription": 'Geben Sie den Neigungswinkel für die Solarpaneele ein.\n\n'
    'Dies ist der Neigungswinkel zur Horizontalen, unter dem die Solarpaneele installiert sind.\n\n'
    '0=Süden, 90=Westen, -90=Osten.\n\n',
    "solarDataAspect": "Aspekt (°)",
    "solarDataAspectDescription": 'Geben Sie den Aspekt der Solarpaneele ein.\n\n'
      'Dies bezieht sich auf die Ausrichtung der Paneele in Bezug auf den Horizont.\n'
      'Ein "Aspekt"-Wert von 0 bedeutet, dass die Paneele nach Süden ausgerichtet sind.\n\n'
      'Ein Aspektwert von 90 repräsentiert eine Ausrichtung nach Westen.\n\n'
      'Ein Aspektwert von -90 impliziert eine Ausrichtung nach Osten..\n\n',
    "solarDataLifetimeYears": "Lebensdauer (Jahre)",
    "solarDataLifetimeYearsDescription": 'Erwartete Lebensdauer des PV-Systems in Jahren.\n\n',
    "solarDataUseHorizon": "Horizont verwenden",
    "solarDataUseHorizonDescription": 'Berechnen unter Berücksichtigung von Schatten durch einen hohen Horizont.\n\n',
    "solarDataOptimalInclination": "Optimale Neigung",
    "solarDataOptimalInclinationDescription": 'Berechnen Sie den optimalen Neigungswinkel.\n\nFür das feste PV-System wird bei Aktivierung dieses Parameters der für den Parameter "Winkel" definierte Wert ignoriert',
    "solarDataOptimalAngles": "Optimale Winkel",
    "solarDataOptimalAnglesDescription": 'Berechnen Sie die optimale Neigungs- und Ausrichtungswinkel.\n\nBei Aktivierung dieses Parameters werden Werte für "Winkel" und "Aspekt" ignoriert und sind daher nicht erforderlich',
    "solarDataInclinedOptimum": "Geneigte Optimal",
    "solarDataInclinedOptimumDescription": 'Optimalen Winkel für ein einzelnes geneigtes Achssystem berechnen.\n\n',
    "solarDataInclinedAxisAngle": "Neigungswinkel der geneigten Achse (°)",
    "solarDataInclinedAxisAngleDescription": 'Neigungswinkel für ein System mit einer einzigen geneigten Achse.\n\nIgnoriert, wenn der optimale Winkel berechnet werden soll.\n\n',
    "solarDataVerticalOptimum": "Vertikale Optimal",
    "solarDataVerticalOptimumDescription": 'Calculate optimum angle for a single vertical axis system.\n\n',
    "solarDataVerticalAxisAngle": "Neigungswinkel der vertikalen Achse (°)",
    "solarDataVerticalAxisAngleDescription": 'Neigungswinkel für ein System mit einer einzigen vertikalen Achse.\n\nIgnoriert, wenn der optimale Winkel berechnet werden soll.\n\n',
    "solarDataBatterySize": "Batteriegröße (Wh)",
    "solarDataBatterySizeDescription": 'Dies ist die Größe oder Energiekapazität der Batterie, die im Off-Grid-System verwendet wird, gemessen in Wattstunden (Wh).\n\n',
    "solarDataBatteryCutoff": "Batterieabschaltung (%)",
    "solarDataBatteryCutoffDescription": 'Batterieabschaltung in %. Die Abschaltung erfolgt, damit der Batterieladezustand nicht unter einen bestimmten Prozentsatz der vollen Ladung fallen kann.\n\n',
    "solarDataRadiationDatabase": "Strahlungsdatenbankname",
    "solarDataRadiationDatabaseDescription": 'Name der Strahlungsdatenbank. "PVGIS-SARAH" für Europa, Afrika und Asien oder "PVGIS-NSRDB" für die Amerikas zwischen 60°N und 20°S, "PVGIS-ERA5" und "PVGIS-COSMO" für Europa (einschließlich hoher Breitengrade).\n\n',
    "solarDataConsumptionPerDay": "Verbrauch pro Tag (Wh)",
    "solarDataConsumptionPerDayDescription": 'Energieverbrauch aller mit dem System verbundenen elektrischen Geräte während eines 24-Stunden-Zeitraums (Wh).\n\n',

  };

  return textContents[textContentType] ?? "";

}

String getTextContentEnglish(String textContentType) {

  Map<String, String> textContents = {
    // Login
    "welcomeText": "Welcome ",
    "continueText": "Continue",
    "biometricsText": "Enable Biometrics",
    "forgotPasswordText": "Forgot Password?",
    "notRegisteredText": "Not yet registered?",
    "resetPasswordText": "Reset Password",
    "resetPasswordHintText": "Enter your email",
    "resetPasswordNotificationText": "A notification has been sent to your email account.",
    "handleLoginError1": "Please enter both email and password.",
    "handleLoginError2": " is not verified. Please verify your identity first!",
    "handleLoginError3": " is disabled. Please contact the support team",
    "handleLoginErrorGeneral": "An error occurred during login.",

    // Biometric Setup
    "biometricSetupError1": "Hardware does not support Biometrics!",
    "biometricSetupErrorGeneral": "Biometric Authentication failed!",
    "biometricSetupSuccess": "Biometric Authentication successful!",
    "localizedReason": "Scan your finger to authenticate",
    "biometricAuthMethod": "Authenticate using your fingerprint instead of your password",
    "biometricAuth": "Authenticate",

    // Chat Window
    "chatWindowError1": "Could not find any administrative users!",
    "chatWindowTextAdmin": "Customer Chat Requests",
    "chatWindowTextClient": "Chat with Us",
    "chatWindowRequestHintText": "Type your message here...",
    "chatWindowReplyHintText": "Type your reply here...",
    "chatWindowDeleteMessageError": "Error deleting message: ",
    "chatWindowReplyText": "Reply Message",
    "chatWindowYourText": "Your Message",
    "chatWindowSendReplyText": "Send Reply",
    "chatWindowFromText": "From",

    // Dashboard Section
    "dashboardTitle1": "Document Library",
    "dashboardDescription1": "Seamless Access",
    "dashboardDetailedDescription1": "Effortlessly access, download, and seamlessly navigate through our comprehensive document library, "
        "\n ensuring easy and efficient management of all your important files.",
    "dashboardDetailedDescriptionAdmin1": "Effortlessly access, download, and seamlessly navigate through our comprehensive document library, "
        "\n ensuring easy and efficient management of all your important files.",
    "dashboardButtonText1": "Access Docs Now",
    "dashboardTitle2": "Document Upload",
    "dashboardDescription2": "Easy Upload",
    "dashboardDetailedDescription2": "Empower your solar panel planning by effortlessly uploading your own documents to our cloud, "
        "\nlaying the foundation for personalized solar panel design tailored to your specific needs.",
    "dashboardDetailedDescriptionAdmin2": "Empower customer solar panel planning by effortlessly uploading Plans and Offers to our cloud, "
        "\nlaying the foundation for personalized solar panel design tailored to customers specific needs.",
    "dashboardButtonText2": "Upload Docs Now",
    "dashboardTitle3": "Solar Insights",
    "dashboardDescription3": "Gain Performance Forecasts",
    "dashboardDetailedDescription3": "Explore tailored forecasts for solar panel performance across diverse environments, configurations, and conditions. "
        "Get detailed insights that enable informed decisions about solar installations by predicting efficiency, energy output, and other critical factors crucial "
        "for optimizing solar projects. "
        "Send us your specifications for personalized forecasts!",
    "dashboardDetailedDescriptionAdmin3": "Explore tailored forecasts for solar panel performance across diverse environments, configurations, and conditions. "
        "Get detailed insights that enable informed decisions about solar installations by predicting efficiency, energy output, and other critical factors crucial "
        "for optimizing solar projects. "
        "Send us your specifications for personalized forecasts!",
    "dashboardButtonText3": "Get Forecasts Now",

    // Document
    "documentErrorLoading": "Error loading document",
    "documentErrorShow": "Unable to show document",
    "documentErrorFormat": "Unsupported document format",

    // Document Library
    "documentLibraryDownloadError": "Could not access download directory",
    "documentLibraryLoadingDataError": "Error loading data",
    "documentLibraryLoadingDocumentError": "Error loading documents",
    "documentLibraryDownloadNotification": "Download Complete",
    "documentLibraryDownloadSuccess": " downloaded successfully",
    "documentLibraryDeleteSuccess": " deleted successfully",
    "documentLibraryNoUserData": "No user data available",
    "documentLibraryUserNotExists": "The user does not exist.",
    "documentLibraryUserRoleNotExists": "User Role not defined",
    "documentLibraryUserDomainNotExists": "User Domain not defined",
    "documentLibraryNoDocs": "No documents available.",
    "documentLibraryDomain": "Domain",
    "documentLibraryYear": "Year",
    "documentLibraryCategory": "Category",
    "documentLibraryPrefixFrom": "From",
    "documentLibraryPrefixFor": "For",
    "documentLibraryCategoryCustomerAdmin": "Customer Docs",
    "documentLibraryCategoryCustomerClient": "My Docs",

    // Helpers
    "helperUserNotSignedIn": "User is not signed in!",

    // Document Operations
    "docOperationsNoDocs": "No Documents available for upload",
    "docOperationsUploadSuccess": " uploaded successfully",

    // Main
    "mainGooglePlayNotAvailable": "Google Play Services Unavailable",
    "mainGooglePlayInstallMessage": "Please install or update Google Play Services.",
    "mainNotification": "New Notification",
    "mainNewDocument": "You have a new document!",

    // Registration
    "registrationEmptyField": "Please fill out Username, Email and Password",
    "registrationInvalidEmail": "Please enter a valid email address",
    "registrationInvalidPasswordLength": "Password must be at least 8 characters long",
    "registrationInvalidPasswordCharacters": "Password must contain at least one special character",
    "registrationUsername": "Username",
    "registrationPassword": "Password",
    "registrationDomain": "Choose your domain based on your location:",
    "registrationExample": "Examples",
    "registrationRegister": "Register",
    "registrationSuccess": "User registered successfully!",
    "registrationNextSteps": "The next steps are:\n- Close this App or Return to the Login Screen\n- Verify your email address with the verification link sent to you by email\n- Login with your email address and password",

    // User Details
    "userDetailsTitle": "Customers and Admins",
    "userDetailsNoUserData": "No user data available",

    // Solar AI
    "solarDataTitle": "Solar Data",
    "solarDataForecast": "Solar Data Forecast",
    "solarDataOverview": "Overview",
    "solarDataMaxBudget": "Maximum Budget:",
    "solarDataMaxLifetime": "Maximum Lifetime:",
    "solarDataTechnology": "Technology:",
    "solarDataPeakPower": "Peak Power:",
    "solarDataSystemLoss": "System Loss:",
    "solarDataDatabase": "Database:",
    "solarDataLocationData": "Location Data",
    "solarDataElevation": "Elevation:",
    "solarDataMountingSystem": "Mounting System",
    "solarDataType": "Type:",
    "solarDataSlope": "Slope:",
    "solarDataSlopeOptimal": "Slope is Optimal:",
    "solarDataOrientationAngle": "Orientation Angle:",
    "solarDataOrientationAngleOptimal": "Orientation Angle is Optimal:",
    "solarDataBatteryCapacity": "Battery Capacity:",
    "solarDataBatteryDischargeCutoffLimit": "Battery Discharge Cutoff Limit:",
    "solarDataDailyEnergyConsumption": "Daily Energy Consumption:",
    "solarDataMonth": "Month",
    "solarDataDailyEnergy": "Daily Energy",
    "solarDataMonthlyEnergy": "Monthly Energy",
    "solarDataDailyIrradiance": "Daily Irradiance",
    "solarDataMonthlyIrradiance": "Monthly Irradiance",
    "solarDataSunshineDuration": "Sunshine Duration",
    "solarDataEnergyLostPerDay": "Energy Lost Per Day",
    "solarDataFillFactor": "Fill Factor",
    "solarDataFactorOfEfficiency": "Factor Of Efficiency",
    "solarDataLocationDataPermissionError": "Location Data Permission Error",
    "solarDataPermanentLocationDataPermissionError": "Permanent Location Data Permission Error",
    "solarDataErrorFetchingLocation": "Error Fetching Location:",
    "solarDataMaxBudgetEuros": "Maximum Budget (Euros)",
    "solarDataMaxBudgetDescription": 'The Maximum Budget parameter allows users to input the total cost they anticipate or plan to spend on installing the entire PV system.\n\nThis cost encompasses all the expenses associated with acquiring and installing the solar panels, inverters, mounting hardware, wiring, labor, permits, and any additional costs required for the installation of the PV system.\n\n',
    "solarDataMountingPlace": "Mounting Place",
    "solarDataTypeDescription": 'Type of mounting of the PV modules. Choices are:\n\n"free" for free-standing\n"building" for building-integrated\n\n',
    "solarDataFixed": "Fixed",
    "solarDataFixedDescription": 'Calculate a fixed mounted system.\n\n',
    "solarDataInclinedAxis": "Inclined Axis",
    "solarDataInclinedAxisDescription": 'Calculate a single inclined axis system.\n\n',
    "solarDataVerticalAxis": "Vertical Axis",
    "solarDataVerticalAxisDescription": 'Calculate a single vertical axis system.\n\n',
    "solarDataTwoAxis": 'Two Axis',
    "solarDataTwoAxisDescription": 'Calculate a two axis tracking system.',
    "solarDataPvTechChoice": "PV Tech Choice",
    "solarDataPvTechDescription": 'Solar Panel technology in use.\n\nPV technology. Choices are: "crystSi", "CIS", "CdTe" and "Unknown".\n\n',
    "solarDataPeakPowerKw": "Peak Power (kW)",
    "solarDataPeakPowerKwDescription": 'Enter the peak power of the solar system in kilowatts.\n\n '
        'This is the maximum power that can be generated by the system under ideal conditions.\n\n',
    "solarDataLossPercentage": "Loss (%)",
    "solarDataLossPercentageDescription": 'Enter the percentage of system loss.\n\n'
        'This accounts for various losses in the system, including efficiency losses and shading.\n\n',
    "solarDataAngle": "Angle (°)",
    "solarDataAngleDescription": 'Enter the angle of inclination for the solar panels.\n\n'
        'This is the tilt angle from the horizontal plane at which the solar panels are installed.\n\n'
        '0=south, 90=west, -90=east.\n\n',
    "solarDataAspect": "Aspect (°)",
    "solarDataAspectDescription": 'Enter the aspect of the solar panels.\n\n'
        'This refers to the orientation of the panels with respect to the horizon.\n'
        'An "aspect" value of 0 implies that the panels are oriented towards the south.\n\n'
        'An aspect value of 90 represents a west-facing orientation.\n\n'
        'An aspect value of -90 implies an east-facing orientation..\n\n',
    "solarDataLifetimeYears": "Lifetime (Years)",
    "solarDataLifetimeYearsDescription": 'Expected lifetime of the PV system in years.\n\n',
    "solarDataUseHorizon": "Use Horizon",
    "solarDataUseHorizonDescription": 'Calculate taking into account shadows from high horizon.\n\n',
    "solarDataOptimalInclination": "Optimal Inclination",
    "solarDataOptimalInclinationDescription": 'Calculate the optimum inclination angle.\n\nFor the fixed PV system, if this parameter is enabled, the value defined for the "Angle" parameter is ignored',
    "solarDataOptimalAngles": "Optimal Angles",
    "solarDataOptimalAnglesDescription": 'Calculate the optimum inclination and orientation angles.\n\nIf this parameter is enabled, values defined for "Angle" and "Aspect" are ignored and therefore are not necessary',
    "solarDataInclinedOptimum": "Inclined Optimum",
    "solarDataInclinedOptimumDescription": 'Calculate optimum angle for a single inclined axis system.\n\n',
    "solarDataInclinedAxisAngle": "Inclined Axis Angle (°)",
    "solarDataInclinedAxisAngleDescription": 'Inclination angle for a single inclined axis system.\n\nIgnored if the optimum angle should be calculated.\n\n',
    "solarDataVerticalOptimum": "Vertical Optimum",
    "solarDataVerticalOptimumDescription": 'Calculate optimum angle for a single vertical axis system.\n\n',
    "solarDataVerticalAxisAngle": "Vertical Axis Angle (°)",
    "solarDataVerticalAxisAngleDescription": 'Inclination angle for a single vertical axis system.\n\nIgnored if the optimum angle should be calculated.\n\n',
    "solarDataBatterySize": "Battery Size (Wh)",
    "solarDataBatterySizeDescription": 'This is the size, or energy capacity, of the battery used in the off-grid system, measured in watt-hours (Wh).\n\n',
    "solarDataBatteryCutoff": "Battery Cutoff (%)",
    "solarDataBatteryCutoffDescription": 'Batteries cutoff in %. The cutoff is imposed so that the battery charge cannot go below a certain percentage of full charge..\n\n',
    "solarDataRadiationDatabase": "Radiation Database Name",
    "solarDataRadiationDatabaseDescription": 'Name of the radiation database. "PVGIS-SARAH" for Europe, Africa and Asia or "PVGIS-NSRDB" for the Americas between 60°N and 20°S, "PVGIS-ERA5" and "PVGIS-COSMO" for Europe (including high-latitudes).\n\n',
    "solarDataConsumptionPerDay": "Consumption Per Day (Wh)",
    "solarDataConsumptionPerDayDescription": 'Energy consumption of all the electrical equipment connected to the system during a 24 hour period (Wh).\n\n',
  };

  return textContents[textContentType] ?? "";

}
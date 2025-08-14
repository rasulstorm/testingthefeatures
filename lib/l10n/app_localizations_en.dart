// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ISS.AI';

  @override
  String get homeTab => 'Home';

  @override
  String get objectsTab => 'Objects';

  @override
  String get settingsTab => 'Settings';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get profileIcon => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get generalSection => 'General';

  @override
  String get languageSetting => 'Language';

  @override
  String get themeSetting => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get accountSection => 'Account';

  @override
  String get profileSetting => 'Profile';

  @override
  String get securitySetting => 'Security';

  @override
  String get logoutSetting => 'Log Out';

  @override
  String get supportSection => 'Support';

  @override
  String get helpSetting => 'Help';

  @override
  String get aboutAppSetting => 'About App';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languageKazakh => 'Kazakh';

  @override
  String get changePassword => 'Change Password';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get myContracts => 'My Contracts';

  @override
  String get noObjects => 'No Objects';

  @override
  String get loadingObjects => 'Loading objects...';

  @override
  String get errorLoadingObjects => 'Error loading objects:';

  @override
  String get retry => 'Retry';

  @override
  String get addHub => 'Add Object';

  @override
  String get hubId => 'Object ID';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get hubAddedSuccessfully => 'Object added successfully';

  @override
  String get errorAddingHub => 'Error adding object:';

  @override
  String get lastUpdate => 'Last update:';

  @override
  String get room => 'Room:';

  @override
  String get group => 'Group:';

  @override
  String get disarm => 'Disarm';

  @override
  String get arm => 'Arm';

  @override
  String get alarm => 'Alarm';

  @override
  String get noMessage => 'No message';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get address => 'Address:';

  @override
  String get status => 'Status:';

  @override
  String devicesOnHub(Object count) {
    return 'Devices on hub ($count)';
  }

  @override
  String get noDevicesFound => 'No devices found on this hub.';

  @override
  String get close => 'Close';

  @override
  String get subscriptionNotActive => 'Subscription not active';

  @override
  String get bindCard => 'Bind Card';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get amount => 'Amount:';

  @override
  String get date => 'Date:';

  @override
  String get description => 'Description:';

  @override
  String get cardBoundSuccessfully => 'Card bound successfully';

  @override
  String get errorBindingCard => 'Error binding card';

  @override
  String get errorLoadingWebView => 'Error loading WebView';

  @override
  String get subscriptionFee => 'Subscription fee:';

  @override
  String get statusActive => 'Status: Active';

  @override
  String get card => 'Card';

  @override
  String get nextPayment => 'Next payment:';

  @override
  String get cardBound => 'Card bound';

  @override
  String get errorLoadingCard => 'Error loading card';

  @override
  String get update => 'Update';

  @override
  String get welcome => 'Welcome!';

  @override
  String get createAccount => 'Create an account';

  @override
  String get name => 'Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phone => 'Phone';

  @override
  String get iin => 'IIN';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get agreePrivacyPolicy => 'I agree to the privacy policy';

  @override
  String get acceptPublicOffer => 'I accept the public offer';

  @override
  String get register => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Log In';

  @override
  String get enterEmailPassword => 'Please enter your email and password';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get otpVerification => 'OTP Verification';

  @override
  String enterCodeSentTo(Object phone) {
    return 'Enter the code sent to $phone';
  }

  @override
  String get otpCode => 'OTP Code';

  @override
  String get verify => 'Verify';

  @override
  String get registrationSuccess => 'Registration successful! Confirm code';

  @override
  String get registrationAndLoginSuccess =>
      'Registration and login successful!';

  @override
  String get verificationError => 'Verification error';

  @override
  String get networkError => 'Network error: No connection';

  @override
  String get generalError => 'An error occurred:';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get errorChangingPassword => 'Error changing password:';

  @override
  String get save => 'Save';

  @override
  String get whatsappCodeTitle => 'WhatsApp Code';

  @override
  String get enterPhoneForCode =>
      'Enter your phone number to receive a code via WhatsApp';

  @override
  String get sendCode => 'Send Code';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSuccessfully => 'Password reset successfully';

  @override
  String get errorResettingPassword => 'Error resetting password:';

  @override
  String get aboutUsTitle => 'About Us';

  @override
  String get ourMission => 'Our Mission';

  @override
  String get whatWeOffer => 'What we offer?';

  @override
  String get mainServices => 'Main services:';

  @override
  String get securitySystems =>
      'Comprehensive security systems: Monitoring, motion sensors, real-time notifications.';

  @override
  String get smartLighting =>
      'Smart lighting: Scenario settings, remote control, energy saving.';

  @override
  String get climateControl =>
      'Climate control: Automatic temperature adjustment for your comfort.';

  @override
  String get videoSurveillance =>
      'Video surveillance: Access to cameras anywhere in the world, event recording.';

  @override
  String get smartDeviceIntegration =>
      'Smart device integration: Support for a wide range of third-party gadgets.';

  @override
  String get questions => 'Any questions?';

  @override
  String get contactUs =>
      'If you have any questions, suggestions, or want to know more about our services, please contact us.';

  @override
  String get failedToOpenEmail => 'Failed to open email application';

  @override
  String get myContractsTitle => 'My Contracts';

  @override
  String get noActiveContracts => 'You don\'t have any active contracts yet.';

  @override
  String get contract => 'Contract:';

  @override
  String get nextPaymentDate => 'Next payment:';

  @override
  String get amountPaid => 'Amount paid:';

  @override
  String get deleteConfirmationTitle => 'Confirm Deletion';

  @override
  String get deleteConfirmationMessage =>
      'Are you sure you want to delete the account? This action is irreversible.';

  @override
  String get delete => 'Delete';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get errorDeletingAccount => 'Error deleting account:';

  @override
  String get logoutConfirmationTitle => 'Confirm Logout';

  @override
  String get logoutConfirmationMessage => 'Are you sure you want to log out?';

  @override
  String get logout => 'Log Out';

  @override
  String get unknown => 'unknown';

  @override
  String get errorLoadingContracts => 'Error loading contracts';

  @override
  String get roomsTitle => 'Rooms';

  @override
  String get devicesTitle => 'Devices';

  @override
  String get noRoomsFound => 'No rooms found. Add rooms to get started!';

  @override
  String get noDevicesInRoom => 'No devices have been added to this room yet.';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get light => 'Light';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get motionDetected => 'Motion';

  @override
  String get noMotion => 'Clear';

  @override
  String get homeOverview => 'Home Overview';

  @override
  String get yourHome => 'Your Home';

  @override
  String get totalDevices => 'Total devices:';

  @override
  String get activeDevices => 'Active devices:';

  @override
  String get totalRooms => 'Total rooms:';

  @override
  String get favoriteDevices => 'Favorite Devices';

  @override
  String get active => 'active';

  @override
  String get iAmHome => 'I am Home';

  @override
  String get officeShort => 'Office';

  @override
  String get doorClosedShort => 'Closed';

  @override
  String get doorNoun => 'Door';

  @override
  String get noResponse => 'No Response';

  @override
  String get chandelier => 'Chandelier';

  @override
  String get topLight => 'Top Light';

  @override
  String get noPower => 'No Power';

  @override
  String get noWater => 'No Water';

  @override
  String get tempShort => 'Temp.';

  @override
  String get humidityShort => 'Humid.';

  @override
  String get lightShort => 'Light';

  @override
  String get all => 'All';

  @override
  String get livingRoom => 'Living Room';

  @override
  String get kitchen => 'Kitchen';

  @override
  String get errorLoadingImage => 'Error loading image';

  @override
  String get list => 'List';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get search => 'Search';

  @override
  String get noHubsFound => 'No hubs found';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get noControlAvailable => 'Control unavailable';

  @override
  String get connectionActive => 'Connection Active';

  @override
  String get connectionLost => 'Connection Lost';

  @override
  String get homeScreenTitle => 'Home Screen';

  @override
  String get noHubsAvailable =>
      'No available objects. Please add an object to get started.';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get commandHubId => 'Command Hub ID';

  @override
  String get noDevices => 'No devices found for this hub.';

  @override
  String get errorLoadingHubs => 'Error loading hubs';

  @override
  String get switchAll => 'Switch All';

  @override
  String get powerOffAll => 'Power Off All';

  @override
  String get noDataAvailable => 'No data available.';

  @override
  String get brightness => 'Brightness';

  @override
  String get lightLevel => 'Light Level';

  @override
  String get occupancy => 'Occupancy';

  @override
  String get detected => 'Detected';

  @override
  String get clear => 'Clear';

  @override
  String get batteryStatus => 'Battery Status';

  @override
  String get low => 'Low';

  @override
  String get normal => 'Normal';

  @override
  String get tamper => 'Tamper';

  @override
  String get distance => 'Distance';

  @override
  String get controllableDevices => 'Controllable Devices';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get switchAllSuccess => 'All devices switched.';

  @override
  String get powerOffAllSuccess => 'All devices powered off.';

  @override
  String get noControllableDevices => 'No controllable devices found.';

  @override
  String get dimmer => 'Dimmer';

  @override
  String get switchDevice => 'Switch';

  @override
  String get blinds => 'Blinds';

  @override
  String get blindsControlTip =>
      'Use buttons to control blinds (Open/Stop/Close)';

  @override
  String get statusIndicators => 'Status Indicators';

  @override
  String get gasDetected => 'Gas Detected';

  @override
  String get smokeDetected => 'Smoke Detected';

  @override
  String get waterLeak => 'Water Leak';

  @override
  String get moving => 'motion detected';

  @override
  String get subscriptionStatus => 'Subscription Status';

  @override
  String get cardIsBound => 'Card is Bound';

  @override
  String get totalContractAmount => 'Total Contract Amount';

  @override
  String get nextCharge => 'Next Charge';

  @override
  String get errorLoadingSubscription => 'Error loading subscription';

  @override
  String get errorLoadingPayments => 'Error loading payments';

  @override
  String get errorLoadingCardInfo => 'Error loading card info';

  @override
  String get errorLoadingBindForm => 'Error loading bind form';

  @override
  String get noPaymentRecords => 'No payment records';

  @override
  String get noDescription => 'No description';

  @override
  String get notAttached => 'Not Attached';

  @override
  String get scenariosTab => 'Scenarios';

  @override
  String get scenariosEmptyList => 'Scenario list is empty.';

  @override
  String get scenariosCreatePrompt => 'Create your first scenario!';

  @override
  String get createScenarioButton => 'Create New Scenario';

  @override
  String get createScenarioNotImplemented =>
      'Navigate to new scenario creation (not implemented yet)';

  @override
  String get loginTitle => 'Login';

  @override
  String get emailPlaceholder => 'Email';

  @override
  String get passwordPlaceholder => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get registerHere => 'Register here';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get profileTitle => 'Profile';

  @override
  String currentLanguage(Object language) {
    return 'Current Language: $language';
  }

  @override
  String get accountDeletedSuccess => 'Account successfully deleted.';

  @override
  String get accountDeleteError => 'Error deleting account';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get loginError => 'Login failed';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get createScenarioTitle => 'Create Scenario';

  @override
  String get editScenarioTitle => 'Edit Scenario';

  @override
  String get scenarioGeneralSettings => 'Scenario General Settings';

  @override
  String get scenarioNameLabel => 'Scenario Name';

  @override
  String get scenarioNameRequired => 'Scenario name is required';

  @override
  String get scenarioEnabledLabel => 'Scenario Enabled';

  @override
  String get scenarioTriggers => 'Triggers';

  @override
  String get addTriggerButton => 'Add Trigger';

  @override
  String get scenarioConditions => 'Conditions';

  @override
  String get addConditionButton => 'Add Condition';

  @override
  String get scenarioActions => 'Actions';

  @override
  String get addActionBtn => 'Add Action';

  @override
  String get saveScenarioButton => 'Save Scenario';

  @override
  String get deviceNameLabel => 'Device Name';

  @override
  String get attributeLabel => 'Attribute';

  @override
  String get operatorLabel => 'Operator';

  @override
  String get valueLabel => 'Value';

  @override
  String get commandJsonLabel => 'Command JSON';

  @override
  String triggerLabel(int number) {
    return 'Trigger $number';
  }

  @override
  String conditionLabel(int number) {
    return 'Condition $number';
  }

  @override
  String actionLabel(int number) {
    return 'Action $number';
  }

  @override
  String get scenariosListEmpty => 'No scenarios here yet.';

  @override
  String get createFirstScenarioPrompt =>
      'Create your first scenario to automate smart home management.';

  @override
  String get createNewScenarioButton => 'Create New Scenario';

  @override
  String get translate => 'Translate';

  @override
  String get setupWifi => 'Setup Wifi';

  @override
  String get wifiSetupScreenTitle => 'Wi-Fi Setup';

  @override
  String get wifiSetupInstructions =>
      'Enter your Wi-Fi network details to connect the hub.';

  @override
  String currentWifiNetwork(Object ssid) {
    return 'Current Wi-Fi Network: $ssid';
  }

  @override
  String get wifiNetworkNameLabel => 'Wi-Fi Network Name (SSID)';

  @override
  String get wifiNetworkNameHint => 'e.g., MyHomeNetwork';

  @override
  String get ssidRequiredError => 'SSID cannot be empty.';

  @override
  String get wifiPasswordLabel => 'Wi-Fi Password';

  @override
  String get wifiPasswordHint => 'Enter your home Wi-Fi password';

  @override
  String get configureWifiButton => 'Configure Wi-Fi';

  @override
  String get wifiSetupSuccessMessage =>
      'Wi-Fi setup successful! Hub is connecting to your network.';

  @override
  String wifiSetupErrorMessage(Object statusCode, Object message) {
    return 'Failed to set up Wi-Fi. Error code: $statusCode. Message: $message';
  }

  @override
  String get unknownErrorMessage =>
      'An unknown error occurred. Please check SSID and password correctness.';

  @override
  String get hubConnectionErrorMessage =>
      'Cannot connect to the hub. Please ensure your device is connected to the hub\'s Wi-Fi access point (usually starts with \"ISS-Hub-\") and try again.';

  @override
  String serverErrorMessage(Object statusCode, Object message) {
    return 'Server error ($statusCode): $message';
  }

  @override
  String get checkWifiDataError => 'Please check Wi-Fi credentials.';

  @override
  String networkErrorMessage(Object message) {
    return 'A network error occurred: $message. Please check your internet connection.';
  }

  @override
  String get unknownNetworkError => 'Unknown network error';

  @override
  String get getString => 'No Face ID login for this account';

  @override
  String unexpectedErrorMessage(Object errorMessage) {
    return 'An unexpected error occurred: $errorMessage. Please try again.';
  }

  @override
  String get createPinTitle => 'Create PIN code';

  @override
  String get createPinDescription =>
      'Please enter a 4-digit PIN code for quick authorization.';

  @override
  String get confirmPinTitle => 'Confirm PIN code';

  @override
  String get confirmPinDescription => 'Please re-enter your 4-digit PIN code.';

  @override
  String get enterPinTitle => 'Enter PIN code';

  @override
  String get enterPinDescription => 'Please enter your 4-digit PIN code.';

  @override
  String get changeOldPinTitle => 'Change PIN code';

  @override
  String get enterOldPinTitle => 'Enter old PIN code';

  @override
  String get enterOldPinDescription =>
      'To change your PIN code, please enter your current PIN code.';

  @override
  String get createNewPinTitle => 'Create new PIN code';

  @override
  String get createNewPinDescription => 'Please enter a new 4-digit PIN code.';

  @override
  String get confirmNewPinTitle => 'Confirm new PIN code';

  @override
  String get confirmNewPinDescription =>
      'Please re-enter your new 4-digit PIN code.';

  @override
  String get pinSetSuccess => 'PIN code successfully set.';

  @override
  String get pinChangedSuccess => 'PIN code successfully changed.';

  @override
  String get pinVerifiedSuccess => 'PIN code successfully verified.';

  @override
  String get pinMismatch => 'PIN codes do not match. Please try again.';

  @override
  String get incorrectPin => 'Incorrect PIN code.';

  @override
  String attemptsRemaining(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'You have # attempts remaining.',
      one: 'You have # attempt remaining.',
    );
    return '$_temp0';
  }

  @override
  String get pinLockedOut => 'PIN code locked. Too many failed attempts.';

  @override
  String get pinLockedOutRedirect =>
      'PIN code locked. Please log in with your username and password.';

  @override
  String get loginWithPassword => 'Log in with password';

  @override
  String get localAuthSetting => 'Face ID / PIN code login';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get useBiometricsOnly => 'Use Face ID only (if available)';

  @override
  String get biometricsOnlyDescription =>
      'Login will be via Face ID only. PIN code will be disabled.';

  @override
  String get biometricsAndPinDescription =>
      'Login will be via Face ID or PIN code as a fallback.';

  @override
  String get authReason => 'Confirm your identity to enter the application';

  @override
  String get authFailedLocalAuthNotEnabled =>
      'Failed to enable local authentication.';

  @override
  String get authFailedBiometricsPinNotFound =>
      'Biometric authentication failed, or PIN code not set/unavailable.';

  @override
  String get sessionExpiredLoginAgain => 'Session Expired. Please login again.';

  @override
  String get localAuthFailedLoginWithCredentials =>
      'Authentication failed. Please login with username/password.';

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get authFailed =>
      'Authentication failed. Please log in with username/password.';

  @override
  String get setupPinTitle => 'Set up PIN code';

  @override
  String get setupPinDescription =>
      'You can set up a PIN code for quick access to the application.';

  @override
  String get setupPinButton => 'Set PIN';

  @override
  String get faceIdPinSettingTitle => 'Face ID / PIN Login';

  @override
  String get localAuthNotAvailable =>
      'Not available on your device or not configured.';

  @override
  String get localAuthEnabledMessage => 'Face ID/PIN login enabled.';

  @override
  String get localAuthNotEnabledMessage =>
      'Authentication failed. Face ID/PIN login not enabled.';

  @override
  String get localAuthDisabledMessage => 'Face ID/PIN login disabled.';

  @override
  String get loadingApp => 'Loading application...';

  @override
  String get incorrectOldPin => 'Incorrect old Pincode';

  @override
  String dimmerControlTitle(Object deviceName) {
    return 'Dimmer control $deviceName';
  }

  @override
  String deviceControlModalTitle(Object deviceType, Object deviceName) {
    return 'Device Control: $deviceType ($deviceName)';
  }

  @override
  String get switchingHistoryTitle => 'Switching History';

  @override
  String get switchingHistoryUnderDevelopment =>
      'Switching history is under development.';

  @override
  String get deviceInfoTitle => 'Device Information';

  @override
  String get scenarioNameHint => 'E.g.: \'Morning Light\', \'Vacation Mode\'';

  @override
  String get triggersTitle => 'Triggers';

  @override
  String get conditionsTitle => 'Conditions';

  @override
  String get actionsTitle => 'Actions';

  @override
  String get addActionbutton => 'Add Action';

  @override
  String get scenarioNameCannotBeEmpty => 'Scenario name cannot be empty.';

  @override
  String get scenarioMustHaveAtLeastOneElement =>
      'Scenario must contain at least one trigger, condition, or action.';

  @override
  String get scenarioSavedSuccessfully => 'Scenario saved successfully!';

  @override
  String get scenarioSaveFailed =>
      'Failed to save scenario. Check connection or data.';

  @override
  String get typeLabel => 'Type';

  @override
  String get commandLabel => 'Command (JSON)';

  @override
  String get temperatureSensor => 'Temperature Sensor';

  @override
  String get humiditySensor => 'Humidity Sensor';

  @override
  String get batterySensor => 'Battery Sensor';

  @override
  String get gasSensor => 'Gas Sensor';

  @override
  String get waterSensor => 'Water Sensor';

  @override
  String get motionSensor => 'Motion sensor';

  @override
  String get smokeSensor => 'Smoke sensor';

  @override
  String get hubNumberRetrievalFailed =>
      'Failed to retrieve hub number from the server. Perhaps the hub hasn\'t connected to the internet yet or manual binding is required.';

  @override
  String get hubNumberRetrievalError =>
      'Error retrieving hub number from the server. Please check your internet connection and try again.';

  @override
  String get hubAttachedSuccessfully =>
      'Hub successfully attached to your account!';

  @override
  String hubAttachmentErrorMessage(Object statusCode, Object message) {
    return 'Failed to attach hub: Status Code $statusCode. Message: $message';
  }

  @override
  String get unknownAttachmentError => 'Unknown error during hub attachment.';

  @override
  String hubAttachmentNetworkError(Object errorMessage) {
    return 'Network error during hub attachment: $errorMessage. Please check your internet connection.';
  }

  @override
  String unexpectedAttachmentError(Object errorMessage) {
    return 'An unexpected error occurred during hub attachment: $errorMessage.';
  }

  @override
  String get wifiSetupSuccessNoAttachmentWarning =>
      'Wi-Fi configured successfully, but hub could not be attached. Please attach it later.';

  @override
  String get checkingWifiStatus => 'Checking Wi-Fi status...';

  @override
  String get notConnectedToWifi => 'Not connected to Wi-Fi';

  @override
  String get failedToGetSsid => 'Failed to get SSID';

  @override
  String get hubSuccessfullyAttached =>
      'Hub successfully attached to your account!';

  @override
  String get errorCreatingHubRecord =>
      'Failed to create hub record on the server. Please try again.';

  @override
  String get pleaseSelectHub => 'Please select a hub';

  @override
  String get selectHub => 'Select a Hub';

  @override
  String get selectDevice => 'select Device';

  @override
  String get selectHubLabel => 'selectHubLabel';

  @override
  String get renameHubTitle => 'Rename Hub';

  @override
  String get enterNewNameHint => 'Enter a new name';

  @override
  String get hubRenamedSuccess => 'Hub renamed successfully';

  @override
  String get hubRenamedFailed => 'Failed to rename hub';

  @override
  String get startPairing => 'Start Pairing';

  @override
  String get pairingStartedSuccess => 'Pairing mode started for 25 seconds';

  @override
  String get pairingStartedFailed => 'Failed to start pairing mode';

  @override
  String get voiceAssistantEnabled => 'Voice Assistant Enabled';

  @override
  String get voiceAssistantDisabled => 'Voice Assistant Disabled';

  @override
  String get voiceAssistantSetting => 'Voice Assistant Settings';

  @override
  String get otpConfirmationTitle => 'OTP Confirmation';

  @override
  String get otpSentTo => 'Enter the code sent to';

  @override
  String get otpSent => 'OTP code has been sent';

  @override
  String get otpSendError => 'Error sending OTP code';

  @override
  String get resendOtp => 'Resend code';

  @override
  String get resendOtpAfter => 'Resend code after';

  @override
  String get seconds => 'sec';

  @override
  String get confirm => 'Confirm';

  @override
  String get registrationSuccessful => 'Registration successful!';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get paymentAndCards => 'Payment & Cards';

  @override
  String get myCards => 'My Cards';

  @override
  String get noCards => 'No saved cards found.';

  @override
  String get primaryCard => 'Primary Card';

  @override
  String get makePrimary => 'Make Primary';

  @override
  String get bindNewCard => 'Bind a New Card';

  @override
  String get primaryCardSetSuccess => 'Primary card has been updated';

  @override
  String get primaryCardSetError => 'Error setting primary card';

  @override
  String get receiptNotAvailable => 'Receipt is not available';

  @override
  String get couldNotOpenReceipt => 'Could not open receipt';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String get monthlyFee => 'Monthly Fee';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get editName => 'Edit Name';

  @override
  String get editLastName => 'Edit Last Name';

  @override
  String get noNotifications => 'You have no notifications yet.';

  @override
  String get securityArmed => 'Security system is armed';

  @override
  String get securityDisarmed => 'Security system is disarmed';

  @override
  String get iAmNotHome => 'I\'m Away';

  @override
  String get familyAccess => 'Family Access';

  @override
  String get noFamilyGroups => 'You haven\'t created any family groups yet.';

  @override
  String get createGroup => 'Create Group';

  @override
  String get members => 'Members';

  @override
  String get createNewGroup => 'Create New Group';

  @override
  String get noHubsForSharing => 'No hubs available to share.';

  @override
  String get groupName => 'Group Name';

  @override
  String get memberEmails => 'Member Emails';

  @override
  String get emailsHint => 'Enter emails, separated by commas';

  @override
  String get fieldCannotBeEmpty => 'This field cannot be empty';

  @override
  String get create => 'Create';

  @override
  String get errorCreatingGroup => 'Error creating group';

  @override
  String get changeRole => 'Change Role';

  @override
  String get deleteMember => 'Delete Member';

  @override
  String get noMembersInGroup => 'There are no members in this group yet';

  @override
  String get confirmDeleteMember =>
      'Are you sure you want to remove this member from the group?';

  @override
  String get roleUpdatedSuccess => 'Role updated successfully';

  @override
  String get memberDeletedSuccess => 'Member successfully deleted';

  @override
  String get addNewHub => 'Add New Hub';

  @override
  String get wifiSetupDescription =>
      'First, connect your phone to the hub\'s Wi-Fi (e.g., \'iss-hub-xxxx\'). Then, enter your HOME Wi-Fi credentials below.';

  @override
  String get phoneCurrentWifi => 'Your phone\'s current Wi-Fi';

  @override
  String get homeWifiName => 'Home Wi-Fi Name (SSID)';

  @override
  String get homeWifiNameHint => 'Enter your home network name';

  @override
  String get wifiPassword => 'Wi-Fi Password';

  @override
  String get configureHub => 'Configure Hub';

  @override
  String get connectingToHub => 'Connecting to hub...';

  @override
  String get hubNumberNotFound => 'Hub number not found in hub response';

  @override
  String get sendingWifiCredentials => 'Sending Wi-Fi credentials...';

  @override
  String get waitingForHubConnection =>
      'Waiting for hub to connect to your network...';

  @override
  String get finalizingSetup => 'Finalizing setup...';

  @override
  String get failedToAttachHub => 'Failed to attach hub';

  @override
  String get hubAddedSuccess => 'Hub added successfully!';

  @override
  String get locationTracking => 'Location Tracking';

  @override
  String get scanningForHubs => 'Scanning for hub networks...';

  @override
  String get selectHubNetwork => 'Select your hub\'s network';

  @override
  String get connectingTo => 'Connecting to';

  @override
  String get failedToConnectToHub =>
      'Failed to connect to the hub\'s Wi-Fi. Please try again.';

  @override
  String get hubScanningNetworks => 'Hub is scanning for home networks...';

  @override
  String get scanFailed =>
      'Scanning failed. The hub might not be in setup mode.';

  @override
  String get selectHomeNetwork => 'Select your home Wi-Fi network';

  @override
  String get noNetworksFound => 'No networks found.';

  @override
  String get network => 'Network';

  @override
  String get connect => 'Connect';

  @override
  String get nowConnectToAvailableNetwork =>
      'Now connect your hub to available network';

  @override
  String get connectToHubFirst => 'Connect your phone to hub';

  @override
  String get devicesInRoom => 'Devices in Room';

  @override
  String get addDevice => 'Add Device';

  @override
  String get removeFromRoom => 'Remove from room';

  @override
  String get roomsAndDevices => 'Rooms & Devices';

  @override
  String get myRooms => 'My Rooms';

  @override
  String get noRooms => 'You don\'t have any rooms yet';

  @override
  String get addRoom => 'Add Room';

  @override
  String get unassignedDevices => 'Unassigned Devices';

  @override
  String get editRoom => 'Edit Room';

  @override
  String get selectRoomBackground => 'Select a background for the room';

  @override
  String get roomName => 'Room Name';

  @override
  String get roomNameIsRequired => 'Room name is required';

  @override
  String get changeImage => 'Change Image';

  @override
  String get addImage => 'Add Image';

  @override
  String get assignDevices => 'Assign Devices';

  @override
  String get selectDevicesFor => 'Select devices for';

  @override
  String get noUnassignedDevices => 'No unassigned devices available';

  @override
  String get devicesAssignedSuccess => 'Devices successfully assigned to room';

  @override
  String get devicesTab => 'Devices';

  @override
  String get connectToHubWifiPromptTitle => 'Connect to Hub';

  @override
  String get connectToHubWifiPromptBody =>
      'To continue, go to your phone\'s Wi-Fi settings and connect to the network named:';

  @override
  String get goToWifiSettings => 'Go to Wi-Fi Settings';

  @override
  String get notConnected => 'Not Connected';

  @override
  String get enterPasswordFor => 'Enter password for';

  @override
  String get detachHub => 'Detach Hub';

  @override
  String get detachHubTitle => 'Detach Hub?';

  @override
  String detachHubConfirmation(String hubName) {
    return 'Are you sure you want to detach the hub \'$hubName\'? This action cannot be undone.';
  }

  @override
  String get hubDetachedSuccess => 'Hub detached successfully';

  @override
  String get hubDetachedFailed => 'Failed to detach hub';

  @override
  String get detach => 'Detach';

  @override
  String get serverUnavailableTitle => 'Server is temporarily unavailable';

  @override
  String get serverUnavailableMessage =>
      'We are already aware of the issue and are working to resolve it. Please try to refresh the page.';

  @override
  String get refresh => 'Refresh';

  @override
  String get locationPermissionNeededForWifi =>
      'Location access is required to determine the Wi-Fi network name.';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get errorGettingWifiName => 'Error getting Wi-Fi name';

  @override
  String get assign => 'Assign';

  @override
  String get image => 'Image';

  @override
  String get imageSelected => 'Image selected';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get change => 'Change';

  @override
  String get deleteRoomTitle => 'Delete Room?';

  @override
  String deleteRoomConfirmation(String roomName) {
    return 'Are you sure you want to delete the room \'$roomName\'? All devices in it will become unassigned.';
  }

  @override
  String get noData => 'No data';

  @override
  String get presence => 'Presence';

  @override
  String get edit => 'Edit room';

  @override
  String get addMemberTitle => 'Add Member';

  @override
  String get addMemberButton => 'Add Member';

  @override
  String get role => 'Role';

  @override
  String get userRole => 'User';

  @override
  String get adminRole => 'Admin';

  @override
  String get newSpace => 'New Space';

  @override
  String get searchDevices => 'Search for devices';

  @override
  String get selectAll => 'Select all devices';

  @override
  String get nothingFound => 'No devices found';

  @override
  String get genericSaved => 'Pin code saved';
}

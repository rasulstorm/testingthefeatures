import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ISS.AI'**
  String get appName;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @objectsTab.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get objectsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @profileIcon.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileIcon;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @themeSetting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSetting;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @profileSetting.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSetting;

  /// No description provided for @securitySetting.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySetting;

  /// No description provided for @logoutSetting.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutSetting;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @helpSetting.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpSetting;

  /// No description provided for @aboutAppSetting.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutAppSetting;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @languageKazakh.
  ///
  /// In en, this message translates to:
  /// **'Kazakh'**
  String get languageKazakh;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @myContracts.
  ///
  /// In en, this message translates to:
  /// **'My Contracts'**
  String get myContracts;

  /// No description provided for @noObjects.
  ///
  /// In en, this message translates to:
  /// **'No Objects'**
  String get noObjects;

  /// No description provided for @loadingObjects.
  ///
  /// In en, this message translates to:
  /// **'Loading objects...'**
  String get loadingObjects;

  /// No description provided for @errorLoadingObjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading objects:'**
  String get errorLoadingObjects;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @addHub.
  ///
  /// In en, this message translates to:
  /// **'Add Object'**
  String get addHub;

  /// No description provided for @hubId.
  ///
  /// In en, this message translates to:
  /// **'Object ID'**
  String get hubId;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @hubAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Object added successfully'**
  String get hubAddedSuccessfully;

  /// No description provided for @errorAddingHub.
  ///
  /// In en, this message translates to:
  /// **'Error adding object:'**
  String get errorAddingHub;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update:'**
  String get lastUpdate;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room:'**
  String get room;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group:'**
  String get group;

  /// No description provided for @disarm.
  ///
  /// In en, this message translates to:
  /// **'Disarm'**
  String get disarm;

  /// No description provided for @arm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get arm;

  /// No description provided for @alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// No description provided for @noMessage.
  ///
  /// In en, this message translates to:
  /// **'No message'**
  String get noMessage;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get address;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get status;

  /// No description provided for @devicesOnHub.
  ///
  /// In en, this message translates to:
  /// **'Devices on hub ({count})'**
  String devicesOnHub(Object count);

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found on this hub.'**
  String get noDevicesFound;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @subscriptionNotActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription not active'**
  String get subscriptionNotActive;

  /// No description provided for @bindCard.
  ///
  /// In en, this message translates to:
  /// **'Bind Card'**
  String get bindCard;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount:'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get description;

  /// No description provided for @cardBoundSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Card bound successfully'**
  String get cardBoundSuccessfully;

  /// No description provided for @errorBindingCard.
  ///
  /// In en, this message translates to:
  /// **'Error binding card'**
  String get errorBindingCard;

  /// No description provided for @errorLoadingWebView.
  ///
  /// In en, this message translates to:
  /// **'Error loading WebView'**
  String get errorLoadingWebView;

  /// No description provided for @subscriptionFee.
  ///
  /// In en, this message translates to:
  /// **'Subscription fee:'**
  String get subscriptionFee;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Status: Active'**
  String get statusActive;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @nextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment:'**
  String get nextPayment;

  /// No description provided for @cardBound.
  ///
  /// In en, this message translates to:
  /// **'Card bound'**
  String get cardBound;

  /// No description provided for @errorLoadingCard.
  ///
  /// In en, this message translates to:
  /// **'Error loading card'**
  String get errorLoadingCard;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @iin.
  ///
  /// In en, this message translates to:
  /// **'IIN'**
  String get iin;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @agreePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the privacy policy'**
  String get agreePrivacyPolicy;

  /// No description provided for @acceptPublicOffer.
  ///
  /// In en, this message translates to:
  /// **'I accept the public offer'**
  String get acceptPublicOffer;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @enterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password'**
  String get enterEmailPassword;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccount;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @enterCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {phone}'**
  String enterCodeSentTo(Object phone);

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Confirm code'**
  String get registrationSuccess;

  /// No description provided for @registrationAndLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration and login successful!'**
  String get registrationAndLoginSuccess;

  /// No description provided for @verificationError.
  ///
  /// In en, this message translates to:
  /// **'Verification error'**
  String get verificationError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: No connection'**
  String get networkError;

  /// No description provided for @generalError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred:'**
  String get generalError;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error changing password:'**
  String get errorChangingPassword;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @whatsappCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Code'**
  String get whatsappCodeTitle;

  /// No description provided for @enterPhoneForCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a code via WhatsApp'**
  String get enterPhoneForCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @passwordResetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccessfully;

  /// No description provided for @errorResettingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error resetting password:'**
  String get errorResettingPassword;

  /// No description provided for @aboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUsTitle;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @whatWeOffer.
  ///
  /// In en, this message translates to:
  /// **'What we offer?'**
  String get whatWeOffer;

  /// No description provided for @mainServices.
  ///
  /// In en, this message translates to:
  /// **'Main services:'**
  String get mainServices;

  /// No description provided for @securitySystems.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive security systems: Monitoring, motion sensors, real-time notifications.'**
  String get securitySystems;

  /// No description provided for @smartLighting.
  ///
  /// In en, this message translates to:
  /// **'Smart lighting: Scenario settings, remote control, energy saving.'**
  String get smartLighting;

  /// No description provided for @climateControl.
  ///
  /// In en, this message translates to:
  /// **'Climate control: Automatic temperature adjustment for your comfort.'**
  String get climateControl;

  /// No description provided for @videoSurveillance.
  ///
  /// In en, this message translates to:
  /// **'Video surveillance: Access to cameras anywhere in the world, event recording.'**
  String get videoSurveillance;

  /// No description provided for @smartDeviceIntegration.
  ///
  /// In en, this message translates to:
  /// **'Smart device integration: Support for a wide range of third-party gadgets.'**
  String get smartDeviceIntegration;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Any questions?'**
  String get questions;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions, suggestions, or want to know more about our services, please contact us.'**
  String get contactUs;

  /// No description provided for @failedToOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to open email application'**
  String get failedToOpenEmail;

  /// No description provided for @myContractsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Contracts'**
  String get myContractsTitle;

  /// No description provided for @noActiveContracts.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any active contracts yet.'**
  String get noActiveContracts;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract:'**
  String get contract;

  /// No description provided for @nextPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Next payment:'**
  String get nextPaymentDate;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid:'**
  String get amountPaid;

  /// No description provided for @deleteConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get deleteConfirmationTitle;

  /// No description provided for @deleteConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the account? This action is irreversible.'**
  String get deleteConfirmationMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @errorDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Error deleting account:'**
  String get errorDeletingAccount;

  /// No description provided for @logoutConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get logoutConfirmationTitle;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmationMessage;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknown;

  /// No description provided for @errorLoadingContracts.
  ///
  /// In en, this message translates to:
  /// **'Error loading contracts'**
  String get errorLoadingContracts;

  /// No description provided for @roomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsTitle;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devicesTitle;

  /// No description provided for @noRoomsFound.
  ///
  /// In en, this message translates to:
  /// **'No rooms found. Add rooms to get started!'**
  String get noRoomsFound;

  /// No description provided for @noDevicesInRoom.
  ///
  /// In en, this message translates to:
  /// **'No devices have been added to this room yet.'**
  String get noDevicesInRoom;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @motionDetected.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motionDetected;

  /// No description provided for @noMotion.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get noMotion;

  /// No description provided for @homeOverview.
  ///
  /// In en, this message translates to:
  /// **'Home Overview'**
  String get homeOverview;

  /// No description provided for @yourHome.
  ///
  /// In en, this message translates to:
  /// **'Your Home'**
  String get yourHome;

  /// No description provided for @totalDevices.
  ///
  /// In en, this message translates to:
  /// **'Total devices:'**
  String get totalDevices;

  /// No description provided for @activeDevices.
  ///
  /// In en, this message translates to:
  /// **'Active devices:'**
  String get activeDevices;

  /// No description provided for @totalRooms.
  ///
  /// In en, this message translates to:
  /// **'Total rooms:'**
  String get totalRooms;

  /// No description provided for @favoriteDevices.
  ///
  /// In en, this message translates to:
  /// **'Favorite Devices'**
  String get favoriteDevices;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @iAmHome.
  ///
  /// In en, this message translates to:
  /// **'I am Home'**
  String get iAmHome;

  /// No description provided for @officeShort.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get officeShort;

  /// No description provided for @doorClosedShort.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get doorClosedShort;

  /// No description provided for @doorNoun.
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get doorNoun;

  /// No description provided for @noResponse.
  ///
  /// In en, this message translates to:
  /// **'No Response'**
  String get noResponse;

  /// No description provided for @chandelier.
  ///
  /// In en, this message translates to:
  /// **'Chandelier'**
  String get chandelier;

  /// No description provided for @topLight.
  ///
  /// In en, this message translates to:
  /// **'Top Light'**
  String get topLight;

  /// No description provided for @noPower.
  ///
  /// In en, this message translates to:
  /// **'No Power'**
  String get noPower;

  /// No description provided for @noWater.
  ///
  /// In en, this message translates to:
  /// **'No Water'**
  String get noWater;

  /// No description provided for @tempShort.
  ///
  /// In en, this message translates to:
  /// **'Temp.'**
  String get tempShort;

  /// No description provided for @humidityShort.
  ///
  /// In en, this message translates to:
  /// **'Humid.'**
  String get humidityShort;

  /// No description provided for @lightShort.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightShort;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @livingRoom.
  ///
  /// In en, this message translates to:
  /// **'Living Room'**
  String get livingRoom;

  /// No description provided for @kitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get kitchen;

  /// No description provided for @errorLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error loading image'**
  String get errorLoadingImage;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noHubsFound.
  ///
  /// In en, this message translates to:
  /// **'No hubs found'**
  String get noHubsFound;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @noControlAvailable.
  ///
  /// In en, this message translates to:
  /// **'Control unavailable'**
  String get noControlAvailable;

  /// No description provided for @connectionActive.
  ///
  /// In en, this message translates to:
  /// **'Connection Active'**
  String get connectionActive;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection Lost'**
  String get connectionLost;

  /// No description provided for @homeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get homeScreenTitle;

  /// No description provided for @noHubsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No available objects. Please add an object to get started.'**
  String get noHubsAvailable;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @commandHubId.
  ///
  /// In en, this message translates to:
  /// **'Command Hub ID'**
  String get commandHubId;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found for this hub.'**
  String get noDevices;

  /// No description provided for @errorLoadingHubs.
  ///
  /// In en, this message translates to:
  /// **'Error loading hubs'**
  String get errorLoadingHubs;

  /// No description provided for @switchAll.
  ///
  /// In en, this message translates to:
  /// **'Switch All'**
  String get switchAll;

  /// No description provided for @powerOffAll.
  ///
  /// In en, this message translates to:
  /// **'Power Off All'**
  String get powerOffAll;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noDataAvailable;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @lightLevel.
  ///
  /// In en, this message translates to:
  /// **'Light Level'**
  String get lightLevel;

  /// No description provided for @occupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get occupancy;

  /// No description provided for @detected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get detected;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @batteryStatus.
  ///
  /// In en, this message translates to:
  /// **'Battery Status'**
  String get batteryStatus;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @tamper.
  ///
  /// In en, this message translates to:
  /// **'Tamper'**
  String get tamper;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @controllableDevices.
  ///
  /// In en, this message translates to:
  /// **'Controllable Devices'**
  String get controllableDevices;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @switchAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'All devices switched.'**
  String get switchAllSuccess;

  /// No description provided for @powerOffAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'All devices powered off.'**
  String get powerOffAllSuccess;

  /// No description provided for @noControllableDevices.
  ///
  /// In en, this message translates to:
  /// **'No controllable devices found.'**
  String get noControllableDevices;

  /// No description provided for @dimmer.
  ///
  /// In en, this message translates to:
  /// **'Dimmer'**
  String get dimmer;

  /// No description provided for @switchDevice.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchDevice;

  /// No description provided for @blinds.
  ///
  /// In en, this message translates to:
  /// **'Blinds'**
  String get blinds;

  /// No description provided for @blindsControlTip.
  ///
  /// In en, this message translates to:
  /// **'Use buttons to control blinds (Open/Stop/Close)'**
  String get blindsControlTip;

  /// No description provided for @statusIndicators.
  ///
  /// In en, this message translates to:
  /// **'Status Indicators'**
  String get statusIndicators;

  /// No description provided for @gasDetected.
  ///
  /// In en, this message translates to:
  /// **'Gas Detected'**
  String get gasDetected;

  /// No description provided for @smokeDetected.
  ///
  /// In en, this message translates to:
  /// **'Smoke Detected'**
  String get smokeDetected;

  /// No description provided for @waterLeak.
  ///
  /// In en, this message translates to:
  /// **'Water Leak'**
  String get waterLeak;

  /// No description provided for @moving.
  ///
  /// In en, this message translates to:
  /// **'motion detected'**
  String get moving;

  /// No description provided for @subscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Subscription Status'**
  String get subscriptionStatus;

  /// No description provided for @cardIsBound.
  ///
  /// In en, this message translates to:
  /// **'Card is Bound'**
  String get cardIsBound;

  /// No description provided for @totalContractAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Contract Amount'**
  String get totalContractAmount;

  /// No description provided for @nextCharge.
  ///
  /// In en, this message translates to:
  /// **'Next Charge'**
  String get nextCharge;

  /// No description provided for @errorLoadingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscription'**
  String get errorLoadingSubscription;

  /// No description provided for @errorLoadingPayments.
  ///
  /// In en, this message translates to:
  /// **'Error loading payments'**
  String get errorLoadingPayments;

  /// No description provided for @errorLoadingCardInfo.
  ///
  /// In en, this message translates to:
  /// **'Error loading card info'**
  String get errorLoadingCardInfo;

  /// No description provided for @errorLoadingBindForm.
  ///
  /// In en, this message translates to:
  /// **'Error loading bind form'**
  String get errorLoadingBindForm;

  /// No description provided for @noPaymentRecords.
  ///
  /// In en, this message translates to:
  /// **'No payment records'**
  String get noPaymentRecords;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @notAttached.
  ///
  /// In en, this message translates to:
  /// **'Not Attached'**
  String get notAttached;

  /// No description provided for @scenariosTab.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get scenariosTab;

  /// No description provided for @scenariosEmptyList.
  ///
  /// In en, this message translates to:
  /// **'Scenario list is empty.'**
  String get scenariosEmptyList;

  /// No description provided for @scenariosCreatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Create your first scenario!'**
  String get scenariosCreatePrompt;

  /// No description provided for @createScenarioButton.
  ///
  /// In en, this message translates to:
  /// **'Create New Scenario'**
  String get createScenarioButton;

  /// No description provided for @createScenarioNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Navigate to new scenario creation (not implemented yet)'**
  String get createScenarioNotImplemented;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailPlaceholder;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordPlaceholder;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @registerHere.
  ///
  /// In en, this message translates to:
  /// **'Register here'**
  String get registerHere;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current Language: {language}'**
  String currentLanguage(Object language);

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account successfully deleted.'**
  String get accountDeletedSuccess;

  /// No description provided for @accountDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting account'**
  String get accountDeleteError;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @createScenarioTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Scenario'**
  String get createScenarioTitle;

  /// No description provided for @editScenarioTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Scenario'**
  String get editScenarioTitle;

  /// No description provided for @scenarioGeneralSettings.
  ///
  /// In en, this message translates to:
  /// **'Scenario General Settings'**
  String get scenarioGeneralSettings;

  /// No description provided for @scenarioNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Scenario Name'**
  String get scenarioNameLabel;

  /// No description provided for @scenarioNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Scenario name is required'**
  String get scenarioNameRequired;

  /// No description provided for @scenarioEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Scenario Enabled'**
  String get scenarioEnabledLabel;

  /// No description provided for @scenarioTriggers.
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get scenarioTriggers;

  /// No description provided for @addTriggerButton.
  ///
  /// In en, this message translates to:
  /// **'Add Trigger'**
  String get addTriggerButton;

  /// No description provided for @scenarioConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get scenarioConditions;

  /// No description provided for @addConditionButton.
  ///
  /// In en, this message translates to:
  /// **'Add Condition'**
  String get addConditionButton;

  /// No description provided for @scenarioActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get scenarioActions;

  /// No description provided for @addActionBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Action'**
  String get addActionBtn;

  /// No description provided for @saveScenarioButton.
  ///
  /// In en, this message translates to:
  /// **'Save Scenario'**
  String get saveScenarioButton;

  /// No description provided for @deviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceNameLabel;

  /// No description provided for @attributeLabel.
  ///
  /// In en, this message translates to:
  /// **'Attribute'**
  String get attributeLabel;

  /// No description provided for @operatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operatorLabel;

  /// No description provided for @valueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// No description provided for @commandJsonLabel.
  ///
  /// In en, this message translates to:
  /// **'Command JSON'**
  String get commandJsonLabel;

  /// No description provided for @triggerLabel.
  ///
  /// In en, this message translates to:
  /// **'Trigger {number}'**
  String triggerLabel(int number);

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition {number}'**
  String conditionLabel(int number);

  /// No description provided for @actionLabel.
  ///
  /// In en, this message translates to:
  /// **'Action {number}'**
  String actionLabel(int number);

  /// No description provided for @scenariosListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scenarios here yet.'**
  String get scenariosListEmpty;

  /// No description provided for @createFirstScenarioPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create your first scenario to automate smart home management.'**
  String get createFirstScenarioPrompt;

  /// No description provided for @createNewScenarioButton.
  ///
  /// In en, this message translates to:
  /// **'Create New Scenario'**
  String get createNewScenarioButton;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @setupWifi.
  ///
  /// In en, this message translates to:
  /// **'Setup Wifi'**
  String get setupWifi;

  /// No description provided for @wifiSetupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Setup'**
  String get wifiSetupScreenTitle;

  /// No description provided for @wifiSetupInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your Wi-Fi network details to connect the hub.'**
  String get wifiSetupInstructions;

  /// No description provided for @currentWifiNetwork.
  ///
  /// In en, this message translates to:
  /// **'Current Wi-Fi Network: {ssid}'**
  String currentWifiNetwork(Object ssid);

  /// No description provided for @wifiNetworkNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Network Name (SSID)'**
  String get wifiNetworkNameLabel;

  /// No description provided for @wifiNetworkNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., MyHomeNetwork'**
  String get wifiNetworkNameHint;

  /// No description provided for @ssidRequiredError.
  ///
  /// In en, this message translates to:
  /// **'SSID cannot be empty.'**
  String get ssidRequiredError;

  /// No description provided for @wifiPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Password'**
  String get wifiPasswordLabel;

  /// No description provided for @wifiPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your home Wi-Fi password'**
  String get wifiPasswordHint;

  /// No description provided for @configureWifiButton.
  ///
  /// In en, this message translates to:
  /// **'Configure Wi-Fi'**
  String get configureWifiButton;

  /// No description provided for @wifiSetupSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi setup successful! Hub is connecting to your network.'**
  String get wifiSetupSuccessMessage;

  /// No description provided for @wifiSetupErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to set up Wi-Fi. Error code: {statusCode}. Message: {message}'**
  String wifiSetupErrorMessage(Object statusCode, Object message);

  /// No description provided for @unknownErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred. Please check SSID and password correctness.'**
  String get unknownErrorMessage;

  /// No description provided for @hubConnectionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the hub. Please ensure your device is connected to the hub\'s Wi-Fi access point (usually starts with \"ISS-Hub-\") and try again.'**
  String get hubConnectionErrorMessage;

  /// No description provided for @serverErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Server error ({statusCode}): {message}'**
  String serverErrorMessage(Object statusCode, Object message);

  /// No description provided for @checkWifiDataError.
  ///
  /// In en, this message translates to:
  /// **'Please check Wi-Fi credentials.'**
  String get checkWifiDataError;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'A network error occurred: {message}. Please check your internet connection.'**
  String networkErrorMessage(Object message);

  /// No description provided for @unknownNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unknown network error'**
  String get unknownNetworkError;

  /// No description provided for @getString.
  ///
  /// In en, this message translates to:
  /// **'No Face ID login for this account'**
  String get getString;

  /// No description provided for @unexpectedErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {errorMessage}. Please try again.'**
  String unexpectedErrorMessage(Object errorMessage);

  /// No description provided for @createPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create PIN code'**
  String get createPinTitle;

  /// No description provided for @createPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 4-digit PIN code for quick authorization.'**
  String get createPinDescription;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN code'**
  String get confirmPinTitle;

  /// No description provided for @confirmPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter your 4-digit PIN code.'**
  String get confirmPinDescription;

  /// No description provided for @enterPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN code'**
  String get enterPinTitle;

  /// No description provided for @enterPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter your 4-digit PIN code.'**
  String get enterPinDescription;

  /// No description provided for @changeOldPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN code'**
  String get changeOldPinTitle;

  /// No description provided for @enterOldPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter old PIN code'**
  String get enterOldPinTitle;

  /// No description provided for @enterOldPinDescription.
  ///
  /// In en, this message translates to:
  /// **'To change your PIN code, please enter your current PIN code.'**
  String get enterOldPinDescription;

  /// No description provided for @createNewPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new PIN code'**
  String get createNewPinTitle;

  /// No description provided for @createNewPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new 4-digit PIN code.'**
  String get createNewPinDescription;

  /// No description provided for @confirmNewPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN code'**
  String get confirmNewPinTitle;

  /// No description provided for @confirmNewPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter your new 4-digit PIN code.'**
  String get confirmNewPinDescription;

  /// No description provided for @pinSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN code successfully set.'**
  String get pinSetSuccess;

  /// No description provided for @pinChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN code successfully changed.'**
  String get pinChangedSuccess;

  /// No description provided for @pinVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN code successfully verified.'**
  String get pinVerifiedSuccess;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PIN codes do not match. Please try again.'**
  String get pinMismatch;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN code.'**
  String get incorrectPin;

  /// No description provided for @attemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{attempts, plural, one{You have # attempt remaining.} other{You have # attempts remaining.}}'**
  String attemptsRemaining(int attempts);

  /// No description provided for @pinLockedOut.
  ///
  /// In en, this message translates to:
  /// **'PIN code locked. Too many failed attempts.'**
  String get pinLockedOut;

  /// No description provided for @pinLockedOutRedirect.
  ///
  /// In en, this message translates to:
  /// **'PIN code locked. Please log in with your username and password.'**
  String get pinLockedOutRedirect;

  /// No description provided for @loginWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Log in with password'**
  String get loginWithPassword;

  /// No description provided for @localAuthSetting.
  ///
  /// In en, this message translates to:
  /// **'Face ID / PIN code login'**
  String get localAuthSetting;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @useBiometricsOnly.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID only (if available)'**
  String get useBiometricsOnly;

  /// No description provided for @biometricsOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Login will be via Face ID only. PIN code will be disabled.'**
  String get biometricsOnlyDescription;

  /// No description provided for @biometricsAndPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Login will be via Face ID or PIN code as a fallback.'**
  String get biometricsAndPinDescription;

  /// No description provided for @authReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity to enter the application'**
  String get authReason;

  /// No description provided for @authFailedLocalAuthNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable local authentication.'**
  String get authFailedLocalAuthNotEnabled;

  /// No description provided for @authFailedBiometricsPinNotFound.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed, or PIN code not set/unavailable.'**
  String get authFailedBiometricsPinNotFound;

  /// No description provided for @sessionExpiredLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Session Expired. Please login again.'**
  String get sessionExpiredLoginAgain;

  /// No description provided for @localAuthFailedLoginWithCredentials.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please login with username/password.'**
  String get localAuthFailedLoginWithCredentials;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please log in with username/password.'**
  String get authFailed;

  /// No description provided for @setupPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up PIN code'**
  String get setupPinTitle;

  /// No description provided for @setupPinDescription.
  ///
  /// In en, this message translates to:
  /// **'You can set up a PIN code for quick access to the application.'**
  String get setupPinDescription;

  /// No description provided for @setupPinButton.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setupPinButton;

  /// No description provided for @faceIdPinSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Face ID / PIN Login'**
  String get faceIdPinSettingTitle;

  /// No description provided for @localAuthNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on your device or not configured.'**
  String get localAuthNotAvailable;

  /// No description provided for @localAuthEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Face ID/PIN login enabled.'**
  String get localAuthEnabledMessage;

  /// No description provided for @localAuthNotEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Face ID/PIN login not enabled.'**
  String get localAuthNotEnabledMessage;

  /// No description provided for @localAuthDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Face ID/PIN login disabled.'**
  String get localAuthDisabledMessage;

  /// No description provided for @loadingApp.
  ///
  /// In en, this message translates to:
  /// **'Loading application...'**
  String get loadingApp;

  /// No description provided for @incorrectOldPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect old Pincode'**
  String get incorrectOldPin;

  /// No description provided for @dimmerControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Dimmer control {deviceName}'**
  String dimmerControlTitle(Object deviceName);

  /// No description provided for @deviceControlModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Control: {deviceType} ({deviceName})'**
  String deviceControlModalTitle(Object deviceType, Object deviceName);

  /// No description provided for @switchingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Switching History'**
  String get switchingHistoryTitle;

  /// No description provided for @switchingHistoryUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Switching history is under development.'**
  String get switchingHistoryUnderDevelopment;

  /// No description provided for @deviceInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get deviceInfoTitle;

  /// No description provided for @scenarioNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: \'Morning Light\', \'Vacation Mode\''**
  String get scenarioNameHint;

  /// No description provided for @triggersTitle.
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get triggersTitle;

  /// No description provided for @conditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditionsTitle;

  /// No description provided for @actionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTitle;

  /// No description provided for @addActionbutton.
  ///
  /// In en, this message translates to:
  /// **'Add Action'**
  String get addActionbutton;

  /// No description provided for @scenarioNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Scenario name cannot be empty.'**
  String get scenarioNameCannotBeEmpty;

  /// No description provided for @scenarioMustHaveAtLeastOneElement.
  ///
  /// In en, this message translates to:
  /// **'Scenario must contain at least one trigger, condition, or action.'**
  String get scenarioMustHaveAtLeastOneElement;

  /// No description provided for @scenarioSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Scenario saved successfully!'**
  String get scenarioSavedSuccessfully;

  /// No description provided for @scenarioSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save scenario. Check connection or data.'**
  String get scenarioSaveFailed;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @commandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command (JSON)'**
  String get commandLabel;

  /// No description provided for @temperatureSensor.
  ///
  /// In en, this message translates to:
  /// **'Temperature Sensor'**
  String get temperatureSensor;

  /// No description provided for @humiditySensor.
  ///
  /// In en, this message translates to:
  /// **'Humidity Sensor'**
  String get humiditySensor;

  /// No description provided for @batterySensor.
  ///
  /// In en, this message translates to:
  /// **'Battery Sensor'**
  String get batterySensor;

  /// No description provided for @gasSensor.
  ///
  /// In en, this message translates to:
  /// **'Gas Sensor'**
  String get gasSensor;

  /// No description provided for @waterSensor.
  ///
  /// In en, this message translates to:
  /// **'Water Sensor'**
  String get waterSensor;

  /// No description provided for @motionSensor.
  ///
  /// In en, this message translates to:
  /// **'Motion sensor'**
  String get motionSensor;

  /// No description provided for @smokeSensor.
  ///
  /// In en, this message translates to:
  /// **'Smoke sensor'**
  String get smokeSensor;

  /// No description provided for @hubNumberRetrievalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve hub number from the server. Perhaps the hub hasn\'t connected to the internet yet or manual binding is required.'**
  String get hubNumberRetrievalFailed;

  /// No description provided for @hubNumberRetrievalError.
  ///
  /// In en, this message translates to:
  /// **'Error retrieving hub number from the server. Please check your internet connection and try again.'**
  String get hubNumberRetrievalError;

  /// No description provided for @hubAttachedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Hub successfully attached to your account!'**
  String get hubAttachedSuccessfully;

  /// No description provided for @hubAttachmentErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to attach hub: Status Code {statusCode}. Message: {message}'**
  String hubAttachmentErrorMessage(Object statusCode, Object message);

  /// No description provided for @unknownAttachmentError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error during hub attachment.'**
  String get unknownAttachmentError;

  /// No description provided for @hubAttachmentNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error during hub attachment: {errorMessage}. Please check your internet connection.'**
  String hubAttachmentNetworkError(Object errorMessage);

  /// No description provided for @unexpectedAttachmentError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred during hub attachment: {errorMessage}.'**
  String unexpectedAttachmentError(Object errorMessage);

  /// No description provided for @wifiSetupSuccessNoAttachmentWarning.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi configured successfully, but hub could not be attached. Please attach it later.'**
  String get wifiSetupSuccessNoAttachmentWarning;

  /// No description provided for @checkingWifiStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking Wi-Fi status...'**
  String get checkingWifiStatus;

  /// No description provided for @notConnectedToWifi.
  ///
  /// In en, this message translates to:
  /// **'Not connected to Wi-Fi'**
  String get notConnectedToWifi;

  /// No description provided for @failedToGetSsid.
  ///
  /// In en, this message translates to:
  /// **'Failed to get SSID'**
  String get failedToGetSsid;

  /// No description provided for @hubSuccessfullyAttached.
  ///
  /// In en, this message translates to:
  /// **'Hub successfully attached to your account!'**
  String get hubSuccessfullyAttached;

  /// No description provided for @errorCreatingHubRecord.
  ///
  /// In en, this message translates to:
  /// **'Failed to create hub record on the server. Please try again.'**
  String get errorCreatingHubRecord;

  /// No description provided for @pleaseSelectHub.
  ///
  /// In en, this message translates to:
  /// **'Please select a hub'**
  String get pleaseSelectHub;

  /// No description provided for @selectHub.
  ///
  /// In en, this message translates to:
  /// **'Select a Hub'**
  String get selectHub;

  /// No description provided for @selectDevice.
  ///
  /// In en, this message translates to:
  /// **'select Device'**
  String get selectDevice;

  /// No description provided for @selectHubLabel.
  ///
  /// In en, this message translates to:
  /// **'selectHubLabel'**
  String get selectHubLabel;

  /// No description provided for @renameHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Hub'**
  String get renameHubTitle;

  /// No description provided for @enterNewNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new name'**
  String get enterNewNameHint;

  /// No description provided for @hubRenamedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hub renamed successfully'**
  String get hubRenamedSuccess;

  /// No description provided for @hubRenamedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename hub'**
  String get hubRenamedFailed;

  /// No description provided for @startPairing.
  ///
  /// In en, this message translates to:
  /// **'Start Pairing'**
  String get startPairing;

  /// No description provided for @pairingStartedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pairing mode started for 25 seconds'**
  String get pairingStartedSuccess;

  /// No description provided for @pairingStartedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start pairing mode'**
  String get pairingStartedFailed;

  /// No description provided for @voiceAssistantEnabled.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant Enabled'**
  String get voiceAssistantEnabled;

  /// No description provided for @voiceAssistantDisabled.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant Disabled'**
  String get voiceAssistantDisabled;

  /// No description provided for @voiceAssistantSetting.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant Settings'**
  String get voiceAssistantSetting;

  /// No description provided for @otpConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP Confirmation'**
  String get otpConfirmationTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get otpSentTo;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP code has been sent'**
  String get otpSent;

  /// No description provided for @otpSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending OTP code'**
  String get otpSendError;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendOtp;

  /// No description provided for @resendOtpAfter.
  ///
  /// In en, this message translates to:
  /// **'Resend code after'**
  String get resendOtpAfter;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get seconds;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @paymentAndCards.
  ///
  /// In en, this message translates to:
  /// **'Payment & Cards'**
  String get paymentAndCards;

  /// No description provided for @myCards.
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get myCards;

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'No saved cards found.'**
  String get noCards;

  /// No description provided for @primaryCard.
  ///
  /// In en, this message translates to:
  /// **'Primary Card'**
  String get primaryCard;

  /// No description provided for @makePrimary.
  ///
  /// In en, this message translates to:
  /// **'Make Primary'**
  String get makePrimary;

  /// No description provided for @bindNewCard.
  ///
  /// In en, this message translates to:
  /// **'Bind a New Card'**
  String get bindNewCard;

  /// No description provided for @primaryCardSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Primary card has been updated'**
  String get primaryCardSetSuccess;

  /// No description provided for @primaryCardSetError.
  ///
  /// In en, this message translates to:
  /// **'Error setting primary card'**
  String get primaryCardSetError;

  /// No description provided for @receiptNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Receipt is not available'**
  String get receiptNotAvailable;

  /// No description provided for @couldNotOpenReceipt.
  ///
  /// In en, this message translates to:
  /// **'Could not open receipt'**
  String get couldNotOpenReceipt;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @monthlyFee.
  ///
  /// In en, this message translates to:
  /// **'Monthly Fee'**
  String get monthlyFee;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @editLastName.
  ///
  /// In en, this message translates to:
  /// **'Edit Last Name'**
  String get editLastName;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications yet.'**
  String get noNotifications;

  /// No description provided for @securityArmed.
  ///
  /// In en, this message translates to:
  /// **'Security system is armed'**
  String get securityArmed;

  /// No description provided for @securityDisarmed.
  ///
  /// In en, this message translates to:
  /// **'Security system is disarmed'**
  String get securityDisarmed;

  /// No description provided for @iAmNotHome.
  ///
  /// In en, this message translates to:
  /// **'I\'m Away'**
  String get iAmNotHome;

  /// No description provided for @familyAccess.
  ///
  /// In en, this message translates to:
  /// **'Family Access'**
  String get familyAccess;

  /// No description provided for @noFamilyGroups.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any family groups yet.'**
  String get noFamilyGroups;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @createNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get createNewGroup;

  /// No description provided for @noHubsForSharing.
  ///
  /// In en, this message translates to:
  /// **'No hubs available to share.'**
  String get noHubsForSharing;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @memberEmails.
  ///
  /// In en, this message translates to:
  /// **'Member Emails'**
  String get memberEmails;

  /// No description provided for @emailsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter emails, separated by commas'**
  String get emailsHint;

  /// No description provided for @fieldCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty'**
  String get fieldCannotBeEmpty;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @errorCreatingGroup.
  ///
  /// In en, this message translates to:
  /// **'Error creating group'**
  String get errorCreatingGroup;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @deleteMember.
  ///
  /// In en, this message translates to:
  /// **'Delete Member'**
  String get deleteMember;

  /// No description provided for @noMembersInGroup.
  ///
  /// In en, this message translates to:
  /// **'There are no members in this group yet'**
  String get noMembersInGroup;

  /// No description provided for @confirmDeleteMember.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member from the group?'**
  String get confirmDeleteMember;

  /// No description provided for @roleUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get roleUpdatedSuccess;

  /// No description provided for @memberDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member successfully deleted'**
  String get memberDeletedSuccess;

  /// No description provided for @addNewHub.
  ///
  /// In en, this message translates to:
  /// **'Add New Hub'**
  String get addNewHub;

  /// No description provided for @wifiSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'First, connect your phone to the hub\'s Wi-Fi (e.g., \'iss-hub-xxxx\'). Then, enter your HOME Wi-Fi credentials below.'**
  String get wifiSetupDescription;

  /// No description provided for @phoneCurrentWifi.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s current Wi-Fi'**
  String get phoneCurrentWifi;

  /// No description provided for @homeWifiName.
  ///
  /// In en, this message translates to:
  /// **'Home Wi-Fi Name (SSID)'**
  String get homeWifiName;

  /// No description provided for @homeWifiNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your home network name'**
  String get homeWifiNameHint;

  /// No description provided for @wifiPassword.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Password'**
  String get wifiPassword;

  /// No description provided for @configureHub.
  ///
  /// In en, this message translates to:
  /// **'Configure Hub'**
  String get configureHub;

  /// No description provided for @connectingToHub.
  ///
  /// In en, this message translates to:
  /// **'Connecting to hub...'**
  String get connectingToHub;

  /// No description provided for @hubNumberNotFound.
  ///
  /// In en, this message translates to:
  /// **'Hub number not found in hub response'**
  String get hubNumberNotFound;

  /// No description provided for @sendingWifiCredentials.
  ///
  /// In en, this message translates to:
  /// **'Sending Wi-Fi credentials...'**
  String get sendingWifiCredentials;

  /// No description provided for @waitingForHubConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for hub to connect to your network...'**
  String get waitingForHubConnection;

  /// No description provided for @finalizingSetup.
  ///
  /// In en, this message translates to:
  /// **'Finalizing setup...'**
  String get finalizingSetup;

  /// No description provided for @failedToAttachHub.
  ///
  /// In en, this message translates to:
  /// **'Failed to attach hub'**
  String get failedToAttachHub;

  /// No description provided for @hubAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hub added successfully!'**
  String get hubAddedSuccess;

  /// No description provided for @locationTracking.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTracking;

  /// No description provided for @scanningForHubs.
  ///
  /// In en, this message translates to:
  /// **'Scanning for hub networks...'**
  String get scanningForHubs;

  /// No description provided for @selectHubNetwork.
  ///
  /// In en, this message translates to:
  /// **'Select your hub\'s network'**
  String get selectHubNetwork;

  /// No description provided for @connectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to'**
  String get connectingTo;

  /// No description provided for @failedToConnectToHub.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the hub\'s Wi-Fi. Please try again.'**
  String get failedToConnectToHub;

  /// No description provided for @hubScanningNetworks.
  ///
  /// In en, this message translates to:
  /// **'Hub is scanning for home networks...'**
  String get hubScanningNetworks;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scanning failed. The hub might not be in setup mode.'**
  String get scanFailed;

  /// No description provided for @selectHomeNetwork.
  ///
  /// In en, this message translates to:
  /// **'Select your home Wi-Fi network'**
  String get selectHomeNetwork;

  /// No description provided for @noNetworksFound.
  ///
  /// In en, this message translates to:
  /// **'No networks found.'**
  String get noNetworksFound;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @nowConnectToAvailableNetwork.
  ///
  /// In en, this message translates to:
  /// **'Now connect your hub to available network'**
  String get nowConnectToAvailableNetwork;

  /// No description provided for @connectToHubFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect your phone to hub'**
  String get connectToHubFirst;

  /// No description provided for @devicesInRoom.
  ///
  /// In en, this message translates to:
  /// **'Devices in Room'**
  String get devicesInRoom;

  /// No description provided for @addDevice.
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDevice;

  /// No description provided for @removeFromRoom.
  ///
  /// In en, this message translates to:
  /// **'Remove from room'**
  String get removeFromRoom;

  /// No description provided for @roomsAndDevices.
  ///
  /// In en, this message translates to:
  /// **'Rooms & Devices'**
  String get roomsAndDevices;

  /// No description provided for @myRooms.
  ///
  /// In en, this message translates to:
  /// **'My Rooms'**
  String get myRooms;

  /// No description provided for @noRooms.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any rooms yet'**
  String get noRooms;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// No description provided for @unassignedDevices.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Devices'**
  String get unassignedDevices;

  /// No description provided for @editRoom.
  ///
  /// In en, this message translates to:
  /// **'Edit Room'**
  String get editRoom;

  /// No description provided for @selectRoomBackground.
  ///
  /// In en, this message translates to:
  /// **'Select a background for the room'**
  String get selectRoomBackground;

  /// No description provided for @roomName.
  ///
  /// In en, this message translates to:
  /// **'Room Name'**
  String get roomName;

  /// No description provided for @roomNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Room name is required'**
  String get roomNameIsRequired;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @assignDevices.
  ///
  /// In en, this message translates to:
  /// **'Assign Devices'**
  String get assignDevices;

  /// No description provided for @selectDevicesFor.
  ///
  /// In en, this message translates to:
  /// **'Select devices for'**
  String get selectDevicesFor;

  /// No description provided for @noUnassignedDevices.
  ///
  /// In en, this message translates to:
  /// **'No unassigned devices available'**
  String get noUnassignedDevices;

  /// No description provided for @devicesAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Devices successfully assigned to room'**
  String get devicesAssignedSuccess;

  /// No description provided for @devicesTab.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devicesTab;

  /// No description provided for @connectToHubWifiPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Hub'**
  String get connectToHubWifiPromptTitle;

  /// No description provided for @connectToHubWifiPromptBody.
  ///
  /// In en, this message translates to:
  /// **'To continue, go to your phone\'s Wi-Fi settings and connect to the network named:'**
  String get connectToHubWifiPromptBody;

  /// No description provided for @goToWifiSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Wi-Fi Settings'**
  String get goToWifiSettings;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @enterPasswordFor.
  ///
  /// In en, this message translates to:
  /// **'Enter password for'**
  String get enterPasswordFor;

  /// No description provided for @detachHub.
  ///
  /// In en, this message translates to:
  /// **'Detach Hub'**
  String get detachHub;

  /// No description provided for @detachHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Detach Hub?'**
  String get detachHubTitle;

  /// Confirmation message for detaching a hub.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to detach the hub \'{hubName}\'? This action cannot be undone.'**
  String detachHubConfirmation(String hubName);

  /// No description provided for @hubDetachedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hub detached successfully'**
  String get hubDetachedSuccess;

  /// No description provided for @hubDetachedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to detach hub'**
  String get hubDetachedFailed;

  /// No description provided for @detach.
  ///
  /// In en, this message translates to:
  /// **'Detach'**
  String get detach;

  /// No description provided for @serverUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Server is temporarily unavailable'**
  String get serverUnavailableTitle;

  /// No description provided for @serverUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We are already aware of the issue and are working to resolve it. Please try to refresh the page.'**
  String get serverUnavailableMessage;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @locationPermissionNeededForWifi.
  ///
  /// In en, this message translates to:
  /// **'Location access is required to determine the Wi-Fi network name.'**
  String get locationPermissionNeededForWifi;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @errorGettingWifiName.
  ///
  /// In en, this message translates to:
  /// **'Error getting Wi-Fi name'**
  String get errorGettingWifiName;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get imageSelected;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @deleteRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Room?'**
  String get deleteRoomTitle;

  /// No description provided for @deleteRoomConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the room \'{roomName}\'? All devices in it will become unassigned.'**
  String deleteRoomConfirmation(String roomName);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @presence.
  ///
  /// In en, this message translates to:
  /// **'Presence'**
  String get presence;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit room'**
  String get edit;

  /// No description provided for @addMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberTitle;

  /// No description provided for @addMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberButton;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @userRole.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userRole;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @newSpace.
  ///
  /// In en, this message translates to:
  /// **'New Space'**
  String get newSpace;

  /// No description provided for @searchDevices.
  ///
  /// In en, this message translates to:
  /// **'Search for devices'**
  String get searchDevices;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all devices'**
  String get selectAll;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get nothingFound;

  /// No description provided for @genericSaved.
  ///
  /// In en, this message translates to:
  /// **'Pin code saved'**
  String get genericSaved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

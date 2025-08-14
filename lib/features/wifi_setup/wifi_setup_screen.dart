// lib/features/wifi_setup/wifi_setup_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:developer' as dev;
import 'package:ISS/l10n/app_localizations.dart';

class WifiSetupScreen extends ConsumerStatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  ConsumerState<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends ConsumerState<WifiSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _statusMessage = '';
  String? _foundHubNumber;
  String _debugLog = '';
  String _currentPhoneSsid = '...';

  @override
  void initState() {
    super.initState();
    _loadCurrentWifiSsid();
  }

  void _appendDebugLog(String message) {
    if (!mounted) return;
    setState(() {
      final time = DateTime.now()
          .toIso8601String()
          .split('T')[1]
          .substring(0, 8);
      _debugLog += '$time: $message\n';
      dev.log('[$time] $message');
    });
  }

  Future<void> _loadCurrentWifiSsid() async {
    try {
      final wifiName = await NetworkInfo().getWifiName();
      if (mounted) {
        setState(() {
          _currentPhoneSsid = wifiName?.replaceAll('"', '') ?? 'Not Connected';
        });
      }
    } catch (e) {
      _appendDebugLog('INIT: Error getting phone SSID: $e');
      if (mounted) setState(() => _currentPhoneSsid = 'Error');
    }
  }

  // УДАЛЕНО: Метод _pollHubStatus больше не нужен

  Future<void> _connectWifi() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _errorMessage = '';
      _statusMessage = '';
      _debugLog = 'SETUP START: Initiating Wi-Fi setup process...\n';
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final hubLocalDio = Dio(
      BaseOptions(
        baseUrl: 'http://192.168.4.1',
        connectTimeout: const Duration(seconds: 15),
      ),
    );

    try {
      // --- Шаг 1: Получение hubNumber С ХАБА ---
      _appendDebugLog('STEP 1: Getting hubNumber from hub...');
      setState(() => _statusMessage = localizations.connectingToHub);

      final hubStatusResponse = await hubLocalDio.get('/api/v1/status');

      if (hubStatusResponse.statusCode == 200 &&
          hubStatusResponse.data['hubNumber'] != null) {
        _foundHubNumber = hubStatusResponse.data['hubNumber'].toString();
        _appendDebugLog(
          'STEP 1 SUCCESS: Hub Number obtained: $_foundHubNumber',
        );
      } else {
        throw Exception(localizations.hubNumberNotFound);
      }

      // --- Шаг 2: Отправка Wi-Fi учетных данных на хаб ---
      _appendDebugLog('STEP 2: Sending Wi-Fi credentials to hub...');
      setState(() => _statusMessage = localizations.sendingWifiCredentials);

      // Отправляем запрос, но не ждем его завершения, так как хаб сразу разорвет соединение
      unawaited(
        hubLocalDio.post(
          '/api/v1/wifi_credentials',
          data: {
            'ssid': _ssidController.text,
            'password': _passwordController.text,
            'country_code': 'KZ',
          },
        ),
      );
      _appendDebugLog(
        'STEP 2 SUCCESS: Credentials sent. Hub will now reboot and connect to your Wi-Fi.',
      );

      // --- Шаг 3: Ожидание ---
      _appendDebugLog('STEP 3: Waiting for hub to connect to the cloud...');
      setState(() => _statusMessage = localizations.waitingForHubConnection);
      // Даем хабу достаточно времени на перезагрузку и подключение
      await Future.delayed(const Duration(seconds: 20));

      _appendDebugLog('STEP 4: Attaching hub $_foundHubNumber to user...');
      setState(() => _statusMessage = localizations.finalizingSetup);

      final attachResponse = await dio.post(
        '/mobile/hub/$_foundHubNumber/attach',
      );

      if (attachResponse.statusCode != 200) {
        throw Exception(
          '${localizations.failedToAttachHub}: ${attachResponse.statusCode}',
        );
      }

      _appendDebugLog('STEP 4 SUCCESS: Hub attached successfully.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.hubAddedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/main');
      }
    } catch (e) {
      final errorText = e.toString();
      _appendDebugLog('PROCESS FAILED: $errorText');
      if (mounted) {
        setState(() => _errorMessage = errorText);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(
    BuildContext context,
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppStyles.bodyText1(
        context,
      ).copyWith(color: AppColors.getSecondaryTextColor(context)),
      hintStyle: AppStyles.bodyText2(
        context,
      ).copyWith(color: AppColors.getLightGreyColor(context)),
      filled: true,
      fillColor: AppColors.getCardBackgroundColor(context),
      border: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide(color: AppColors.getBorderGrayColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.addNewHub,
          style: AppStyles.headline3(context),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.wifiSetupDescription,
                style: AppStyles.bodyText1(
                  context,
                ).copyWith(color: AppColors.getSecondaryTextColor(context)),
              ),
              const SizedBox(height: 20),
              Text(
                "${localizations.phoneCurrentWifi}: $_currentPhoneSsid",
                style: AppStyles.bodyText2(
                  context,
                ).copyWith(color: AppColors.getLightGreyColor(context)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ssidController,
                style: AppStyles.bodyText1(context),
                decoration: _buildInputDecoration(
                  context,
                  localizations.homeWifiName,
                  hint: localizations.homeWifiNameHint,
                ),
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? localizations.fieldCannotBeEmpty
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: AppStyles.bodyText1(context),
                decoration: _buildInputDecoration(
                  context,
                  localizations.wifiPassword,
                  hint: localizations.wifiPasswordHint,
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage,
                    style: AppStyles.bodyText2(
                      context,
                    ).copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _statusMessage,
                    style: AppStyles.bodyText1(
                      context,
                    ).copyWith(color: AppColors.primaryAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_debugLog.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.25,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Text(
                        _debugLog,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _connectWifi,
                style: AppStyles.primaryButtonStyle,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          localizations.configureHub,
                          style: TextStyle(
                            color: AppColors.textColorDark,
                            fontSize: 16,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

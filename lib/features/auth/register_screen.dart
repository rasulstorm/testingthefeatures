// lib/features/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/appcolor.dart';
import 'package:ISS/appstyles.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/core/network/dio_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _iinController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  final phoneFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoading = false;
  bool _agreeWithPolicy = false;
  bool _agreeWithOffer = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus && _phoneController.text.isEmpty) {
        _phoneController.text = '+7 (';
        _phoneController.selection = TextSelection.collapsed(
          offset: _phoneController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _iinController.dispose();
    super.dispose();
  }

  String normalizePhoneNumber(String rawPhone) {
    final digitsOnly = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = normalizePhoneNumber(_phoneController.text);

    try {
      final response = await dio.post(
        'https://app.iss-control.kz:443/api/v1/account-management/register/check-credentials',
        data: {
          "iin": _iinController.text,
          "phone": phone,
          "firstName": _nameController.text,
          "lastName": _lastNameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
        },
      );

      final data = response.data;
      final code = data['code'];
      final message = data['message'] ?? 'Неизвестная ошибка';

      if (code == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Регистрация успешна! Подтвердите код",
                style: AppStyles.bodyText2(
                  context,
                ).copyWith(color: AppColors.textColorDark),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.push(
            '/otp',
            extra: {
              'phone': _phoneController.text,
              'email': _emailController.text,
              'password': _passwordController.text,
              "iin": _iinController.text,
              "phoneNumber": phone,
              "firstName": _nameController.text,
              "lastName": _lastNameController.text,
            },
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Ошибка регистрации: $message",
                style: AppStyles.bodyText2(
                  context,
                ).copyWith(color: AppColors.textColorDark),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Ошибка сети: Нет соединения';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Ошибка: $msg",
              style: AppStyles.bodyText2(
                context,
              ).copyWith(color: AppColors.textColorDark),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Ошибка: $e",
              style: AppStyles.bodyText2(
                context,
              ).copyWith(color: AppColors.textColorDark),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPrivacyPolicy() =>
      _showModalWithText("Политика конфиденциальности", _privacyText);
  void _showPublicOffer() => _showModalWithText("Публичная оферта", _offerText);

  void _showModalWithText(String title, List<Widget> content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(20),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (_, controller) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppStyles.headline3(context)),
                        SizedBox(height: 16),
                        ...content,
                        SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: AppStyles.primaryButtonStyle,
                            child: Text(
                              "Закрыть",
                              style: AppStyles.bodyText1(
                                context,
                              ).copyWith(color: AppColors.textColorDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title, style: AppStyles.headline4(context)),
  );

  Widget _bulletList(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ", style: AppStyles.bodyText2(context)),
                    Expanded(
                      child: Text(item, style: AppStyles.bodyText2(context)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
  );

  List<Widget> get _privacyText => [
    Text(
      "СОГЛАСИЕ НА ОБРАБОТКУ ПЕРСОНАЛЬНЫХ ДАННЫХ",
      style: AppStyles.headline3(context),
    ),
    SizedBox(height: 8),
    Text(
      "Дата публикации: 25.03.2025 г\nНастоящая редакция действует с: 25.03.2025 г",
      style: AppStyles.bodyText2(context),
    ),
    SizedBox(height: 8),
    Text(
      "Настоящим Пользователь, принимая условия Политики конфиденциальности, свободно, по своей воле и в своем интересе дает безусловное согласие на обработку своих персональных данных ТОО “Innovative Security Systems - ISS” в соответствии с Законом Республики Казахстан от 21 мая 2013 года № 94-V «О персональных данных и их защите».",
      style: AppStyles.bodyText2(context),
      textAlign: TextAlign.justify,
    ),
    _sectionTitle("1. Обрабатываемые данные"),
    _bulletList([
      "ФИО, контактные данные (телефон, email), ИИН/БИН.",
      "Данные платежных карт (обрабатываются платежными системами, не хранятся на серверах Компании).",
    ]),
    _sectionTitle("2. Цели обработки"),
    _bulletList([
      "Предоставление доступа к Приложению и его функционалу.",
      "Автоматическое списание абонентской платы (при подписке).",
      "Отправка уведомлений и рекламных предложений (с возможностью отписки).",
      "Отправка СМС-сообщений, Whatsapp-сообщений, включая уведомления о платежах, важных изменениях в сервисе и маркетинговых предложениях.",
    ]),
    _sectionTitle("3. Передача данных"),
    _bulletList([
      "Данные могут передаваться платежным системам и партнерам для выполнения функций Приложения.",
      "Данные не передаются третьим лицам без согласия Пользователя, за исключением требований закона.",
    ]),
    _sectionTitle("4. Хранение и безопасность данных"),
    _bulletList([
      "Данные хранятся в течение срока использования Приложения и могут быть удалены по запросу Пользователя.",
      "Мы принимаем меры по защите данных, включая шифрование и ограниченный доступ.",
    ]),
    _sectionTitle("5. Права Пользователя"),
    _bulletList([
      "Отозвать согласие на обработку данных.",
      "Запросить удаление или исправление данных.",
      "Получить информацию о целях и способах обработки данных.",
    ]),
    SizedBox(height: 12),
    Text(
      "Запросы направляются на system.info.iss@gmail.com.",
      style: AppStyles.bodyText2(context),
    ),
    SizedBox(height: 12),
    Text(
      "Принятие условий Оферты и согласие на обработку персональных данных осуществляется при регистрации и использовании Приложения.",
      style: AppStyles.bodyText2(context),
      textAlign: TextAlign.justify,
    ),
  ];

  List<Widget> get _offerText => [
    Text(
      "ПУБЛИЧНАЯ ОФЕРТА\nна использование мобильного приложения iss",
      style: AppStyles.headline3(context),
    ),
    SizedBox(height: 8),
    Text(
      "Дата публикации: 25.03.2025 г.\nНастоящая редакция действует с: 25.03.2025 г.",
      style: AppStyles.bodyText2(context),
    ),
    SizedBox(height: 8),
    Text(
      "Настоящий документ является публичной офертой (далее — «Оферта») ТОО 'Innovative Security Systems - ISS' (далее — «Компания», «Мы», «Наш»), адресованной любому лицу (далее — «Пользователь»), заключить соглашение на использование мобильного приложения iss (далее — «Приложение») на изложенных ниже условиях.",
      style: AppStyles.bodyText2(context),
      textAlign: TextAlign.justify,
    ),
    Text(
      "Принятие Оферты (акцепт) осуществляется путем регистрации в Приложении и начала его использования.",
      style: AppStyles.bodyText2(context),
      textAlign: TextAlign.justify,
    ),
    _sectionTitle("1. ПРЕДМЕТ ОФЕРТЫ"),
    _sectionTitle(
      "1.1. Компания предоставляет Пользователю доступ к функционалу Приложения, включая (но не ограничиваясь):",
    ),
    _bulletList([
      "Управление подписками и платежами.",
      "Получение уведомлений и другой информации.",
      "Ведение истории заказов и платежей.",
    ]),
    _sectionTitle(
      "1.2. Услуги предоставляются в соответствии с условиями настоящей Оферты и Политики конфиденциальности.",
    ),
    _sectionTitle(
      "1.3. Компания вправе в любое время изменять условия предоставления услуг, уведомляя об этом Пользователей через Приложение или иными доступными способами.",
    ),
    _sectionTitle("2. РЕГИСТРАЦИЯ И АККАУНТ ПОЛЬЗОВАТЕЛЯ"),
    _bulletList([
      "2.1. Для использования Приложения Пользователь обязан зарегистрироваться, предоставив достоверные данные.",
      "2.2. Пользователь несет ответственность за сохранность учетных данных (логин, пароль) и обязуется не передавать их третьим лицам.",
      "2.3. Компания оставляет за собой право заблокировать или удалить аккаунт в случае нарушения условий Оферты.",
    ]),
    _sectionTitle("3. ПРАВА И ОБЯЗАННОСТИ СТОРОН"),
    _sectionTitle("3.1. Права и обязанности Пользователя:"),
    _bulletList([
      "Использовать Приложение в соответствии с его назначением.",
      "Предоставлять актуальные и достоверные данные.",
      "Не предпринимать действий, направленных на нарушение работы Приложения.",
      "Соблюдать законодательство и условия Оферты.",
    ]),
    _sectionTitle("3.2. Права и обязанности Компании:"),
    _bulletList([
      "Обеспечивать работу Приложения, за исключением периодов обслуживания или форс-мажорных ситуаций.",
      "Обрабатывать персональные данные в соответствии с Политикой конфиденциальности.",
      "Вносить изменения в функционал Приложения без предварительного уведомления.",
    ]),
    _sectionTitle("4. ОПЛАТА И ВОЗВРАТ"),
    _bulletList([
      "4.1. Оплата услуг осуществляется через интегрированные платежные системы (например, HalykBank).",
      "4.2. Пользователь соглашается с автоматическим списанием платежей при использовании подписки.",
      "4.3. Возврат средств возможен в соответствии с законодательством и условиями платежных систем.",
    ]),
    _sectionTitle("5. ОТВЕТСТВЕННОСТЬ"),
    _bulletList([
      "5.1. Компания не несет ответственности за сбои в работе Приложения, вызванные третьими лицами или форс-мажорными обстоятельствами.",
      "5.2. Пользователь несет ответственность за достоверность предоставленных данных и соблюдение условий Оферты.",
    ]),
    _sectionTitle("6. ЗАКЛЮЧИТЕЛЬНЫЕ ПОЛОЖЕНИЯ"),
    _bulletList([
      "6.1. Настоящая Оферта вступает в силу с момента акцепта Пользователем.",
      "6.2. Все споры и разногласия решаются путем переговоров, а в случае их не разрешения — решаются в соответствии с законодательством Республики Казахстан.",
      "6.3. Обновленная версия Оферты публикуется в Приложении и вступает в силу с момента публикации.",
    ]),
    SizedBox(height: 12),
    Text(
      "Контактная информация:\nТОО 'Innovative Security Systems - ISS'\nEmail: system.info.iss@gmail.com\nТелефон: +77052096943",
      style: AppStyles.bodyText2(context),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 120),
              SizedBox(height: 20),
              Text("Создайте аккаунт", style: AppStyles.headline2(context)),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getCardBackgroundColor(context),
                  labelText: "Имя",
                  prefixIcon: Icon(
                    Icons.person,
                    color: AppColors.getLightGreyColor(context),
                  ),
                  labelStyle: AppStyles.bodyText1(context),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.getBorderGrayColor(context),
                    ),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                ),
                style: AppStyles.bodyText1(context),
                validator: (value) => value!.isEmpty ? "Введите имя" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getCardBackgroundColor(context),
                  labelText: "Фамилия",
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.getLightGreyColor(context),
                  ),
                  labelStyle: AppStyles.bodyText1(context),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.getBorderGrayColor(context),
                    ),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                ),
                style: AppStyles.bodyText1(context),
                validator: (value) => value!.isEmpty ? "Введите фамилию" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                inputFormatters: [phoneFormatter],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getCardBackgroundColor(context),
                  labelText: "Телефон",
                  prefixIcon: Icon(
                    Icons.phone,
                    color: AppColors.getLightGreyColor(context),
                  ),
                  labelStyle: AppStyles.bodyText1(context),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.getBorderGrayColor(context),
                    ),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                ),
                style: AppStyles.bodyText1(context),
                validator:
                    (value) =>
                        (value == null ||
                                value.isEmpty ||
                                phoneFormatter.getUnmaskedText().length < 10)
                            ? 'Введите корректный номер'
                            : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _iinController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getCardBackgroundColor(context),
                  labelText: "ИИН",
                  prefixIcon: Icon(
                    Icons.badge,
                    color: AppColors.getLightGreyColor(context),
                  ),
                  labelStyle: AppStyles.bodyText1(context),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.getBorderGrayColor(context),
                    ),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                ),
                style: AppStyles.bodyText1(context),
                validator: (value) => value!.isEmpty ? "Введите иин" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getCardBackgroundColor(context),
                  labelText: "Email",
                  prefixIcon: Icon(
                    Icons.email,
                    color: AppColors.getLightGreyColor(context),
                  ),
                  labelStyle: AppStyles.bodyText1(context),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.getBorderGrayColor(context),
                    ),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                ),
                style: AppStyles.bodyText1(context),
                validator:
                    (value) =>
                        value!.contains('@')
                            ? null
                            : "Введите корректный email",
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getCardBackgroundColor(context),
                  labelText: "Пароль",
                  prefixIcon: Icon(
                    Icons.lock,
                    color: AppColors.getLightGreyColor(context),
                  ),
                  labelStyle: AppStyles.bodyText1(context),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.getBorderGrayColor(context),
                    ),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                ),
                style: AppStyles.bodyText1(context),
                validator:
                    (value) =>
                        value!.length >= 6
                            ? null
                            : "Пароль должен быть от 6 символов",
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getCardBackgroundColor(context),
                  labelText: "Подтвердите пароль",
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.getLightGreyColor(context),
                  ),
                  labelStyle: AppStyles.bodyText1(context),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.getBorderGrayColor(context),
                    ),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                    borderRadius: AppStyles.borderRadiusAll(12),
                  ),
                ),
                style: AppStyles.bodyText1(context),
                validator:
                    (value) =>
                        value == _passwordController.text
                            ? null
                            : "Пароли не совпадают",
              ),
              SizedBox(height: 20),
              CheckboxListTile(
                value: _agreeWithPolicy,
                onChanged:
                    (val) => setState(() => _agreeWithPolicy = val ?? false),
                activeColor: AppColors.primaryAccent,
                checkColor: AppColors.textColorDark,
                tileColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Я соглашаюсь с ",
                      style: AppStyles.bodyText2(context),
                    ),
                    GestureDetector(
                      onTap: _showPrivacyPolicy,
                      child: Text(
                        "политикой конфиденциальности",
                        style: AppStyles.bodyText2(context).copyWith(
                          color: AppColors.primaryAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _agreeWithOffer,
                onChanged:
                    (val) => setState(() => _agreeWithOffer = val ?? false),
                activeColor: AppColors.primaryAccent,
                checkColor: AppColors.textColorDark,
                tileColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text("Я принимаю ", style: AppStyles.bodyText2(context)),
                    GestureDetector(
                      onTap: _showPublicOffer,
                      child: Text(
                        "публичную оферту",
                        style: AppStyles.bodyText2(context).copyWith(
                          color: AppColors.primaryAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (!_agreeWithPolicy || !_agreeWithOffer || _isLoading)
                          ? null
                          : _register,
                  style: AppStyles.primaryButtonStyle.copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return AppColors.getLightGreyColor(context);
                      }
                      return AppColors.primaryAccent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return AppColors.secondaryTextColorDark;
                      }
                      return AppColors.textColorDark;
                    }),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textColorDark,
                              ),
                            ),
                          )
                          : Text(
                            "Зарегистрироваться",
                            style: AppStyles.bodyText1(
                              context,
                            ).copyWith(color: AppColors.textColorDark),
                          ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    "Уже есть аккаунт? Войти",
                    style: AppStyles.bodyText1(
                      context,
                    ).copyWith(color: AppColors.primaryAccent),
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

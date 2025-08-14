// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'ISS.AI';

  @override
  String get homeTab => 'Главная';

  @override
  String get objectsTab => 'Объекты';

  @override
  String get settingsTab => 'Настройки';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get profileIcon => 'Профиль';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get generalSection => 'Общие';

  @override
  String get languageSetting => 'Язык';

  @override
  String get themeSetting => 'Тема';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Темная';

  @override
  String get accountSection => 'Аккаунт';

  @override
  String get profileSetting => 'Профиль';

  @override
  String get securitySetting => 'Безопасность';

  @override
  String get logoutSetting => 'Выйти';

  @override
  String get supportSection => 'Поддержка';

  @override
  String get helpSetting => 'Помощь';

  @override
  String get aboutAppSetting => 'О приложении';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageKazakh => 'Казахский';

  @override
  String get changePassword => 'Сменить пароль';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get myContracts => 'Мои контракты';

  @override
  String get noObjects => 'Нет объектов';

  @override
  String get loadingObjects => 'Загрузка объектов...';

  @override
  String get errorLoadingObjects => 'Ошибка загрузки объектов:';

  @override
  String get retry => 'Повторить';

  @override
  String get addHub => 'Добавить объект';

  @override
  String get hubId => 'ID объекта';

  @override
  String get cancel => 'Отмена';

  @override
  String get add => 'Добавить';

  @override
  String get hubAddedSuccessfully => 'Объект успешно добавлен';

  @override
  String get errorAddingHub => 'Ошибка добавления объекта:';

  @override
  String get lastUpdate => 'Последнее обновление:';

  @override
  String get room => 'Комната:';

  @override
  String get group => 'Группа:';

  @override
  String get disarm => 'Снять с охраны';

  @override
  String get arm => 'Поставить на охрану';

  @override
  String get alarm => 'Тревога';

  @override
  String get noMessage => 'Нет сообщения';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get address => 'Адрес:';

  @override
  String get status => 'Статус:';

  @override
  String devicesOnHub(Object count) {
    return 'Устройства на объекте ($count)';
  }

  @override
  String get noDevicesFound => 'Устройства на этом объекте не найдены.';

  @override
  String get close => 'Закрыть';

  @override
  String get subscriptionNotActive => 'Подписка не активна';

  @override
  String get bindCard => 'Привязать карту';

  @override
  String get paymentHistory => 'История платежей';

  @override
  String get amount => 'Сумма:';

  @override
  String get date => 'Дата:';

  @override
  String get description => 'Описание:';

  @override
  String get cardBoundSuccessfully => 'Карта успешно привязана';

  @override
  String get errorBindingCard => 'Ошибка привязки карты';

  @override
  String get errorLoadingWebView => 'Ошибка загрузки WebView';

  @override
  String get subscriptionFee => 'Абонентская плата:';

  @override
  String get statusActive => 'Статус: Активна';

  @override
  String get card => 'Карта';

  @override
  String get nextPayment => 'Следующее списание:';

  @override
  String get cardBound => 'Карта привязана';

  @override
  String get errorLoadingCard => 'Ошибка загрузки карты';

  @override
  String get update => 'Обновить';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get name => 'Название';

  @override
  String get lastName => 'Фамилия';

  @override
  String get phone => 'Телефон';

  @override
  String get iin => 'ИИН';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get passwordMinLength => 'Пароль должен быть не менее 6 символов';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get agreePrivacyPolicy => 'Я согласен с политикой конфиденциальности';

  @override
  String get acceptPublicOffer => 'Я принимаю публичную оферту';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get login => 'Войти';

  @override
  String get enterEmailPassword => 'Пожалуйста, введите ваш email и пароль';

  @override
  String get enterValidEmail => 'Пожалуйста, введите корректный email';

  @override
  String get enterPassword => 'Пожалуйста, введите ваш пароль';

  @override
  String get rememberMe => 'Запомнить меня';

  @override
  String get noAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get otpVerification => 'OTP Верификация';

  @override
  String enterCodeSentTo(Object phone) {
    return 'Введите код, отправленный на $phone';
  }

  @override
  String get otpCode => 'OTP Код';

  @override
  String get verify => 'Подтвердить';

  @override
  String get registrationSuccess => 'Регистрация успешна! Подтвердите код';

  @override
  String get registrationAndLoginSuccess => 'Регистрация и вход успешны!';

  @override
  String get verificationError => 'Verification error';

  @override
  String get networkError => 'Ошибка сети: Нет соединения';

  @override
  String get generalError => 'Произошла ошибка:';

  @override
  String get changePasswordTitle => 'Сменить пароль';

  @override
  String get oldPassword => 'Старый пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтвердите новый пароль';

  @override
  String get passwordChangedSuccessfully => 'Пароль успешно изменен';

  @override
  String get errorChangingPassword => 'Ошибка смены пароля:';

  @override
  String get save => 'Сохранить';

  @override
  String get whatsappCodeTitle => 'Код WhatsApp';

  @override
  String get enterPhoneForCode =>
      'Введите номер телефона для получения кода через WhatsApp';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get resetPasswordTitle => 'Сброс пароля';

  @override
  String get resetPassword => 'Сбросить пароль';

  @override
  String get passwordResetSuccessfully => 'Пароль успешно сброшен';

  @override
  String get errorResettingPassword => 'Ошибка сброса пароля:';

  @override
  String get aboutUsTitle => 'О нас';

  @override
  String get ourMission => 'Наша миссия';

  @override
  String get whatWeOffer => 'Что мы предлагаем?';

  @override
  String get mainServices => 'Основные услуги:';

  @override
  String get securitySystems =>
      'Комплексные системы безопасности: Мониторинг, датчики движения, уведомления в реальном времени.';

  @override
  String get smartLighting =>
      'Умное освещение: Настройка сценариев, дистанционное управление, экономия энергии.';

  @override
  String get climateControl =>
      'Климат-контроль: Автоматическая регулировка температуры для вашего комфорта.';

  @override
  String get videoSurveillance =>
      'Видеонаблюдение: Доступ к камерам в любой точке мира, запись событий.';

  @override
  String get smartDeviceIntegration =>
      'Интеграция умных устройств: Поддержка широкого спектра сторонних гаджетов.';

  @override
  String get questions => 'Есть вопросы?';

  @override
  String get contactUs =>
      'Если у вас есть вопросы, предложения или вы хотите узнать больше о наших услугах, пожалуйста, свяжитесь с нами.';

  @override
  String get failedToOpenEmail => 'Не удалось открыть почтовое приложение';

  @override
  String get myContractsTitle => 'Мои контракты';

  @override
  String get noActiveContracts => 'У вас пока нет активных контрактов.';

  @override
  String get contract => 'Контракт:';

  @override
  String get nextPaymentDate => 'Следующее списание:';

  @override
  String get amountPaid => 'Оплаченная сумма:';

  @override
  String get deleteConfirmationTitle => 'Подтвердите удаление';

  @override
  String get deleteConfirmationMessage =>
      'Вы уверены, что хотите удалить аккаунт? Это действие необратимо.';

  @override
  String get delete => 'Удалить';

  @override
  String get accountDeleted => 'Аккаунт удален';

  @override
  String get errorDeletingAccount => 'Ошибка удаления аккаунта:';

  @override
  String get logoutConfirmationTitle => 'Подтвердите выход';

  @override
  String get logoutConfirmationMessage => 'Вы уверены, что хотите выйти?';

  @override
  String get logout => 'Выйти';

  @override
  String get unknown => 'неизвестно';

  @override
  String get errorLoadingContracts => 'Ошибка загрузки контрактов';

  @override
  String get roomsTitle => 'Комнаты';

  @override
  String get devicesTitle => 'Устройства';

  @override
  String get noRoomsFound =>
      'Комнаты не найдены. Добавьте комнаты, чтобы начать!';

  @override
  String get noDevicesInRoom => 'В эту комнату еще не добавлены устройства.';

  @override
  String get temperature => 'Температура';

  @override
  String get humidity => 'Влажность';

  @override
  String get light => 'Свет';

  @override
  String get open => 'Открыто';

  @override
  String get closed => 'Закрыто';

  @override
  String get on => 'Вкл';

  @override
  String get off => 'Выкл';

  @override
  String get motionDetected => 'Движение';

  @override
  String get noMotion => 'Нет движения';

  @override
  String get homeOverview => 'Обзор дома';

  @override
  String get yourHome => 'Ваш дом';

  @override
  String get totalDevices => 'Всего устройств:';

  @override
  String get activeDevices => 'Активных устройств:';

  @override
  String get totalRooms => 'Всего комнат:';

  @override
  String get favoriteDevices => 'Избранные устройства';

  @override
  String get active => 'активна';

  @override
  String get iAmHome => 'Я дома';

  @override
  String get officeShort => 'Офис';

  @override
  String get doorClosedShort => 'Закрыта';

  @override
  String get doorNoun => 'Дверь';

  @override
  String get noResponse => 'Нет ответа';

  @override
  String get chandelier => 'Люстра';

  @override
  String get topLight => 'Верхний свет';

  @override
  String get noPower => 'Нет питания';

  @override
  String get noWater => 'Нет воды';

  @override
  String get tempShort => 'Темп.';

  @override
  String get humidityShort => 'Влажн.';

  @override
  String get lightShort => 'Свет';

  @override
  String get all => 'Все';

  @override
  String get livingRoom => 'Гостиная';

  @override
  String get kitchen => 'Кухня';

  @override
  String get errorLoadingImage => 'Ошибка загрузки изображения';

  @override
  String get list => 'Список';

  @override
  String get paymentMethods => 'Способы оплаты';

  @override
  String get search => 'Поиск';

  @override
  String get noHubsFound => 'Хабы не найдены';

  @override
  String get errorLoadingData => 'Ошибка загрузки данных';

  @override
  String get noControlAvailable => 'Управление недоступно';

  @override
  String get connectionActive => 'Соединение активно';

  @override
  String get connectionLost => 'Соединение потеряно';

  @override
  String get homeScreenTitle => 'Главный экран';

  @override
  String get noHubsAvailable =>
      'Нет доступных объектов. Пожалуйста, добавьте объект, чтобы начать.';

  @override
  String get online => 'Онлайн';

  @override
  String get offline => 'Оффлайн';

  @override
  String get commandHubId => 'ID хаба для команд';

  @override
  String get noDevices => 'Устройства для этого хаба не найдены.';

  @override
  String get errorLoadingHubs => 'Ошибка загрузки хабов';

  @override
  String get switchAll => 'Включить все';

  @override
  String get powerOffAll => 'Выключить все';

  @override
  String get noDataAvailable => 'Данные недоступны.';

  @override
  String get brightness => 'Яркость';

  @override
  String get lightLevel => 'Уровень освещенности';

  @override
  String get occupancy => 'Присутствие';

  @override
  String get detected => 'Обнаружено';

  @override
  String get clear => 'Чисто';

  @override
  String get batteryStatus => 'Статус батареи';

  @override
  String get low => 'Низкий';

  @override
  String get normal => 'Нормальный';

  @override
  String get tamper => 'Вскрытие';

  @override
  String get distance => 'Расстояние';

  @override
  String get controllableDevices => 'Управляемые устройства';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get switchAllSuccess => 'Все устройства переключены.';

  @override
  String get powerOffAllSuccess => 'Все устройства выключены.';

  @override
  String get noControllableDevices => 'Управляемые устройства не найдены.';

  @override
  String get dimmer => 'Диммер';

  @override
  String get switchDevice => 'Переключатель';

  @override
  String get blinds => 'Жалюзи';

  @override
  String get blindsControlTip =>
      'Используйте кнопки для управления жалюзи (Открыть/Стоп/Закрыть)';

  @override
  String get statusIndicators => 'Статус индикаторов';

  @override
  String get gasDetected => 'Газ обнаружен';

  @override
  String get smokeDetected => 'Дым обнаружен';

  @override
  String get waterLeak => 'Утечка воды';

  @override
  String get moving => 'движение обнаружено';

  @override
  String get subscriptionStatus => 'Статус подписки';

  @override
  String get cardIsBound => 'Карта привязана';

  @override
  String get totalContractAmount => 'Общая сумма контракта';

  @override
  String get nextCharge => 'Следующее списание';

  @override
  String get errorLoadingSubscription => 'Ошибка загрузки подписки';

  @override
  String get errorLoadingPayments => 'Ошибка загрузки платежей';

  @override
  String get errorLoadingCardInfo => 'Ошибка загрузки информации о карте';

  @override
  String get errorLoadingBindForm => 'Ошибка загрузки формы привязки';

  @override
  String get noPaymentRecords => 'Нет записей о платежах';

  @override
  String get noDescription => 'Без описания';

  @override
  String get notAttached => 'Не прикреплен';

  @override
  String get scenariosTab => 'Сценарии';

  @override
  String get scenariosEmptyList => 'Список сценариев пуст.';

  @override
  String get scenariosCreatePrompt => 'Создайте свой первый сценарий!';

  @override
  String get createScenarioButton => 'Создать новый сценарий';

  @override
  String get createScenarioNotImplemented =>
      'Переход к созданию нового сценария (пока не реализовано)';

  @override
  String get loginTitle => 'Вход';

  @override
  String get emailPlaceholder => 'Email';

  @override
  String get passwordPlaceholder => 'Пароль';

  @override
  String get loginButton => 'Войти';

  @override
  String get noAccountPrompt => 'Нет аккаунта?';

  @override
  String get registerHere => 'Зарегистрироваться здесь';

  @override
  String get generalSettings => 'Общие настройки';

  @override
  String get accountSettings => 'Настройки аккаунта';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'Английский';

  @override
  String get profileTitle => 'Профиль';

  @override
  String currentLanguage(Object language) {
    return 'Текущий язык: $language';
  }

  @override
  String get accountDeletedSuccess => 'Аккаунт успешно удален.';

  @override
  String get accountDeleteError => 'Ошибка удаления аккаунта';

  @override
  String get loginFailed => 'Ошибка входа';

  @override
  String get loginError => 'Ошибка входа';

  @override
  String get language => 'Язык';

  @override
  String get darkMode => 'Темная тема';

  @override
  String get createScenarioTitle => 'Создание сценария';

  @override
  String get editScenarioTitle => 'Редактировать сценарий';

  @override
  String get scenarioGeneralSettings => 'Общие настройки сценария';

  @override
  String get scenarioNameLabel => 'Название сценария';

  @override
  String get scenarioNameRequired => 'Название сценария обязательно';

  @override
  String get scenarioEnabledLabel => 'Сценарий включен';

  @override
  String get scenarioTriggers => 'Триггеры';

  @override
  String get addTriggerButton => 'Добавить триггер';

  @override
  String get scenarioConditions => 'Условия';

  @override
  String get addConditionButton => 'Добавить условие';

  @override
  String get scenarioActions => 'Действия';

  @override
  String get addActionBtn => 'Добавить действие';

  @override
  String get saveScenarioButton => 'Сохранить сценарий';

  @override
  String get deviceNameLabel => 'Имя устройства';

  @override
  String get attributeLabel => 'Атрибут';

  @override
  String get operatorLabel => 'Оператор';

  @override
  String get valueLabel => 'Значение';

  @override
  String get commandJsonLabel => 'JSON команды';

  @override
  String triggerLabel(int number) {
    return 'Триггер $number';
  }

  @override
  String conditionLabel(int number) {
    return 'Условие $number';
  }

  @override
  String actionLabel(int number) {
    return 'Действие $number';
  }

  @override
  String get scenariosListEmpty => 'Здесь пока нет сценариев.';

  @override
  String get createFirstScenarioPrompt =>
      'Создайте свой первый сценарий, чтобы автоматизировать управление умным домом.';

  @override
  String get createNewScenarioButton => 'Создать новый сценарий';

  @override
  String get translate => 'Перевод';

  @override
  String get setupWifi => 'Настроить Wifi';

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
  String get wifiPasswordHint => 'Введите пароль от вашего домашнего Wi-Fi';

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
  String get unknownNetworkError => 'Неизвестная сетевая ошибка';

  @override
  String get getString => 'Нет входа по этому FaceID';

  @override
  String unexpectedErrorMessage(Object errorMessage) {
    return 'An unexpected error occurred: $errorMessage. Please try again.';
  }

  @override
  String get createPinTitle => 'Создать PIN-код';

  @override
  String get createPinDescription =>
      'Пожалуйста, введите 4-значный PIN-код для быстрой авторизации.';

  @override
  String get confirmPinTitle => 'Подтвердите PIN-код';

  @override
  String get confirmPinDescription =>
      'Пожалуйста, повторите свой 4-значный PIN-код.';

  @override
  String get enterPinTitle => 'Введите PIN-код';

  @override
  String get enterPinDescription =>
      'Пожалуйста, введите свой 4-значный PIN-код.';

  @override
  String get changeOldPinTitle => 'Изменить PIN-код';

  @override
  String get enterOldPinTitle => 'Введите старый PIN-код';

  @override
  String get enterOldPinDescription =>
      'Для изменения PIN-кода, пожалуйста, введите текущий PIN-код.';

  @override
  String get createNewPinTitle => 'Создать новый PIN-код';

  @override
  String get createNewPinDescription =>
      'Пожалуйста, введите новый 4-значный PIN-код.';

  @override
  String get confirmNewPinTitle => 'Подтвердите новый PIN-код';

  @override
  String get confirmNewPinDescription =>
      'Пожалуйста, повторите новый 4-значный PIN-код.';

  @override
  String get pinSetSuccess => 'PIN-код успешно установлен.';

  @override
  String get pinChangedSuccess => 'PIN-код успешно изменен.';

  @override
  String get pinVerifiedSuccess => 'PIN-код успешно проверен.';

  @override
  String get pinMismatch =>
      'PIN-коды не совпадают. Пожалуйста, попробуйте снова.';

  @override
  String get incorrectPin => 'Неверный PIN-код.';

  @override
  String attemptsRemaining(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'Осталось # попыток.',
      many: 'Осталось # попыток.',
      few: 'Осталось # попытки.',
      one: 'Осталась # попытка.',
    );
    return '$_temp0';
  }

  @override
  String get pinLockedOut =>
      'PIN-код заблокирован. Слишком много неудачных попыток.';

  @override
  String get pinLockedOutRedirect =>
      'PIN-код заблокирован. Пожалуйста, войдите с помощью логина и пароля.';

  @override
  String get loginWithPassword => 'Войти с помощью пароля';

  @override
  String get localAuthSetting => 'Вход по Face ID / PIN-коду';

  @override
  String get enabled => 'Включен';

  @override
  String get disabled => 'Выключен';

  @override
  String get useBiometricsOnly => 'Только Face ID (если доступно)';

  @override
  String get biometricsOnlyDescription =>
      'Вход будет осуществляться только по Face ID. PIN-код будет отключен.';

  @override
  String get biometricsAndPinDescription =>
      'Вход будет осуществляться по Face ID или по PIN-коду как резервный вариант.';

  @override
  String get authReason => 'Подтвердите свою личность для входа в приложение';

  @override
  String get authFailedLocalAuthNotEnabled =>
      'Не удалось включить локальную аутентификацию.';

  @override
  String get authFailedBiometricsPinNotFound =>
      'Биометрическая аутентификация не пройдена, или PIN-код не настроен/недоступен.';

  @override
  String get sessionExpiredLoginAgain =>
      'Сессия истекла. Пожалуйста, войдите снова.';

  @override
  String get localAuthFailedLoginWithCredentials =>
      'Аутентификация не пройдена. Пожалуйста, войдите с помощью логина/пароля.';

  @override
  String get sessionExpired => 'Сессия истекла. Пожалуйста, войдите снова.';

  @override
  String get authFailed =>
      'Аутентификация не пройдена. Пожалуйста, войдите с помощью логина/пароля.';

  @override
  String get setupPinTitle => 'Настроить PIN-код';

  @override
  String get setupPinDescription =>
      'Вы можете настроить PIN-код для быстрого доступа к приложению.';

  @override
  String get setupPinButton => 'Установить PIN';

  @override
  String get faceIdPinSettingTitle => 'Вход по Face ID / PIN-коду';

  @override
  String get localAuthNotAvailable =>
      'Недоступно на вашем устройстве или не настроено.';

  @override
  String get localAuthEnabledMessage => 'Вход по Face ID/PIN-коду включен.';

  @override
  String get localAuthNotEnabledMessage =>
      'Аутентификация не пройдена. Вход по Face ID/PIN-коду не включен.';

  @override
  String get localAuthDisabledMessage => 'Вход по Face ID/PIN-коду выключен.';

  @override
  String get loadingApp => 'Загрузка приложения...';

  @override
  String get incorrectOldPin => 'Ошибка ввода старого PIN-кода';

  @override
  String dimmerControlTitle(Object deviceName) {
    return 'Управление диммером: $deviceName';
  }

  @override
  String deviceControlModalTitle(Object deviceType, Object deviceName) {
    return 'Управление устройством: $deviceType ($deviceName)';
  }

  @override
  String get switchingHistoryTitle => 'История переключений';

  @override
  String get switchingHistoryUnderDevelopment =>
      'История переключений находится в разработке.';

  @override
  String get deviceInfoTitle => 'Информация об устройстве';

  @override
  String get scenarioNameHint =>
      'Например: \'Утренний свет\', \'Режим отпуска\'';

  @override
  String get triggersTitle => 'Триггеры';

  @override
  String get conditionsTitle => 'Условия';

  @override
  String get actionsTitle => 'Действия';

  @override
  String get addActionbutton => 'Добавить действие';

  @override
  String get scenarioNameCannotBeEmpty =>
      'Название сценария не может быть пустым.';

  @override
  String get scenarioMustHaveAtLeastOneElement =>
      'Сценарий должен содержать хотя бы один триггер, условие или действие.';

  @override
  String get scenarioSavedSuccessfully => 'Сценарий успешно сохранен!';

  @override
  String get scenarioSaveFailed =>
      'Не удалось сохранить сценарий. Проверьте подключение или данные.';

  @override
  String get typeLabel => 'Тип';

  @override
  String get commandLabel => 'Команда (JSON)';

  @override
  String get temperatureSensor => 'Датчик температуры';

  @override
  String get humiditySensor => 'Датчик влажности';

  @override
  String get batterySensor => 'Датчик батареи';

  @override
  String get gasSensor => 'Датчик газа';

  @override
  String get waterSensor => 'Датчик воды';

  @override
  String get motionSensor => 'Датчик движения';

  @override
  String get smokeSensor => 'Датчик дыма и пожара';

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
  String get pleaseSelectHub => 'Пожалуйста, выберите хаб';

  @override
  String get selectHub => 'Выберите хаб';

  @override
  String get selectDevice => 'select Device';

  @override
  String get selectHubLabel => 'selectHubLabel';

  @override
  String get renameHubTitle => 'Переименовать хаб';

  @override
  String get enterNewNameHint => 'Введите новое имя';

  @override
  String get hubRenamedSuccess => 'Хаб успешно переименован';

  @override
  String get hubRenamedFailed => 'Не удалось переименовать хаб';

  @override
  String get startPairing => 'Начать сопряжение';

  @override
  String get pairingStartedSuccess => 'Режим сопряжения запущен на 25 секунд';

  @override
  String get pairingStartedFailed => 'Не удалось запустить режим сопряжения';

  @override
  String get voiceAssistantEnabled => 'Голосовой ассистент активирован';

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
  String get paymentAndCards => 'Оплата и карты';

  @override
  String get myCards => 'Мои карты';

  @override
  String get noCards => 'Привязанных карт не найдено.';

  @override
  String get primaryCard => 'Основная карта';

  @override
  String get makePrimary => 'Сделать основной';

  @override
  String get bindNewCard => 'Привязать новую карту';

  @override
  String get primaryCardSetSuccess => 'Основная карта обновлена';

  @override
  String get primaryCardSetError => 'Ошибка при установке основной карты';

  @override
  String get receiptNotAvailable => 'Чек недоступен';

  @override
  String get couldNotOpenReceipt => 'Не удалось открыть чек';

  @override
  String get viewReceipt => 'Посмотреть чек';

  @override
  String get monthlyFee => 'Абонентская плата';

  @override
  String get profileUpdatedSuccess => 'Профиль успешно обновлен';

  @override
  String get editName => 'Редактировать имя';

  @override
  String get editLastName => 'Редактировать фамилию';

  @override
  String get noNotifications => 'У вас пока нет уведомлений.';

  @override
  String get securityArmed => 'Объект поставлен на охрану';

  @override
  String get securityDisarmed => 'Объект снят с охраны';

  @override
  String get iAmNotHome => 'Я не дома';

  @override
  String get familyAccess => 'Семейный доступ';

  @override
  String get noFamilyGroups => 'Вы еще не создали ни одной семейной группы.';

  @override
  String get createGroup => 'Создать группу';

  @override
  String get members => 'Участники';

  @override
  String get createNewGroup => 'Создание новой группы';

  @override
  String get noHubsForSharing =>
      'Нет хабов, доступных для предоставления доступа.';

  @override
  String get groupName => 'Название группы';

  @override
  String get memberEmails => 'Email участников';

  @override
  String get emailsHint => 'Введите email через запятую';

  @override
  String get fieldCannotBeEmpty => 'Это поле не может быть пустым';

  @override
  String get create => 'Создать';

  @override
  String get errorCreatingGroup => 'Ошибка при создании группы';

  @override
  String get changeRole => 'Изменить роль';

  @override
  String get deleteMember => 'Удалить участника';

  @override
  String get noMembersInGroup => 'В этой группе пока нет участников';

  @override
  String get confirmDeleteMember =>
      'Вы уверены, что хотите удалить этого участника из группы?';

  @override
  String get roleUpdatedSuccess => 'Роль успешно обновлена';

  @override
  String get memberDeletedSuccess => 'Участник успешно удален';

  @override
  String get addNewHub => 'Добавить новый хаб';

  @override
  String get wifiSetupDescription =>
      'Сначала подключите телефон к Wi-Fi хаба (например, \'iss-hub-xxxx\'). Затем введите данные вашего ДОМАШНЕГО Wi-Fi ниже.';

  @override
  String get phoneCurrentWifi => 'Текущий Wi-Fi вашего телефона';

  @override
  String get homeWifiName => 'Имя домашнего Wi-Fi (SSID)';

  @override
  String get homeWifiNameHint => 'Введите имя вашей домашней сети';

  @override
  String get wifiPassword => 'Пароль от Wi-Fi';

  @override
  String get configureHub => 'Настроить хаб';

  @override
  String get connectingToHub => 'Подключение к хабу...';

  @override
  String get hubNumberNotFound => 'Номер хаба не найден в ответе хаба';

  @override
  String get sendingWifiCredentials => 'Отправка данных Wi-Fi...';

  @override
  String get waitingForHubConnection =>
      'Ожидание подключения хаба к вашей сети...';

  @override
  String get finalizingSetup => 'Завершение настройки...';

  @override
  String get failedToAttachHub => 'Не удалось привязать хаб';

  @override
  String get hubAddedSuccess => 'Хаб успешно добавлен!';

  @override
  String get locationTracking => 'Отслеживание геолокации';

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
  String get hubScanningNetworks => 'Хаб сканирует домашние сети...';

  @override
  String get scanFailed =>
      'Сканирование не удалось. Возможно, хаб не в режиме настройки.';

  @override
  String get selectHomeNetwork => 'Выберите вашу домашнюю Wi-Fi сеть';

  @override
  String get noNetworksFound => 'Сети не найдены.';

  @override
  String get network => 'Сеть';

  @override
  String get connect => 'Подключить';

  @override
  String get nowConnectToAvailableNetwork =>
      'Now connect your hub to available network';

  @override
  String get connectToHubFirst => 'Connect your phone to hub';

  @override
  String get devicesInRoom => 'Устройства в комнате';

  @override
  String get addDevice => 'Добавить устройство';

  @override
  String get removeFromRoom => 'Убрать из комнаты';

  @override
  String get roomsAndDevices => 'Комнаты и устройства';

  @override
  String get myRooms => 'Мои комнаты';

  @override
  String get noRooms => 'У вас пока нет комнат';

  @override
  String get addRoom => 'Добавить комнату';

  @override
  String get unassignedDevices => 'Устройства без комнаты';

  @override
  String get editRoom => 'Редактировать комнату';

  @override
  String get selectRoomBackground => 'Выберите фон для комнаты';

  @override
  String get roomName => 'Название комнаты';

  @override
  String get roomNameIsRequired => 'Название комнаты обязательно';

  @override
  String get changeImage => 'Изменить изображение';

  @override
  String get addImage => 'Добавить изображение';

  @override
  String get assignDevices => 'Назначить устройства';

  @override
  String get selectDevicesFor => 'Выберите устройства для';

  @override
  String get noUnassignedDevices => 'Нет устройств для назначения';

  @override
  String get devicesAssignedSuccess => 'Устройства успешно назначены в комнату';

  @override
  String get devicesTab => 'Устройства';

  @override
  String get connectToHubWifiPromptTitle => 'Подключитесь к хабу';

  @override
  String get connectToHubWifiPromptBody =>
      'Для продолжения, перейдите в настройки Wi-Fi вашего телефона и подключитесь к сети с именем:';

  @override
  String get goToWifiSettings => 'Перейти в настройки Wi-Fi';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get enterPasswordFor => 'Введите пароль для';

  @override
  String get detachHub => 'Отвязать хаб';

  @override
  String get detachHubTitle => 'Отвязать хаб?';

  @override
  String detachHubConfirmation(String hubName) {
    return 'Вы уверены, что хотите отвязать хаб \'$hubName\'? Это действие необратимо.';
  }

  @override
  String get hubDetachedSuccess => 'Хаб успешно отвязан';

  @override
  String get hubDetachedFailed => 'Ошибка при отвязке хаба';

  @override
  String get detach => 'Отвязать';

  @override
  String get serverUnavailableTitle => 'Сервер временно недоступен';

  @override
  String get serverUnavailableMessage =>
      'Мы уже знаем о проблеме и работаем над ее решением. Пожалуйста, попробуйте обновить страницу.';

  @override
  String get refresh => 'Обновить';

  @override
  String get locationPermissionNeededForWifi =>
      'Доступ к геолокации необходим для определения имени Wi-Fi сети.';

  @override
  String get permissionDenied => 'Разрешение отклонено';

  @override
  String get errorGettingWifiName => 'Ошибка при получении имени Wi-Fi';

  @override
  String get assign => 'Назначить';

  @override
  String get image => 'Изображение';

  @override
  String get imageSelected => 'Изображение выбрано';

  @override
  String get noImageSelected => 'Изображение не выбрано';

  @override
  String get change => 'Изменить';

  @override
  String get deleteRoomTitle => 'Удалить комнату?';

  @override
  String deleteRoomConfirmation(String roomName) {
    return 'Вы уверены, что хотите удалить комнату \'$roomName\'? Все устройства в ней станут нераспределенными.';
  }

  @override
  String get noData => 'Нет данных';

  @override
  String get presence => 'Присутствие';

  @override
  String get edit => 'Изменить';

  @override
  String get addMemberTitle => 'Добавить участника';

  @override
  String get addMemberButton => 'Добавить участника';

  @override
  String get role => 'Роль';

  @override
  String get userRole => 'Пользователь';

  @override
  String get adminRole => 'Администратор';

  @override
  String get newSpace => 'New Space';

  @override
  String get searchDevices => 'Поиск устройств';

  @override
  String get selectAll => 'Выбор всех устройств';

  @override
  String get nothingFound => 'Устройства не найдены';

  @override
  String get genericSaved => 'Пинкод сохранен';
}

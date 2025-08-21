import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';

final whatsappCodeControllerProvider =
    StateNotifierProvider.autoDispose<WhatsappCodeController, AsyncValue<void>>(
      (ref) => WhatsappCodeController(ref),
    );

class WhatsappCodeController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  WhatsappCodeController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> verifyCode(String phone, String code) async {
    state = const AsyncValue.loading();
    try {
      final response = await dio.post(
        '/account-management/verify-otp',
        queryParameters: {'phoneNumber': phone, 'code': code},
      );

      final data = response.data;

      if (data['code'] == 0) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        throw Exception(data['message'] ?? 'Неизвестная ошибка');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> resendCode(String phone, bool sendByEmail) async {
    state = const AsyncValue.loading();
    try {
      final response = await dio.post(
        '/account-management/send-otp',
        queryParameters: {
          'phoneNumber': phone,
          'verificationType': sendByEmail ? 'sms' : 'whatsapp',
          'forgotPassword': true,
        },
      );

      final data = response.data;

      if (data['code'] == 0) {
        state = const AsyncValue.data(null);
      } else {
        throw Exception(data['message'] ?? 'Ошибка при отправке кода');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

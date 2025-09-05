import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'avatar_service.dart';
import 'photo_service.dart';

class AvatarState {
  final String? url;
  final bool loading;
  final double progress;
  final String? error;

  const AvatarState({
    this.url,
    this.loading = false,
    this.progress = 0.0,
    this.error,
  });

  AvatarState copyWith({
    String? url,
    bool? loading,
    double? progress,
    String? error,
  }) {
    return AvatarState(
      url: url ?? this.url,
      loading: loading ?? this.loading,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

final avatarControllerProvider =
    StateNotifierProvider<AvatarController, AvatarState>((ref) {
      final svc = ref.read(avatarServiceProvider);
      final photoSvc = ref.read(photoServiceProvider);
      return AvatarController(ref, svc, photoSvc);
    });

class AvatarController extends StateNotifier<AvatarState> {
  AvatarController(this.ref, this._svc, this._photoSvc)
    : super(const AvatarState());

  final Ref ref;
  final AvatarService _svc;
  final PhotoService _photoSvc;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickAndUpload({required bool camera}) async {
    state = state.copyWith(error: null);
    final XFile? xfile = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 100,
    );
    if (xfile == null) return;
    await upload(xfile.path);
  }

  Future<void> upload(String sourcePath) async {
    try {
      state = state.copyWith(loading: true, progress: 0, error: null);

      await _svc.uploadUserAvatar(
        sourcePath,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          state = state.copyWith(progress: sent / total);
        },
      );

      final list = await _photoSvc.getUserPhotos();
      final url = _photoSvc.pickBestAvatarUrl(list);
      final withBust = (url == null || url.isEmpty) ? null : _appendBust(url);

      state = state.copyWith(url: withBust, loading: false, progress: 1.0);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Не удалось загрузить фото: $e',
      );
    }
  }

  String _appendBust(String url) {
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}t=${DateTime.now().millisecondsSinceEpoch}';
  }
}

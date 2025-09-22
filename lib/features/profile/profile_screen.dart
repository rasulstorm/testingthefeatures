import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/l10n/app_localizations.dart';

import 'package:ISS/features/profile/avatar/avatar_controller.dart';
import 'package:ISS/features/profile/avatar/token_header_provider.dart';
import 'package:ISS/features/profile/avatar/photo_service.dart';

// ---------- ДАННЫЕ ПРОФИЛЯ ----------
final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  Future<String> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) throw Exception("Refresh token не найден");

    final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    final response = await refreshDio.post(
      '/account-management/refresh',
      data: {'refreshToken': refreshToken},
    );

    final data = response.data['data'];
    final newAccessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

    if (newAccessToken == null || newRefreshToken == null) {
      throw Exception("Неверный ответ при обновлении токена");
    }
    await prefs.setString('accessToken', newAccessToken);
    await prefs.setString('refreshToken', newRefreshToken);
    return newAccessToken;
  }

  final token = await refreshAccessToken();
  final response = await dio.get(
    '/user/get',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  bool _isDirty = false;
  bool _isLoading = false;

  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();

    _profileSub = ref.listenManual<AsyncValue<Map<String, dynamic>>>(
      profileProvider,
      (prev, next) async {
        if (next.hasValue) {
          final profile = next.value!;
          _firstNameController.text = (profile['firstName'] ?? '').toString();
          _lastNameController.text = (profile['lastName'] ?? '').toString();

          // При первом получении профиля — подтянем фото пользователя
          try {
            final photos = await ref.read(photoServiceProvider).getUserPhotos();
            final url = ref
                .read(photoServiceProvider)
                .pickBestAvatarUrl(photos);
            if (url != null && url.isNotEmpty) {
              final bust = _appendBust(url);
              final avatarCtrl = ref.read(avatarControllerProvider.notifier);
              avatarCtrl.state = avatarCtrl.state.copyWith(url: bust);
            }
          } catch (_) {}
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _profileSub?.close();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final t = AppLocalizations.of(context);
    if (!_isDirty) return;
    setState(() => _isLoading = true);
    try {
      await dio.put(
        '/user/update',
        data: {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.profileUpdatedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(profileProvider);
      setState(() => _isDirty = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.generalError}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editFieldDialog(
    String title,
    TextEditingController controller,
  ) async {
    final t = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(context),
          title: Text(title, style: AppStyles.headline4(context)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppStyles.bodyText1(context),
            cursorColor: AppColors.primaryAccent,
            decoration: InputDecoration(
              filled: false,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.getBorderGrayColor(context),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primaryAccent,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                t.cancel,
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _isDirty = true);
                Navigator.pop(dialogContext);
              },
              style: AppStyles.primaryButtonStyle.copyWith(
                minimumSize: WidgetStateProperty.all(Size.zero),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              child: Text(
                t.save,
                style: const TextStyle(color: AppColors.textColorDark),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeAvatar() async {
    final ctrl = ref.read(avatarControllerProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Сфотографировать'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ctrl.pickAndUpload(camera: true);
                    if (!mounted) return;
                    ref.invalidate(profileProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Фото обновлено')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Выбрать из галереи'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ctrl.pickAndUpload(camera: false);
                    if (!mounted) return;
                    ref.invalidate(profileProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Фото обновлено')),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileProvider);
    final avatarState = ref.watch(avatarControllerProvider);
    final headersAsync = ref.watch(bearerHeadersProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.getBackgroundColor(context),
        leading: const BackButton(),
        title: Text(t.profileSetting),
        actions: [
          if (_isDirty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child:
                  _isLoading
                      ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : TextButton(
                        onPressed: _updateProfile,
                        child: Text(
                          t.save,
                          style: AppStyles.bodyText1(context).copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const _ProfileSkeleton(),
        error:
            (e, _) => _ErrorState(
              message: '${t.generalError} $e',
              onRetry: () => ref.invalidate(profileProvider),
            ),
        data: (profile) {
          final firstName = (profile['firstName'] ?? '').toString();
          final lastName = (profile['lastName'] ?? '').toString();
          final initials = _initials(firstName, lastName);
          final avatarUrl = avatarState.url; // уже нормализованный и с bust
          final headers = headersAsync.maybeWhen(
            data: (h) => h,
            orElse: () => const <String, String>{},
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderHero(
                  title:
                      '${firstName.isEmpty ? t.name : firstName} ${lastName.isEmpty ? '' : lastName}',
                  subtitle: profile['email']?.toString() ?? '-',
                  avatarUrl: avatarUrl,
                  initials: initials,
                  loading: avatarState.loading,
                  progress: avatarState.progress,
                  onChangeAvatar: _changeAvatar,
                  headers: headers,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _SectionCard(
                  children: [
                    _EditableTile(
                      icon: Icons.person,
                      title: t.name,
                      value: firstName,
                      onTap:
                          () => _editFieldDialog(
                            t.editName,
                            _firstNameController,
                          ),
                    ),
                    _DividerLine(),
                    _EditableTile(
                      icon: Icons.person_outline,
                      title: t.lastName,
                      value: lastName,
                      onTap:
                          () => _editFieldDialog(
                            t.editLastName,
                            _lastNameController,
                          ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _SectionCard(
                  children: [
                    _InfoTile(
                      icon: Icons.email,
                      title: t.email,
                      value: (profile['email'] ?? '-').toString(),
                    ),
                    _DividerLine(),
                    _InfoTile(
                      icon: Icons.phone,
                      title: t.phone,
                      value: (profile['phoneNumber'] ?? '-').toString(),
                    ),
                    _DividerLine(),
                    _InfoTile(
                      icon: Icons.badge,
                      title: t.iin,
                      value: (profile['iin'] ?? '-').toString(),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    t.myContracts,
                    style: AppStyles.headline3(context),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: _SectionCard(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: Text(
                        t.myContracts,
                        style: AppStyles.bodyText1(context),
                      ),
                      leading: Icon(
                        Icons.description,
                        color: AppColors.primaryAccent,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                      onTap: () => context.push('/contracts'),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  String _appendBust(String url) {
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  String _initials(String first, String last) {
    String i1 = first.isNotEmpty ? first.trim()[0] : '';
    String i2 = last.isNotEmpty ? last.trim()[0] : '';
    return (i1 + i2).toUpperCase();
  }
}

// ---------- UI SUBWIDGETS ----------

class _HeaderHero extends StatelessWidget {
  const _HeaderHero({
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.initials,
    required this.loading,
    required this.progress,
    required this.onChangeAvatar,
    required this.headers,
  });

  final String title;
  final String subtitle;
  final String? avatarUrl;
  final String initials;
  final bool loading;
  final double progress;
  final VoidCallback onChangeAvatar;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        AppColors.primaryAccent.withOpacity(0.20),
        AppColors.primaryAccent.withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(gradient: gradient),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Мой профиль', style: AppStyles.headline3(context)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppStyles.bodyText2(context).copyWith(
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          top: 90,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _Avatar(
              size: 110,
              url: avatarUrl,
              initials: initials,
              loading: loading,
              progress: progress,
              onTap: onChangeAvatar,
              headers: headers,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    required this.url,
    required this.initials,
    required this.loading,
    required this.progress,
    required this.onTap,
    required this.headers,
  });

  final double size;
  final String? url;
  final String initials;
  final bool loading;
  final double progress;
  final VoidCallback onTap;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;
    final imgProvider = hasImage ? NetworkImage(url!, headers: headers) : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: AppColors.getBackgroundColor(context),
              width: 3,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            backgroundImage: imgProvider,
            child:
                imgProvider == null
                    ? Text(
                      initials.isEmpty ? '🙂' : initials,
                      style: TextStyle(
                        fontSize: initials.isEmpty ? 38 : 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    )
                    : null,
          ),
        ),
        if (loading)
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: size + 6,
                height: size + 6,
                child: CircularProgressIndicator(
                  value: (progress > 0 && progress < 1) ? progress : null,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        Positioned(
          right: -2,
          bottom: -2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 20,
                color: AppColors.textColorDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppStyles.cardDecoration(context),
      child: Column(children: children),
    );
  }
}

class _EditableTile extends StatelessWidget {
  const _EditableTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: AppColors.getSecondaryTextColor(context)),
      title: Text(title, style: AppStyles.bodyText2(context)),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyles.bodyText1(context)
            .copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.edit,
        color: AppColors.getSecondaryTextColor(context),
        size: 20,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: AppColors.getSecondaryTextColor(context)),
      title: Text(title, style: AppStyles.bodyText2(context)),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyles.bodyText1(context)
            .copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.getBorderGrayColor(context).withOpacity(0.4),
      height: 1,
      thickness: 0.7,
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final card = AppStyles.cardDecoration(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 220,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryAccent.withOpacity(0.20),
                AppColors.primaryAccent.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 50),
        Container(height: 120, decoration: card),
        const SizedBox(height: 16),
        Container(height: 160, decoration: card),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.bodyText1(
                context,
              ).copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: AppStyles.primaryButtonStyle,
              child: const Text(
                'Повторить',
                style: TextStyle(color: AppColors.textColorDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

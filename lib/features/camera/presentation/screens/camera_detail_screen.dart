import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../domain/camera_models.dart';
import '../../data/cameras_repository.dart';
import '../providers.dart';
import '../../widgets/camera_form_sheet.dart';

enum _StreamMode { live, archive }

class CameraDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CameraDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends ConsumerState<CameraDetailScreen> {
  VideoPlayerController? _vp;
  _StreamMode _mode = _StreamMode.live;
  bool _muted = false;
  bool _playerError = false;
  String? _currentUrl;

  @override
  void dispose() {
    _vp?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer(String url) async {
    if (!mounted) return;
    if (_currentUrl == url && (_vp?.value.isInitialized ?? false)) return;

    final old = _vp;
    _currentUrl = url;
    _playerError = false;

    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _vp = c;

    try {
      await c.initialize();
      c.setLooping(true);
      await c.setVolume(_muted ? 0 : 1);
      await c.play();
    } catch (e) {
      _playerError = true;
      debugPrint('[CameraPlayer] init error: $e');
    } finally {
      old?.dispose();
      if (mounted) setState(() {});
    }
  }

  void _retry() {
    final cam = ref.read(cameraByIdProvider(widget.id)).valueOrNull;
    final url = _urlFor(cam, _mode);
    if (url != null) {
      _initPlayer(url);
    }
  }

  String? _urlFor(Camera? cam, _StreamMode m) {
    if (cam == null) return null;
    switch (m) {
      case _StreamMode.live:
        return cam.hlsUrl;
      case _StreamMode.archive:
        return cam.videoPlaylistUrl;
    }
  }

  Future<void> _edit(BuildContext context, Camera cam) async {
    final req = await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => CameraFormSheet(initial: cam),
    );
    if (req == null) return;
    await ref.read(camerasRepositoryProvider).update(cam.id, req);
    ref.invalidate(cameraByIdProvider(widget.id));
    ref.invalidate(camerasProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final camAsync = ref.watch(cameraByIdProvider(widget.id));

    return Scaffold(
      body: camAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => SafeArea(
              child: Column(
                children: [
                  AppBar(leading: const BackButton()),
                  Expanded(child: Center(child: Text('Ошибка: $e'))),
                ],
              ),
            ),
        data: (cam) {
          final enabled = cam.status == CameraStatus.ENABLED;

          // если переключили режим — подготовим URL и инициализируем после build
          final url = _urlFor(cam, _mode);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (url != null && enabled) _initPlayer(url);
          });

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 260,
                leading: const BackButton(),
                actions: [
                  IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () => _edit(context, cam),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _PlayerHero(
                    child: _PlayerView(
                      enabled: enabled,
                      mode: _mode,
                      url: url,
                      vp: _vp,
                      playerError: _playerError,
                      muted: _muted,
                      onRetry: _retry,
                      onToggleMute: () async {
                        setState(() => _muted = !_muted);
                        await _vp?.setVolume(_muted ? 0 : 1);
                      },
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cam.cameraModel ?? 'Камера',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _StatusChip(enabled: enabled),
                    ],
                  ),
                ),
              ),

              // режимы Live/Запись
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SegmentedButton<_StreamMode>(
                    segments: const [
                      ButtonSegment(
                        value: _StreamMode.live,
                        label: Text('Live'),
                        icon: Icon(Icons.podcasts),
                      ),
                      ButtonSegment(
                        value: _StreamMode.archive,
                        label: Text('Запись'),
                        icon: Icon(Icons.history),
                      ),
                    ],
                    style: ButtonStyle(visualDensity: VisualDensity.compact),
                    selected: {_mode},
                    onSelectionChanged: (s) {
                      final next = s.first;
                      if (_mode == next) return;
                      HapticFeedback.lightImpact();
                      setState(() {
                        _mode = next;
                        _currentUrl = null;
                      });
                      // player инициализируется в postFrame
                    },
                  ),
                ),
              ),

              // Информация
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverToBoxAdapter(child: _InfoCard(cam: cam)),
              ),

              // Действия
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: _ActionsRow(
                    enabled: enabled,
                    onToggle: () async {
                      final repo = ref.read(camerasRepositoryProvider);
                      if (enabled) {
                        await repo.deactivate(cam.id);
                      } else {
                        await repo.activate(cam.id);
                      }
                      _vp?.dispose();
                      _vp = null;
                      _currentUrl = null;
                      ref.invalidate(cameraByIdProvider(widget.id));
                      ref.invalidate(camerasProvider);
                    },
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Удалить камеру?'),
                              content: Text(cam.cameraModel ?? cam.id),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                      );
                      if (ok == true) {
                        await ref
                            .read(camerasRepositoryProvider)
                            .delete(cam.id);
                        ref.invalidate(camerasProvider);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    onCopyUrl: () async {
                      final u = _urlFor(cam, _mode);
                      if (u == null || u.isEmpty) return;
                      await Clipboard.setData(ClipboardData(text: u));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ссылка скопирована')),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// === UI bits ===

class _PlayerHero extends StatelessWidget {
  final Widget child;
  const _PlayerHero({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(.25),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _PlayerView extends StatelessWidget {
  final bool enabled;
  final _StreamMode mode;
  final String? url;
  final VideoPlayerController? vp;
  final bool playerError;
  final bool muted;
  final VoidCallback onRetry;
  final VoidCallback onToggleMute;

  const _PlayerView({
    required this.enabled,
    required this.mode,
    required this.url,
    required this.vp,
    required this.playerError,
    required this.muted,
    required this.onRetry,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content() {
      if (!enabled) {
        return _placeholder(
          context,
          icon: Icons.videocam_off,
          label: 'Поток выключен',
        );
      }
      if (url == null || url!.isEmpty) {
        return _placeholder(
          context,
          icon: Icons.link_off,
          label:
              mode == _StreamMode.live ? 'Нет HLS-ссылки' : 'Нет ссылки записи',
        );
      }
      if (playerError) {
        return _placeholder(
          context,
          icon: Icons.error_outline,
          label: 'Не удалось воспроизвести',
          action: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        );
      }
      if (vp == null || !vp!.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black, child: VideoPlayer(vp!)),
          // Градиент и оверлеи
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.25),
                    Colors.transparent,
                    Colors.black.withOpacity(.35),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: _ModePill(
              text: mode == _StreamMode.live ? 'LIVE' : 'RECORD',
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                IconButton.filled(
                  tooltip: muted ? 'Включить звук' : 'Выключить звук',
                  onPressed: onToggleMute,
                  icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Пауза/Плей',
                  onPressed: () {
                    if (vp!.value.isPlaying) {
                      vp!.pause();
                    } else {
                      vp!.play();
                    }
                  },
                  icon: Icon(
                    vp!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: (vp?.value.aspectRatio ?? 16 / 9).clamp(1.3, 2.0),
      child: content(),
    );
  }

  Widget _placeholder(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white30, size: 40),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String text;
  const _ModePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool enabled;
  const _StatusChip({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            enabled ? 'ENABLED' : 'DISABLED',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Camera cam;
  const _InfoCard({required this.cam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile(String title, String value, {Widget? trailing}) {
      return ListTile(
        dense: true,
        title: Text(title, style: theme.textTheme.bodySmall),
        subtitle: Text(value),
        trailing: trailing,
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          tile(
            'HLS (live)',
            cam.hlsUrl ?? '—',
            trailing: _CopyBtn(text: cam.hlsUrl),
          ),
          const Divider(height: 1),
          tile(
            'Запись (playlist)',
            cam.videoPlaylistUrl ?? '—',
            trailing: _CopyBtn(text: cam.videoPlaylistUrl),
          ),
          const Divider(height: 1),
          tile('IP адрес', cam.ipAddress ?? '—'),
          const Divider(height: 1),
          tile('Источник (ingest)', cam.ingestSource ?? '—'),
        ],
      ),
    );
  }
}

class _CopyBtn extends StatelessWidget {
  final String? text;
  const _CopyBtn({this.text});

  @override
  Widget build(BuildContext context) {
    final can = (text != null && text!.isNotEmpty);
    return IconButton(
      tooltip: can ? 'Скопировать' : null,
      onPressed:
          !can
              ? null
              : () async {
                await Clipboard.setData(ClipboardData(text: text!));
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Скопировано')));
                }
              },
      icon: const Icon(Icons.copy_all_rounded),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onCopyUrl;

  const _ActionsRow({
    required this.enabled,
    required this.onToggle,
    required this.onDelete,
    required this.onCopyUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onToggle,
            icon: Icon(enabled ? Icons.videocam_off : Icons.videocam),
            label: Text(enabled ? 'Отключить' : 'Включить'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCopyUrl,
            icon: const Icon(Icons.link),
            label: const Text('Копировать URL'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

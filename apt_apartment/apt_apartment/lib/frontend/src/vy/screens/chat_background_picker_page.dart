import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';

class ChatBackgroundPickerPage extends StatefulWidget {
  const ChatBackgroundPickerPage({
    super.key,
    required this.initialUrl,
  });

  final String? initialUrl;

  @override
  State<ChatBackgroundPickerPage> createState() =>
      _ChatBackgroundPickerPageState();
}

class _ChatBackgroundPickerPageState extends State<ChatBackgroundPickerPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  Future<List<String>>? _future;
  String? _selectedUrl;
  VideoPlayerController? _previewController;
  Future<void>? _previewInit;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.initialUrl;
    _future = _repository.fetchChatBackgroundUrls();
    _setPreview(widget.initialUrl);
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _setPreview(String? url) async {
    final previous = _previewController;
    _previewController = null;
    _previewInit = null;
    await previous?.dispose();

    if (url == null) {
      if (!mounted) return;
      setState(() {});
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _previewController = controller;
    _previewInit = controller.initialize().then((_) async {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
    });
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chon nen chat')),
      body: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final urls = snapshot.data ?? const <String>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _PreviewCard(
                  controller: _previewController,
                  init: _previewInit,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Thu vien nen',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (_selectedUrl != null)
                      Text(
                        'Da chon',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Mac dinh'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedUrl == null
                            ? null
                            : () => Navigator.of(context).pop(_selectedUrl),
                        child: const Text('Chon nen nay'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: urls.isEmpty
                    ? const Center(child: Text('Khong co nen nao.'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 16 / 10,
                        ),
                        itemCount: urls.length,
                        itemBuilder: (context, index) {
                          final url = urls[index];
                          final selected = url == _selectedUrl;
                          return _BackgroundTile(
                            title: 'Nen ${index + 1}',
                            selected: selected,
                            onTap: () async {
                              setState(() => _selectedUrl = url);
                              await _setPreview(url);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  const _BackgroundTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.16),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                top: -6,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 72,
                  color: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          selected ? 'Dang chon' : 'Xem truoc',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.75),
                              ),
                        ),
                        const Spacer(),
                        if (selected)
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.controller,
    required this.init,
  });

  final VideoPlayerController? controller;
  final Future<void>? init;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.2),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: controller == null || init == null
              ? const Center(child: Text('Chon mot nen de xem truoc'))
              : FutureBuilder<void>(
                  future: init,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Khong the xem truoc.'));
                    }

                    final value = controller!.value;
                    if (!value.isInitialized) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: value.size.width,
                            height: value.size.height,
                            child: VideoPlayer(controller!),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

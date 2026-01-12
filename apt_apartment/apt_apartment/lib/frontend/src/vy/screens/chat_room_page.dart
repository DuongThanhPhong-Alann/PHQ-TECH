import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:apt_apartment/backend/src/phong/models/nguoi_dung.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/backend/src/vy/models/chat_message.dart';
import 'package:apt_apartment/frontend/src/vy/screens/chat_background_picker_page.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.title,
    required this.currentUserId,
  });

  final int chatId;
  final String title;
  final int currentUserId;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  final TextEditingController _composer = TextEditingController();
  final DateFormat _timeFormat = DateFormat('HH:mm');
  Future<Map<int, NguoiDung>>? _membersFuture;
  final StreamController<List<ChatMessage>> _messagesController =
      StreamController<List<ChatMessage>>.broadcast();
  StreamSubscription<List<ChatMessage>>? _realtimeSub;
  Timer? _pollTimer;
  VideoPlayerController? _bgController;
  Future<void>? _bgInit;
  String? _bgUrl;

  @override
  void initState() {
    super.initState();
    _membersFuture = _init();
    _startMessages();
    _restoreBackground();
  }

  Future<Map<int, NguoiDung>> _init() async {
    await _repository.ensureChatMember(
      chatId: widget.chatId,
      nguoiDungId: widget.currentUserId,
    );
    return _repository.fetchChatMembers(widget.chatId);
  }

  String get _bgPrefKey =>
      'aptconnect.chat_bg.${widget.chatId}.${widget.currentUserId}';

  Future<void> _restoreBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString(_bgPrefKey);
      if (!mounted) return;
      await _setBackground(url, persist: false);
    } catch (_) {}
  }

  Future<void> _setBackground(String? url, {required bool persist}) async {
    if (_bgUrl == url) return;
    _bgUrl = url;

    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (url == null) {
          await prefs.remove(_bgPrefKey);
        } else {
          await prefs.setString(_bgPrefKey, url);
        }
      } catch (_) {}
    }

    final old = _bgController;
    _bgController = null;
    _bgInit = null;
    await old?.dispose();

    if (url != null) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _bgController = controller;
      _bgInit = controller.initialize().then((_) async {
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();
      });
    }
    if (!mounted) return;
    setState(() {});
  }

  void _startMessages() {
    _refreshMessages();
    _realtimeSub = _repository
        .watchChatMessages(chatId: widget.chatId)
        .listen(_messagesController.add, onError: _messagesController.addError);
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshMessages();
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await _repository.fetchChatMessages(chatId: widget.chatId);
      if (_messagesController.isClosed) return;
      _messagesController.add(messages);
    } catch (error) {
      if (_messagesController.isClosed) return;
      _messagesController.addError(error);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeSub?.cancel();
    _messagesController.close();
    _bgController?.dispose();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Doi nen',
            icon: const Icon(Icons.wallpaper_outlined),
            onPressed: _openBackgroundPicker,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _ChatBackground(
              controller: _bgController,
              init: _bgInit,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.72),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: FutureBuilder<Map<int, NguoiDung>>(
                          future: _membersFuture,
                          builder: (context, membersSnapshot) {
                            final members = membersSnapshot.data ??
                                const <int, NguoiDung>{};
                            return StreamBuilder<List<ChatMessage>>(
                              stream: _messagesController.stream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
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
                                final messages =
                                    snapshot.data ?? const <ChatMessage>[];
                                if (messages.isEmpty) {
                                  return const _EmptyChat();
                                }
                                return ListView.separated(
                                  reverse: true,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    16,
                                    12,
                                    16,
                                  ),
                                  itemCount: messages.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final isMine = message.senderId ==
                                        widget.currentUserId;
                                    final senderName = isMine
                                        ? 'Ban'
                                        : (members[message.senderId]?.hoTen ??
                                            'User #${message.senderId}');
                                    return _MessageBubble(
                                      isMine: isMine,
                                      senderName: senderName,
                                      content: message.noiDung,
                                      timeLabel: _timeFormat
                                          .format(message.createdAt),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _Composer(
                controller: _composer,
                onSend: _handleSend,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBackgroundPicker() async {
    final selected = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => ChatBackgroundPickerPage(initialUrl: _bgUrl),
      ),
    );
    if (!mounted) return;
    await _setBackground(selected, persist: true);
  }

  Future<void> _handleSend() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.sendChatMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        noiDung: text,
      );
      await _refreshMessages();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ChatBackground extends StatelessWidget {
  const _ChatBackground({required this.controller, required this.init});

  final VideoPlayerController? controller;
  final Future<void>? init;

  @override
  Widget build(BuildContext context) {
    final base = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );

    if (controller == null || init == null) {
      return base;
    }

    return FutureBuilder<void>(
      future: init,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return base;
        }
        if (snapshot.hasError || !controller!.value.isInitialized) {
          return base;
        }

        final value = controller!.value;
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
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.20),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.78),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        decoration: const InputDecoration(
                          hintText: 'Nhap tin nhan...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => onSend(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isMine,
    required this.senderName,
    required this.content,
    required this.timeLabel,
  });

  final bool isMine;
  final String senderName;
  final String content;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 6),
      bottomRight: Radius.circular(isMine ? 6 : 18),
    );

    final bg = isMine
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                color: colorScheme.primary.withValues(alpha: 0.18),
                offset: const Offset(0, 6),
              ),
            ],
          )
        : BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
            borderRadius: radius,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          );

    final textColor = isMine ? colorScheme.onPrimary : colorScheme.onSurface;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final initial = senderName.isNotEmpty
        ? senderName.trim().substring(0, 1).toUpperCase()
        : '?';

    return Align(
      alignment: align,
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 4),
                    child: Text(
                      senderName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth * 0.82;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: DecoratedBox(
                        decoration: bg,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                content,
                                style: TextStyle(
                                  color: textColor,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: textColor.withValues(alpha: 0.78),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.chat_bubble_outline,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chua co tin nhan',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Hay gui tin nhan dau tien cua ban.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

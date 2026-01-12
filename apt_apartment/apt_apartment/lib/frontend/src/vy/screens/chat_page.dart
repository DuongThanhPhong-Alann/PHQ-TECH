import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/phong/models/nguoi_dung.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/backend/src/vy/models/chat_private_summary.dart';
import 'package:apt_apartment/frontend/src/vy/screens/chat_room_page.dart';
import 'package:apt_apartment/frontend/src/vy/screens/resident_picker_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.profile});

  final NguoiDung? profile;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _dateFormat = DateFormat('dd/MM');
  Future<_ChatPageData>? _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase().trim());
    });
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_ChatPageData> _load() async {
    final profile = widget.profile;
    if (profile == null) {
      throw Exception('Vui long dang nhap lai.');
    }
    if (!profile.isCuDan) {
      return _ChatPageData(
        userId: profile.id,
        chungCuId: null,
        tenChungCu: profile.tenChungCu ?? '',
        buildingChatId: null,
        privateChats: const [],
      );
    }

    final info = await _repository.fetchCuDanResidencyInfo(profile.id);
    final chungCuId = (info?['ID_ChungCu'] as int?);
    final tenChungCu =
        info?['TenChungCu']?.toString() ?? profile.tenChungCu ?? '';

    final buildingChatId = chungCuId == null
        ? null
        : (await _repository.getOrCreateBuildingChat(
            chungCuId: chungCuId,
            nguoiDungId: profile.id,
          ))
            .id;

    final privateChats = await _repository.fetchPrivateChatsForUser(
      nguoiDungId: profile.id,
    );
    return _ChatPageData(
      userId: profile.id,
      chungCuId: chungCuId,
      tenChungCu: tenChungCu,
      buildingChatId: buildingChatId,
      privateChats: privateChats,
    );
  }

  Future<void> _refresh() async {
    final data = await _load();
    if (!mounted) return;
    setState(() => _future = Future.value(data));
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    if (profile == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Vui long dang nhap de su dung chat.'),
        ),
      );
    }

    return FutureBuilder<_ChatPageData>(
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
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Khong the tai du lieu chat.'));
        }

        if (!profile.isCuDan) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chat hien chi danh cho tai khoan Cu dan.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: _BuildingChatCard(
                        title: data.tenChungCu.isNotEmpty
                            ? data.tenChungCu
                            : 'Chung cu',
                        enabled: data.buildingChatId != null,
                        onTap: data.buildingChatId == null
                            ? null
                            : () => _openRoom(
                                  chatId: data.buildingChatId!,
                                  title: 'Chat chung cu',
                                  currentUserId: data.userId,
                                ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: _SearchBox(controller: _searchController),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: 'Chat rieng',
                        icon: Icons.forum_outlined,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: _buildPrivateChats(data),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: data.chungCuId == null
                    ? null
                    : () => _startPrivateChat(
                          currentUserId: data.userId,
                          chungCuId: data.chungCuId!,
                        ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Nhan tin'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startPrivateChat({
    required int currentUserId,
    required int chungCuId,
  }) async {
    final selected = await Navigator.of(context).push<NguoiDung>(
      MaterialPageRoute(
        builder: (_) => ResidentPickerPage(
          currentUserId: currentUserId,
          chungCuId: chungCuId,
        ),
      ),
    );
    if (selected == null) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final chat = await _repository.getOrCreatePrivateChat(
        nguoiDungId: currentUserId,
        otherUserId: selected.id,
      );
      if (!mounted) return;
      _openRoom(
        chatId: chat.id,
        title: selected.hoTen,
        currentUserId: currentUserId,
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openRoom({
    required int chatId,
    required String title,
    required int currentUserId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          chatId: chatId,
          title: title,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  SliverChildDelegate _emptyPrivateChatsDelegate() {
    return SliverChildListDelegate.fixed(
      const [
        _EmptyStateCard(
          icon: Icons.chat_bubble_outline,
          title: 'Chua co cuoc tro chuyen nao',
          subtitle: 'Bam "Nhan tin" de bat dau chat rieng.',
        ),
      ],
    );
  }

  Widget _buildPrivateChats(_ChatPageData data) {
    final filtered = _query.isEmpty
        ? data.privateChats
        : data.privateChats
            .where(
              (chat) =>
                  chat.otherUser.hoTen.toLowerCase().contains(_query) ||
                  (chat.lastMessage ?? '').toLowerCase().contains(_query),
            )
            .toList(growable: false);

    if (filtered.isEmpty) {
      return SliverList(delegate: _emptyPrivateChatsDelegate());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: filtered.length,
        (context, index) {
          final chat = filtered[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == filtered.length - 1 ? 0 : 10),
            child: _PrivateChatTile(
              chat: chat,
              timeLabel: _formatLastAt(chat.lastAt),
              onTap: () => _openRoom(
                chatId: chat.chatId,
                title: chat.otherUser.hoTen,
                currentUserId: data.userId,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatLastAt(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final sameDay =
        now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    return sameDay ? _timeFormat.format(dateTime) : _dateFormat.format(dateTime);
  }
}

class _ChatPageData {
  const _ChatPageData({
    required this.userId,
    required this.chungCuId,
    required this.tenChungCu,
    required this.buildingChatId,
    required this.privateChats,
  });

  final int userId;
  final int? chungCuId;
  final String tenChungCu;
  final int? buildingChatId;
  final List<ChatPrivateSummary> privateChats;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrivateChatTile extends StatelessWidget {
  const _PrivateChatTile({
    required this.chat,
    required this.timeLabel,
    required this.onTap,
  });

  final ChatPrivateSummary chat;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = chat.lastMessage?.trim();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                child: Text(
                  chat.otherUser.hoTen.isNotEmpty
                      ? chat.otherUser.hoTen.trim().substring(0, 1).toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.otherUser.hoTen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (timeLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeLabel,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle == null || subtitle.isEmpty ? 'Chua co tin nhan' : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Tim chat...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _BuildingChatCard extends StatelessWidget {
  const _BuildingChatCard({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final overlay = enabled ? 0.0 : 0.35;
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primary.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: Icon(
                  Icons.apartment_rounded,
                  size: 120,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          colorScheme.onPrimaryContainer.withValues(alpha: 0.10),
                      child: Icon(
                        Icons.groups_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat nhom',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            enabled ? 'Realtime chat chung cu' : 'Khong tim thay chung cu cua ban',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.75),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
              if (overlay > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: overlay),
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

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

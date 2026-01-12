import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:apt_apartment/backend/src/quang/models/tin_tuc.dart';
import 'package:apt_apartment/backend/src/quang/services/supabase_repository.dart';
import 'package:apt_apartment/frontend/src/quang/constants/media_assets.dart';
import 'package:apt_apartment/frontend/src/quang/widgets/app_states.dart';

class TinTucPage extends StatefulWidget {
  const TinTucPage({super.key});

  @override
  State<TinTucPage> createState() => _TinTucPageState();
}

class _TinTucPageState extends State<TinTucPage> {
  final AptConnectRepository _repository = AptConnectRepository();
  Future<List<TinTuc>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchTinTucs();
  }

  Future<void> _refresh() async {
    final result = await _repository.fetchTinTucs();
    if (!mounted) return;
    setState(() => _future = Future.value(result));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TinTuc>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }
        final articles = snapshot.data ?? const [];
        if (articles.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 80),
                AppEmptyState(
                  icon: Icons.newspaper_rounded,
                  title: 'Chưa có tin tức',
                  subtitle: 'Khi có bài viết mới, chúng sẽ hiển thị ở đây.',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return _TinTucCard(
                article: article,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TinTucDetailPage(article: article),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TinTucCard extends StatelessWidget {
  const _TinTucCard({required this.article, required this.onTap});

  final TinTuc article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = article.hinhAnh?.isNotEmpty == true
        ? article.hinhAnh!
        : MediaAssets.tinTucImage;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.newspaper_rounded,
                      size: 54,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.tieuDe,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM/yyyy').format(article.ngayDang),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.noiDung,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

class TinTucDetailPage extends StatelessWidget {
  const TinTucDetailPage({super.key, required this.article});

  final TinTuc article;

  @override
  Widget build(BuildContext context) {
    final image = article.hinhAnh?.isNotEmpty == true
        ? article.hinhAnh!
        : MediaAssets.tinTucImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết tin tức')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            article.tieuDe,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(DateFormat('dd/MM/yyyy').format(article.ngayDang)),
          const SizedBox(height: 16),
          Text(article.noiDung),
        ],
      ),
    );
  }
}

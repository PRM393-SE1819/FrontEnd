import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../data/models/moderation_item.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../widgets/moderation_card.dart';

/// Màn hình "Moderation Queue" — hàng đợi kiểm duyệt nội dung.
///
/// Lấy dữ liệu qua [ModerationRepository] (API `/api/admin/reports`).
class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF2D3748);

  final ModerationRepository _repo = getIt<ModerationRepository>();
  late final TabController _tabController;

  List<ModerationItem> _queue = [];
  List<ModerationItem> _resolved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final queue = await _repo.getQueue();
    final resolved = await _repo.getResolved();
    if (!mounted) return;
    setState(() {
      _queue = queue;
      _resolved = resolved;
      _loading = false;
    });
  }

  Future<void> _handleAction(ModerationItem item, ModerationStatus status) async {
    await _repo.updateStatus(item.id, status);
    final queue = await _repo.getQueue();
    final resolved = await _repo.getResolved();
    if (!mounted) return;
    setState(() {
      _queue = queue;
      _resolved = resolved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item.userHandle} • ${_statusVerb(status)}"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _statusVerb(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return "Đã duyệt";
      case ModerationStatus.rejected:
        return "Đã từ chối";
      case ModerationStatus.escalated:
        return "Đã chuyển cấp";
      case ModerationStatus.pending:
        return "Đang chờ";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hàng đợi kiểm duyệt",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              _buildPendingBadge(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: _primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Cần xử lý"),
            Tab(text: "Đã xử lý"),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _primaryGreen),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_queue, showActions: true),
                    _buildList(_resolved, showActions: false),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 15, color: Color(0xFFDD6B20)),
          const SizedBox(width: 6),
          Text(
            "${_queue.length} mục chờ duyệt",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDD6B20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ModerationItem> items, {required bool showActions}) {
    if (items.isEmpty) {
      return _buildEmpty(showActions);
    }
    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ModerationCard(
            item: item,
            showActions: showActions,
            onAction: (status) => _handleAction(item, status),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(bool isQueue) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isQueue ? Icons.task_alt : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            isQueue ? "Đã xử lý hết!" : "Chưa có mục nào được xử lý",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

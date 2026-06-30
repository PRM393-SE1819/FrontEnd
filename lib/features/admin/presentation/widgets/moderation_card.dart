import 'package:flutter/material.dart';
import '../../data/models/moderation_item.dart';

/// Thẻ hiển thị một mục kiểm duyệt trong hàng đợi.
///
/// Khi [showActions] = true (tab Action Queue) sẽ hiện 3 nút
/// Approve / Reject / Escalate. Ngược lại (tab Resolved) hiện nhãn trạng thái.
class ModerationCard extends StatelessWidget {
  final ModerationItem item;
  final bool showActions;
  final ValueChanged<ModerationStatus>? onAction;

  const ModerationCard({
    super.key,
    required this.item,
    this.showActions = true,
    this.onAction,
  });

  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (item.imageUrl != null || _needsImage) ...[
            _buildImage(),
            const SizedBox(height: 12),
          ],
          _buildUserQuote(),
          const SizedBox(height: 14),
          if (showActions) _buildActions() else _buildStatusLabel(),
        ],
      ),
    );
  }

  // Mục "phát hiện sai" thường gắn với ảnh món ăn -> luôn chừa chỗ ảnh.
  bool get _needsImage =>
      item.flagType == ModerationFlagType.inaccurateDetection;

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(item.flagType.icon, size: 16, color: item.flagType.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.flagType.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: item.flagType.color,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Text(
          _timeAgo(item.reportedAt),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        width: double.infinity,
        color: const Color(0xFFEDF2F7),
        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserQuote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.userHandle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: "Duyệt",
            background: _primaryGreen,
            foreground: Colors.white,
            onTap: () => onAction?.call(ModerationStatus.approved),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: "Từ chối",
            background: const Color(0xFFFDECEC),
            foreground: const Color(0xFFE53E3E),
            onTap: () => onAction?.call(ModerationStatus.rejected),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: "Chuyển cấp",
            background: const Color(0xFFE7F0FE),
            foreground: const Color(0xFF2B6CB0),
            onTap: () => onAction?.call(ModerationStatus.escalated),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLabel() {
    late final Color color;
    late final String text;
    late final IconData icon;
    switch (item.status) {
      case ModerationStatus.approved:
        color = _primaryGreen;
        text = "Đã duyệt";
        icon = Icons.check_circle;
        break;
      case ModerationStatus.rejected:
        color = const Color(0xFFE53E3E);
        text = "Đã từ chối";
        icon = Icons.cancel;
        break;
      case ModerationStatus.escalated:
        color = const Color(0xFF2B6CB0);
        text = "Đã chuyển cấp";
        icon = Icons.arrow_upward;
        break;
      case ModerationStatus.pending:
        color = Colors.grey;
        text = "Đang chờ";
        icon = Icons.hourglass_empty;
        break;
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${diff.inDays} ngày trước";
  }
}

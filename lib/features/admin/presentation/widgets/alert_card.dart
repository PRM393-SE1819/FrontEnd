import 'package:flutter/material.dart';
import '../../data/models/system_alert.dart';

/// Thẻ hiển thị một cảnh báo hệ thống.
///
/// Nút hành động chính tô màu theo [SystemAlert.severity]. Nếu
/// [SystemAlert.dismissible] = true sẽ có thêm nút "Dismiss".
class AlertCard extends StatelessWidget {
  final SystemAlert alert;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.alert,
    this.onAction,
    this.onDismiss,
  });

  static const Color _textDark = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    final color = alert.severity.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Cảnh báo chưa đọc viền theo màu mức độ.
        border: alert.unread
            ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.grey.shade200),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(alert.severity.icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                _timeAgo(alert.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              if (alert.unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            alert.description,
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),
          _buildActions(color),
        ],
      ),
    );
  }

  Widget _buildActions(Color color) {
    final actionButton = Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            alert.actionLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    if (!alert.dismissible) {
      // Không cho bỏ qua -> nút hành động chiếm toàn bộ chiều ngang.
      return SizedBox(width: double.infinity, child: actionButton);
    }

    return Row(
      children: [
        Expanded(child: actionButton),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  "Dismiss",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? "1 hr ago" : "${diff.inHours} hrs ago";
    }
    return "${diff.inDays} days ago";
  }
}

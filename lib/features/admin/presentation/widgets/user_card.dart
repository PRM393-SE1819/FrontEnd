import 'package:flutter/material.dart';
import '../../data/models/admin_user.dart';

/// Thẻ hiển thị một người dùng trong User Registry.
///
/// Hiện avatar (ảnh hoặc chữ viết tắt), tên, email, vai trò, trạng thái,
/// thời điểm hoạt động gần nhất, cùng nút Sửa và Khóa/Mở khóa.
class UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const UserCard({
    super.key,
    required this.user,
    this.onEdit,
    this.onToggleStatus,
  });

  static const Color _textDark = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    final isSuspended = user.status == UserStatus.suspended;
    return Opacity(
      // Tài khoản bị khóa hiển thị mờ đi (giống Figma).
      opacity: isSuspended ? 0.65 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
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
            _buildIdentity(),
            const SizedBox(height: 12),
            _infoRow("Vai trò:", _roleBadge()),
            const SizedBox(height: 8),
            _infoRow("Trạng thái:", _statusBadge()),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _infoRow("Hoạt động:", _activeText())),
                _actionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    return Row(
      children: [
        _avatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF0FA68A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar() {
    final color = user.role.color;
    if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(user.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        user.initials,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _infoRow(String label, Widget value) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
        ),
        value,
      ],
    );
  }

  Widget _roleBadge() {
    final color = user.role.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(user.role.icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            user.role.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    final color = user.status.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          user.status.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _activeText() {
    return Text(
      _formatLastActive(user.lastActive),
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF4A5568),
      ),
    );
  }

  Widget _actionButtons() {
    final isSuspended = user.status == UserStatus.suspended;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onEdit,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF718096)),
          tooltip: "Sửa",
        ),
        IconButton(
          onPressed: onToggleStatus,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isSuspended ? Icons.check_circle_outline : Icons.block,
            size: 18,
            color: isSuspended ? const Color(0xFF006D44) : const Color(0xFFE53E3E),
          ),
          tooltip: isSuspended ? "Mở khóa" : "Khóa",
        ),
      ],
    );
  }

  String _formatLastActive(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays < 7) {
      return diff.inDays == 1 ? "1 ngày trước" : "${diff.inDays} ngày trước";
    }
    return "${time.day} thg ${time.month}, ${time.year}";
  }
}

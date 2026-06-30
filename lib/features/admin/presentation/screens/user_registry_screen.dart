import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../data/models/admin_user.dart';
import '../../domain/repositories/user_registry_repository.dart';
import '../widgets/user_card.dart';

/// Màn hình "User Registry" — quản lý người dùng, vai trò và trạng thái.
///
/// Lấy dữ liệu qua [UserRegistryRepository] (remote/API). Hỗ trợ tìm kiếm,
/// lọc theo Status/Role, phân trang, đổi trạng thái, đổi vai trò và xóa user.
class UserRegistryScreen extends StatefulWidget {
  const UserRegistryScreen({super.key});

  @override
  State<UserRegistryScreen> createState() => _UserRegistryScreenState();
}

class _UserRegistryScreenState extends State<UserRegistryScreen> {
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF2D3748);

  final UserRegistryRepository _repo = getIt<UserRegistryRepository>();
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 8;
  int _page = 1;
  String _search = '';
  Timer? _debounce;

  // Bộ lọc (null = tất cả).
  UserStatus? _filterStatus;
  int? _filterRoleId;

  PaginatedUsers? _result;
  bool _loading = true;

  bool get _hasFilter => _filterStatus != null || _filterRoleId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final result = await _repo.getUsers(
      page: _page,
      pageSize: _pageSize,
      search: _search,
      status: _filterStatus,
      roleId: _filterRoleId,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value;
      _page = 1;
      _loadData();
    });
  }

  void _goToPage(int page) {
    final totalPages = _result?.totalPages ?? 1;
    if (page < 1 || page > totalPages) return;
    _page = page;
    _loadData();
  }

  Future<void> _toggleStatus(AdminUser user) async {
    final newStatus = user.status == UserStatus.suspended
        ? UserStatus.active
        : UserStatus.suspended;
    await _repo.setUserStatus(user.id, newStatus);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${user.name} • ${newStatus.label}"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mở sheet quản lý user: đổi vai trò hoặc xóa.
  Future<void> _editUser(AdminUser user) async {
    final action = await showModalBottomSheet<_ManageResult>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ManageUserSheet(user: user),
    );
    if (action == null || !mounted) return;

    if (action.deleted) {
      await _confirmAndDelete(user);
    } else if (action.role != null && action.role != user.role) {
      await _changeRole(user, action.role!);
    }
  }

  Future<void> _changeRole(AdminUser user, UserRole role) async {
    await _repo.changeUserRole(user.id, role.roleId);
    await _loadData();
    if (!mounted) return;
    _snack("${user.name} • ${role.label}");
  }

  Future<void> _confirmAndDelete(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa người dùng"),
        content: Text(
            "Bạn có chắc muốn xóa vĩnh viễn ${user.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53E3E)),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteUser(user.id);
    // Nếu xóa item cuối của trang, lùi về trang trước.
    if ((_result?.items.length ?? 0) <= 1 && _page > 1) _page--;
    await _loadData();
    if (!mounted) return;
    _snack("Đã xóa ${user.name}");
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        status: _filterStatus,
        roleId: _filterRoleId,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _filterStatus = result.status;
      _filterRoleId = result.roleId;
      _page = 1;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryGreen,
        onPressed: () => _snack(
            "Backend không có API tạo người dùng cho admin — người dùng tự đăng ký"),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildBody()),
          if (!_loading && _result != null) _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quản lý người dùng",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Quản lý quyền truy cập, theo dõi trạng thái và phân vai trò.",
            style: TextStyle(fontSize: 13, color: Color(0xFFDD6B20)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Tìm theo tên hoặc email...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openFilterSheet,
              icon: Icon(
                _hasFilter ? Icons.filter_alt : Icons.tune,
                size: 18,
                color: _hasFilter ? _primaryGreen : _textDark,
              ),
              label: Text(
                _hasFilter ? "Bộ lọc • Bật" : "Bộ lọc",
                style: TextStyle(
                  color: _hasFilter ? _primaryGreen : _textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey[200]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primaryGreen));
    }
    final users = _result?.items ?? [];
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "Không tìm thấy người dùng",
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
    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserCard(
            user: user,
            onEdit: () => _editUser(user),
            onToggleStatus: () => _toggleStatus(user),
          );
        },
      ),
    );
  }

  Widget _buildPaginationBar() {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Hiển thị ${result.from}–${result.to} trên ${result.total} mục",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Row(
            children: [
              _pageButton(
                icon: Icons.chevron_left,
                enabled: result.page > 1,
                onTap: () => _goToPage(result.page - 1),
              ),
              const SizedBox(width: 8),
              _pageButton(
                icon: Icons.chevron_right,
                enabled: result.page < result.totalPages,
                onTap: () => _goToPage(result.page + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _primaryGreen.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? _primaryGreen : Colors.grey[400],
        ),
      ),
    );
  }
}

// =============================================================================
// Sheet quản lý user: đổi vai trò / xóa
// =============================================================================

class _ManageResult {
  final UserRole? role;
  final bool deleted;
  const _ManageResult({this.role, this.deleted = false});
}

class _ManageUserSheet extends StatefulWidget {
  final AdminUser user;
  const _ManageUserSheet({required this.user});

  @override
  State<_ManageUserSheet> createState() => _ManageUserSheetState();
}

class _ManageUserSheetState extends State<_ManageUserSheet> {
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF2D3748);

  late UserRole _role = widget.user.role;

  @override
  Widget build(BuildContext context) {
    // Chỉ cho chọn Admin / User (backend có roleId 1, 2).
    const selectable = [UserRole.admin, UserRole.user];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          Text(
            widget.user.email,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0FA68A)),
          ),
          const SizedBox(height: 20),
          const Text(
            "Vai trò",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: selectable.map((r) {
              final selected = _role == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _role = r),
                  child: Container(
                    margin: EdgeInsets.only(right: r == selectable.first ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? _primaryGreen.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _primaryGreen : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(r.icon,
                            size: 16,
                            color: selected ? _primaryGreen : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          r.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected ? _primaryGreen : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, _ManageResult(role: _role)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Lưu thay đổi",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.pop(context, const _ManageResult(deleted: true)),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text("Xóa người dùng",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53E3E),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sheet lọc: theo Status và Role
// =============================================================================

class _FilterResult {
  final UserStatus? status;
  final int? roleId;
  const _FilterResult({this.status, this.roleId});
}

class _FilterSheet extends StatefulWidget {
  final UserStatus? status;
  final int? roleId;
  const _FilterSheet({this.status, this.roleId});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF2D3748);

  late UserStatus? _status = widget.status;
  late int? _roleId = widget.roleId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Lọc người dùng",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text("Trạng thái",
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip("Tất cả", _status == null, () => setState(() => _status = null)),
              _chip("Hoạt động", _status == UserStatus.active,
                  () => setState(() => _status = UserStatus.active)),
              _chip("Đã khóa", _status == UserStatus.suspended,
                  () => setState(() => _status = UserStatus.suspended)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Vai trò",
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip("Tất cả", _roleId == null, () => setState(() => _roleId = null)),
              _chip("Quản trị", _roleId == 1, () => setState(() => _roleId = 1)),
              _chip("Người dùng", _roleId == 2, () => setState(() => _roleId = 2)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, const _FilterResult()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Xóa lọc",
                      style: TextStyle(
                          color: _textDark, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                      context, _FilterResult(status: _status, roleId: _roleId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Áp dụng",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

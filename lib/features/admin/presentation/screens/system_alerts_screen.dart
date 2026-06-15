import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../data/models/system_alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../widgets/alert_card.dart';

/// Màn hình "System Alerts" — danh sách cảnh báo hệ thống.
///
/// Dữ liệu lấy qua [AlertsRepository] (hiện là mock). Có lọc theo nhóm
/// (All / Security / System / Moderation) và bỏ qua cảnh báo.
class SystemAlertsScreen extends StatefulWidget {
  const SystemAlertsScreen({super.key});

  @override
  State<SystemAlertsScreen> createState() => _SystemAlertsScreenState();
}

class _SystemAlertsScreenState extends State<SystemAlertsScreen> {
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF2D3748);

  final AlertsRepository _repo = getIt<AlertsRepository>();

  List<SystemAlert> _alerts = [];
  bool _loading = true;

  /// null = "All", ngược lại lọc theo nhóm tương ứng.
  AlertCategory? _filter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final alerts = await _repo.getAlerts();
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _loading = false;
    });
  }

  Future<void> _dismiss(SystemAlert alert) async {
    await _repo.dismissAlert(alert.id);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Dismissed: ${alert.title}"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _runAction(SystemAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${alert.actionLabel}: ${alert.title} (coming soon)"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<SystemAlert> get _visibleAlerts {
    if (_filter == null) return _alerts;
    return _alerts.where((a) => a.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            "System Alerts",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildFilterChips(),
        const SizedBox(height: 4),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _primaryGreen))
              : _buildList(),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final entries = <(String, AlertCategory?)>[
      ("All", null),
      ("Security", AlertCategory.security),
      ("System", AlertCategory.system),
      ("Moderation", AlertCategory.moderation),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, category) = entries[index];
          final isActive = _filter == category;
          return GestureDetector(
            onTap: () => setState(() => _filter = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? _primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? _primaryGreen : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    final alerts = _visibleAlerts;
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "No alerts here",
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return AlertCard(
            alert: alert,
            onAction: () => _runAction(alert),
            onDismiss: () => _dismiss(alert),
          );
        },
      ),
    );
  }
}

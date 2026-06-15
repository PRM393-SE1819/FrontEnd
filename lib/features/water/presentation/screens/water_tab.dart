import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';

class WaterTab extends StatefulWidget {
  const WaterTab({super.key});

  @override
  State<WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<WaterTab> {
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  // Water data
  double _consumedML = 0;
  double _goalML = 2000;
  List<dynamic> _logs = [];
  List<dynamic> _reminders = [];

  // Reminder Timer and Checkers
  Timer? _reminderTimer;
  final Set<String> _notifiedTimes = {};

  final Color primaryGreen = const Color(0xFF006D44);
  final Color waterBlue = const Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    _loadWaterData();
    _startReminderCheck();
  }

  Future<void> _loadWaterData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      // 1. Get daily summary
      final summary = await ApiService.getDailyWaterSummary(dateStr);
      if (summary != null) {
        _consumedML = (summary['consumedML'] as num?)?.toDouble() ?? 0.0;
        _goalML = (summary['goalML'] as num?)?.toDouble() ?? 2000.0;
      }

      // 2. Get today's logs
      final history = await ApiService.getWaterLogHistory(date: dateStr);
      if (history != null) {
        _logs = history['items'] ?? [];
      }

      // 3. Get reminders list
      final rems = await ApiService.getWaterReminders();
      if (rems != null) {
        _reminders = rems;
      }
    } catch (e) {
      debugPrint("Error loading water data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addWater(double amount) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final res = await ApiService.addWaterLog(amount);
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged +${amount.round()} ml of Water!"),
          backgroundColor: waterBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadWaterData();
    }
  }

  Future<void> _deleteLog(int logId) async {
    final success = await ApiService.deleteWaterLog(logId);
    if (success) {
      _loadWaterData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Water log deleted"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _openCustomWaterDialog() {
    final amountController = TextEditingController(text: "250");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Water Custom Amount"),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: "Amount (ml)",
            suffixText: "ml",
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 250.0;
              Navigator.pop(context);
              _addWater(amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: waterBlue),
            child: const Text("Log", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _openUpdateGoalDialog() {
    final goalController = TextEditingController(text: _goalML.round().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Daily Water Goal"),
        content: TextField(
          controller: goalController,
          decoration: const InputDecoration(
            labelText: "Daily Target Goal (ml)",
            suffixText: "ml",
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final target = double.tryParse(goalController.text) ?? 2000.0;
              Navigator.pop(context);
              final res = await ApiService.updateWaterGoal(target);
              if (res != null) {
                _loadWaterData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Water goal updated successfully")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: waterBlue),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _addReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      final timeStr = "$hourStr:$minStr:00";

      final res = await ApiService.createWaterReminder(timeStr);
      if (res != null) {
        _loadWaterData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Water reminder added!")),
        );
      }
    }
  }

  Future<void> _deleteReminder(int reminderId) async {
    final success = await ApiService.deleteWaterReminder(reminderId);
    if (success) {
      _loadWaterData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder deleted")),
      );
    }
  }

  void _startReminderCheck() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      final currentHourMin = DateFormat('HH:mm').format(now);
      
      // Clean up past entries from cache
      _notifiedTimes.removeWhere((time) => time != currentHourMin);

      for (final reminder in _reminders) {
        final isEnabled = reminder['isEnabled'] ?? true;
        if (!isEnabled) continue;

        final reminderTimeStr = reminder['reminderTime'] ?? '';
        if (reminderTimeStr.isEmpty) continue;

        final parts = reminderTimeStr.split(':');
        if (parts.isEmpty) continue;
        final hour = parts[0].padLeft(2, '0');
        final min = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
        final remHourMin = "$hour:$min";

        if (remHourMin == currentHourMin && !_notifiedTimes.contains(currentHourMin)) {
          _notifiedTimes.add(currentHourMin);
          _showWaterReminderAlert(remHourMin);
        }
      }
    });
  }

  void _showWaterReminderAlert(String time) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.local_drink, color: waterBlue, size: 28),
              const SizedBox(width: 10),
              const Text("Drink Water!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("It's $time! Time to drink some water and stay hydrated."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Dismiss"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addWater(250);
              },
              style: ElevatedButton.styleFrom(backgroundColor: waterBlue),
              child: const Text("Log 250ml", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = _goalML > 0 ? (_consumedML / _goalML).clamp(0.0, 1.0) : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          "Water Logging & Goals",
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: waterBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildWaterVisualizerCard(percent),
                  const SizedBox(height: 25),
                  _buildQuickAddGrid(),
                  const SizedBox(height: 25),
                  _buildGoalCard(),
                  const SizedBox(height: 25),
                  _buildRemindersSection(),
                  const SizedBox(height: 25),
                  _buildLogsHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildWaterVisualizerCard(double percent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A5568)),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 14,
                  backgroundColor: Colors.blue.shade50,
                  color: waterBlue,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_drink, color: waterBlue, size: 36),
                  const SizedBox(height: 4),
                  Text(
                    "${_consumedML.round()} ml",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: waterBlue),
                  ),
                  Text(
                    "Target: ${_goalML.round()} ml",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(
            percent >= 1.0
                ? "🎉 Fantastic job! Goal achieved!"
                : "You need ${(_goalML - _consumedML).clamp(0, double.infinity).round()} ml more to reach your goal.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: percent >= 1.0 ? Colors.green[700] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildQuickAddGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Log Water",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _waterQuickBtn(Icons.local_cafe, "Cup", 250)),
            const SizedBox(width: 12),
            Expanded(child: _waterQuickBtn(Icons.local_drink, "Bottle", 500)),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _openCustomWaterDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: waterBlue, size: 28),
                      const SizedBox(height: 4),
                      Text("Custom", style: TextStyle(fontWeight: FontWeight.bold, color: waterBlue, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _waterQuickBtn(IconData icon, String label, double amount) {
    return InkWell(
      onTap: () => _addWater(amount),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: waterBlue, size: 28),
            const SizedBox(height: 4),
            Text("+${amount.round()}ml", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: waterBlue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Daily Water Target", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text("Goal: ${_goalML.round()} ml", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
          OutlinedButton(
            onPressed: _openUpdateGoalDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: waterBlue,
              side: BorderSide(color: waterBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Edit Goal"),
          )
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Water Reminders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: Icon(Icons.add_alarm, color: waterBlue),
                onPressed: _addReminder,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _reminders.isEmpty
              ? Text("No alarms configured.", style: TextStyle(color: Colors.grey[500], fontSize: 13))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reminders.length,
                  itemBuilder: (context, idx) {
                    final reminder = _reminders[idx];
                    final time = reminder['reminderTime'] ?? '00:00';
                    final remId = reminder['reminderId'];
                    final isEnabled = reminder['isEnabled'] ?? true;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isEnabled ? Icons.alarm : Icons.alarm_off,
                        color: isEnabled ? waterBlue : Colors.grey,
                        size: 20,
                      ),
                      title: Text(
                        time,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? const Color(0xFF2D3748) : Colors.grey,
                          decoration: isEnabled ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isEnabled,
                            activeTrackColor: waterBlue,
                            onChanged: (val) async {
                              await ApiService.saveReminderEnabledState(remId, val);
                              _loadWaterData();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteReminder(remId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildLogsHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Water Intake logs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _logs.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Text("No water logged today yet.", style: TextStyle(color: Colors.grey[400])),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _logs.length,
                itemBuilder: (context, idx) {
                  final log = _logs[idx];
                  final logTime = DateTime.parse(log['loggedAt']).toLocal();
                  final timeStr = DateFormat('hh:mm a').format(logTime);
                  final amt = (log['amountML'] as num?)?.toDouble() ?? 0.0;
                  final logId = log['waterLogId'];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.local_drink, color: waterBlue),
                      title: Text("${amt.round()} ml"),
                      subtitle: Text(timeStr),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => _deleteLog(logId),
                      ),
                    ),
                  );
                },
              )
      ],
    );
  }
}

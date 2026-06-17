import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/network/api_service.dart';



class WeightTab extends StatefulWidget {
  const WeightTab({super.key});

  @override
  State<WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends State<WeightTab> {
  bool _isLoading = false;

  // Weight & Body Fat stats
  double? _startWeight;
  double? _currentWeight;
  double? _weightChanged;
  double? _targetWeight;
  
  double? _startBodyFat;
  double? _currentBodyFat;
  double? _bodyFatChanged;

  List<dynamic> _logs = [];
  List<dynamic> _chartHistory = [];
  List<dynamic> _bodyFatHistory = [];

  final Color primaryGreen = const Color(0xFF006D44);
  final Color tealAccent = const Color(0xFF319795);

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get Weight Summary
      final summary = await ApiService.getWeightSummary();
      if (summary != null) {
        _currentWeight = (summary['currentWeight'] as num?)?.toDouble();
        _targetWeight = (summary['targetWeight'] as num?)?.toDouble();
        _currentBodyFat = (summary['currentBodyFat'] as num?)?.toDouble();
      }

      // 2. Get Weight Logs
      final logsRes = await ApiService.getWeightLogs(page: 1, pageSize: 20);
      if (logsRes != null) {
        _logs = logsRes['items'] ?? [];
      }

      // 3. Get Progress Statistics for the last 30 days
      final endStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final startStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
      final progress = await ApiService.getProgressStatistics(startStr, endStr);

      if (progress != null) {
        _startWeight = (progress['startWeight'] as num?)?.toDouble();
        _currentWeight = (progress['currentWeight'] as num?)?.toDouble() ?? _currentWeight;
        _weightChanged = (progress['weightChanged'] as num?)?.toDouble();
        _startBodyFat = (progress['startBodyFat'] as num?)?.toDouble();
        _currentBodyFat = (progress['currentBodyFat'] as num?)?.toDouble() ?? _currentBodyFat;
        _bodyFatChanged = (progress['bodyFatChanged'] as num?)?.toDouble();
        _chartHistory = progress['history'] ?? [];
      }

      // Load body fat analysis history
      final bfHistory = await ApiService.getBodyFatHistory();
      if (bfHistory != null) {
        _bodyFatHistory = bfHistory;
      }
    } catch (e) {
      debugPrint("Error loading weight logs: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLogWeightDialog({Map<String, dynamic>? editLog}) {
    final weightController = TextEditingController(text: editLog?['weight']?.toString() ?? _currentWeight?.toString() ?? '70');
    final fatController = TextEditingController(text: editLog?['bodyFat']?.toString() ?? _currentBodyFat?.toString() ?? '18');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(editLog == null ? "Log Weight & Body Fat" : "Update Weight Log"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: "Weight (kg)",
                suffixText: "kg",
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: fatController,
              decoration: const InputDecoration(
                labelText: "Body Fat (%) (Optional)",
                suffixText: "%",
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final w = double.tryParse(weightController.text) ?? 70.0;
              final f = double.tryParse(fatController.text);

              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              Map<String, dynamic>? res;
              if (editLog == null) {
                res = await ApiService.createWeightLog(w, f);
              } else {
                res = await ApiService.updateWeightLog(editLog['weightLogId'], w, f);
              }

              if (context.mounted) Navigator.pop(context); // Close loading

              if (res != null) {
                _loadWeightData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(editLog == null ? "Weight logged successfully!" : "Log updated successfully!"),
                    backgroundColor: primaryGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _openBodyFatCalcDialog() {
    final waistCtrl = TextEditingController();
    final neckCtrl = TextEditingController();
    final hipCtrl = TextEditingController();
    bool isCalculating = false;
    Map<String, dynamic>? result;

    // Get gender/age/height/weight from current profile if available
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Body Fat Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 340,
            child: result != null
                ? _buildBodyFatResultView(result!)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your body measurements (cm) to estimate body fat % using the US Navy formula.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: waistCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Waist circumference (cm) *',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: neckCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Neck circumference (cm) *',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hipCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Hip circumference (cm) — female only',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      if (isCalculating) ...
                          [const SizedBox(height: 16), const Center(child: CircularProgressIndicator())],
                    ],
                  ),
          ),
          actions: result != null
              ? [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadWeightData();
                    },
                    child: const Text('Done'),
                  )
                ]
              : [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: tealAccent),
                    onPressed: isCalculating
                        ? null
                        : () async {
                            final waist = double.tryParse(waistCtrl.text);
                            final neck = double.tryParse(neckCtrl.text);
                            if (waist == null || neck == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter waist and neck measurements')),
                              );
                              return;
                            }
                            setS(() => isCalculating = true);
                            final hip = double.tryParse(hipCtrl.text);
                            final res = await ApiService.analyzeBodyFatFromMeasurements(
                              gender: 'Male', // default; user can set in profile
                              age: 25,
                              height: 170,
                              weight: _currentWeight ?? 70,
                              waist: waist,
                              neck: neck,
                              hip: hip,
                            );
                            setS(() {
                              isCalculating = false;
                              result = res;
                            });
                          },
                    child: const Text('Calculate', style: TextStyle(color: Colors.white)),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildBodyFatResultView(Map<String, dynamic> result) {
    final bf = (result['estimatedBodyFat'] as num?)?.toDouble() ?? 0.0;
    final category = result['category'] ?? '';
    final assessment = result['healthAssessment'] ?? '';
    final recommendation = result['recommendation'] ?? '';

    Color catColor = primaryGreen;
    if (category.toString().toLowerCase().contains('obese')) catColor = Colors.redAccent;
    else if (category.toString().toLowerCase().contains('average')) catColor = Colors.orange;
    else if (category.toString().toLowerCase().contains('athlete')) catColor = Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text('${bf.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: catColor)),
              Chip(
                label: Text(category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: catColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (assessment.isNotEmpty) ...
            [Text('Health: $assessment', style: const TextStyle(fontSize: 13)), const SizedBox(height: 8)],
        if (recommendation.isNotEmpty)
          Text('Tip: $recommendation', style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          "Weight & Body Fat Tracker",
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildSummaryGrid(),
                  const SizedBox(height: 25),
                  _buildChartCard(),
                  const SizedBox(height: 25),
                  _buildBodyFatCalculatorBanner(),
                  const SizedBox(height: 25),
                  _buildBodyFatHistorySection(),
                  const SizedBox(height: 25),
                  _buildLogHistorySection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _openLogWeightDialog(),
        backgroundColor: primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      children: [
        // Weight comparison card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weight progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryMetric("Start", _startWeight != null ? "${_startWeight!.toStringAsFixed(1)} kg" : "-- kg"),
                  _summaryMetric("Current", _currentWeight != null ? "${_currentWeight!.toStringAsFixed(1)} kg" : "-- kg"),
                  _summaryMetric("Target", _targetWeight != null ? "${_targetWeight!.toStringAsFixed(1)} kg" : "-- kg"),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Weight Change:",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Text(
                    _weightChanged != null
                        ? "${_weightChanged! > 0 ? '+' : ''}${_weightChanged!.toStringAsFixed(1)} kg"
                        : "-- kg",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _weightChanged != null
                          ? (_weightChanged! <= 0 ? Colors.green[700] : Colors.redAccent)
                          : const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        // Body fat comparison card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Body Fat progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryMetric("Start Fat", _startBodyFat != null ? "${_startBodyFat!.toStringAsFixed(1)}%" : "--%"),
                  _summaryMetric("Current Fat", _currentBodyFat != null ? "${_currentBodyFat!.toStringAsFixed(1)}%" : "--%"),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Body Fat Change:",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Text(
                    _bodyFatChanged != null
                        ? "${_bodyFatChanged! > 0 ? '+' : ''}${_bodyFatChanged!.toStringAsFixed(1)}%"
                        : "--%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _bodyFatChanged != null
                          ? (_bodyFatChanged! <= 0 ? Colors.green[700] : Colors.redAccent)
                          : const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("30-Day Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _chartHistory.isEmpty || _chartHistory.length < 2
              ? Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: Text(
                    "Need at least 2 logs to display trend chart.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartHistory.asMap().entries.map((entry) {
                            final idx = entry.key.toDouble();
                            final val = (entry.value['weight'] as num?)?.toDouble() ?? 0.0;
                            return FlSpot(idx, val);
                          }).toList(),
                          isCurved: true,
                          color: primaryGreen,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                        )
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBodyFatCalculatorBanner() {
    return InkWell(
      onTap: _openBodyFatCalcDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tealAccent, const Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: tealAccent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Body Fat Calculator',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('US Navy formula — enter measurements, no photo needed',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyFatHistorySection() {
    if (_bodyFatHistory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Body Fat Analysis History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bodyFatHistory.length,
          itemBuilder: (context, idx) {
            final rec = _bodyFatHistory[idx];
            final bf = (rec['estimatedBodyFat'] as num?)?.toDouble() ?? 0.0;
            final category = rec['category'] ?? '';
            final createdAt = rec['createdAt'] != null
                ? DateFormat('MMM dd, yyyy').format(DateTime.parse(rec['createdAt']).toLocal())
                : '';
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: tealAccent.withOpacity(0.1),
                  child: Text('${bf.round()}%',
                      style: TextStyle(color: tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                title: Text('${bf.toStringAsFixed(1)}% — $category'),
                subtitle: Text(createdAt),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final success = await ApiService.deleteBodyFatHistory(rec['id']);
                    if (success) _loadWeightData();
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Weight Log History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _logs.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Text('No weight logged yet.', style: TextStyle(color: Colors.grey[400])),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _logs.length,
                itemBuilder: (context, idx) {
                  final log = _logs[idx];
                  final logTime = DateTime.parse(log['loggedAt']).toLocal();
                  final dateStr = DateFormat('MMM dd, yyyy').format(logTime);
                  final weight = (log['weight'] as num?)?.toDouble() ?? 0.0;
                  final bodyFat = (log['bodyFat'] as num?)?.toDouble();

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryGreen.withOpacity(0.1),
                        child: Icon(Icons.monitor_weight_outlined, color: primaryGreen, size: 20),
                      ),
                      title: Text('${weight.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(dateStr),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (bodyFat != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tealAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${bodyFat.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      color: tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                            onPressed: () => _openLogWeightDialog(editLog: log),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Log'),
                                  content: const Text('Remove this weight log?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final success = await ApiService.deleteWeightLog(log['weightLogId']);
                                if (success) _loadWeightData();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

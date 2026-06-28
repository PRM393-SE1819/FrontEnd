import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../cubit/weight_cubit.dart';
import '../cubit/weight_state.dart';
import '../../domain/entities/weight_log.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';

class WeightTab extends StatefulWidget {
  const WeightTab({super.key});

  @override
  State<WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends State<WeightTab> {
  final Color primaryGreen = const Color(0xFF006D44);
  final Color tealAccent = const Color(0xFF319795);

  @override
  void initState() {
    super.initState();
    context.read<WeightCubit>().loadWeightData();
  }

  void _openLogWeightDialog({WeightLog? editLog, double? currentWeight, double? currentBodyFat}) {
    final weightController = TextEditingController(
      text: editLog?.weight.toString() ?? currentWeight?.toString() ?? '70',
    );
    final fatController = TextEditingController(
      text: editLog?.bodyFat?.toString() ?? currentBodyFat?.toString() ?? '18',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(editLog == null ? "Ghi nhận Cân nặng & Lượng mỡ" : "Cập nhật lượt ghi nhận"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: "Cân nặng (kg) *",
                suffixText: "kg",
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: fatController,
              decoration: const InputDecoration(
                labelText: "Tỉ lệ mỡ cơ thể (%) (Tùy chọn)",
                suffixText: "%",
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(weightController.text) ?? 70.0;
              final f = double.tryParse(fatController.text);

              Navigator.pop(dialogCtx);
              
              if (editLog == null) {
                context.read<WeightCubit>().addWeightLog(w, f);
              } else {
                context.read<WeightCubit>().updateWeightLog(editLog.weightLogId, w, f);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _openBodyFatCalcDialog(double? currentWeight) {
    final waistCtrl = TextEditingController();
    final neckCtrl = TextEditingController();
    final hipCtrl = TextEditingController();
    bool isCalculating = false;
    Map<String, dynamic>? result;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Công cụ tính Tỷ lệ mỡ', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 340,
            child: result != null
                ? _buildBodyFatResultView(result!)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nhập số đo cơ thể (cm) để ước tính tỷ lệ mỡ theo công thức US Navy (Hải quân Hoa Kỳ).',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: waistCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Số đo vòng eo (cm) *',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: neckCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Số đo vòng cổ (cm) *',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hipCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Số đo vòng hông (cm) — Chỉ dành cho Nữ',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      if (isCalculating) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator())
                      ],
                    ],
                  ),
          ),
          actions: result != null
              ? [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      context.read<WeightCubit>().loadWeightData();
                    },
                    child: const Text('Hoàn thành'),
                  )
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: tealAccent),
                    onPressed: isCalculating
                        ? null
                        : () async {
                            final waist = double.tryParse(waistCtrl.text);
                            final neck = double.tryParse(neckCtrl.text);
                            if (waist == null || neck == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập vòng eo và vòng cổ')),
                              );
                              return;
                            }
                            setS(() => isCalculating = true);
                            final hip = double.tryParse(hipCtrl.text);
                            
                            final res = await context.read<WeightCubit>().calculateBodyFat(
                              gender: 'Male', // default
                              age: 25,
                              height: 170,
                              weight: currentWeight ?? 70,
                              waist: waist,
                              neck: neck,
                              hip: hip,
                            );

                            setS(() {
                              isCalculating = false;
                              result = res;
                            });
                          },
                    child: const Text('Tính toán', style: TextStyle(color: Colors.white)),
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
    if (category.toString().toLowerCase().contains('obese')) {
      catColor = Colors.redAccent;
    } else if (category.toString().toLowerCase().contains('average')) {
      catColor = Colors.orange;
    } else if (category.toString().toLowerCase().contains('athlete')) {
      catColor = Colors.blue;
    }

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
        if (assessment.isNotEmpty) ...[
          Text('Sức khỏe: $assessment', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8)
        ],
        if (recommendation.isNotEmpty)
          Text('Lời khuyên: $recommendation', style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WeightCubit, WeightState>(
      listener: (context, state) {
        if (state is WeightLoaded && state.toastMessage != null) {
          try {
            context.read<DashboardCubit>().loadDashboardData(showLoading: false);
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.toastMessage!),
              backgroundColor: primaryGreen,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is WeightInitial || state is WeightLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
            body: Center(child: CircularProgressIndicator(color: primaryGreen)),
          );
        }

        if (state is WeightError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            ),
          );
        }

        if (state is WeightLoaded) {
          final summary = state.summary;
          final progress = state.progress;

          final startWeight = progress?.startWeight;
          final currentWeight = progress?.currentWeight ?? summary?.currentWeight;
          final targetWeight = summary?.targetWeight;
          final weightChanged = progress?.weightChanged;

          final startBodyFat = progress?.startBodyFat;
          final currentBodyFat = progress?.currentBodyFat ?? summary?.currentBodyFat;
          final bodyFatChanged = progress?.bodyFatChanged;

          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
            appBar: AppBar(
              title: const Text(
                "Theo dõi Cân nặng & Lượng mỡ",
                style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      AnimatedFadeSlide(
                        delay: 0,
                        child: _buildSummaryGrid(
                          startWeight: startWeight,
                          currentWeight: currentWeight,
                          targetWeight: targetWeight,
                          weightChanged: weightChanged,
                          startBodyFat: startBodyFat,
                          currentBodyFat: currentBodyFat,
                          bodyFatChanged: bodyFatChanged,
                        ),
                      ),
                      const SizedBox(height: 25),
                      AnimatedFadeSlide(
                        delay: 100,
                        child: _buildChartCard(progress?.history ?? []),
                      ),
                      const SizedBox(height: 25),
                      AnimatedFadeSlide(
                        delay: 150,
                        child: _buildBodyFatCalculatorBanner(currentWeight),
                      ),
                      const SizedBox(height: 25),
                      AnimatedFadeSlide(
                        delay: 200,
                        child: _buildBodyFatHistorySection(state.bodyFatHistory),
                      ),
                      const SizedBox(height: 25),
                      AnimatedFadeSlide(
                        delay: 250,
                        child: _buildLogHistorySection(state.logs, currentWeight, currentBodyFat),
                      ),
                    ],
                  ),
                ),
                if (state.isOperationLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: null,
              onPressed: () => _openLogWeightDialog(currentWeight: currentWeight, currentBodyFat: currentBodyFat),
              backgroundColor: primaryGreen,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryGrid({
    double? startWeight,
    double? currentWeight,
    double? targetWeight,
    double? weightChanged,
    double? startBodyFat,
    double? currentBodyFat,
    double? bodyFatChanged,
  }) {
    return Column(
      children: [
        // Weight comparison card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tiến trình cân nặng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryMetric("Bắt đầu", startWeight != null ? "${startWeight.toStringAsFixed(1)} kg" : "-- kg"),
                  _summaryMetric("Hiện tại", currentWeight != null ? "${currentWeight.toStringAsFixed(1)} kg" : "-- kg"),
                  _summaryMetric("Mục tiêu", targetWeight != null ? "${targetWeight.toStringAsFixed(1)} kg" : "-- kg"),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Thay đổi cân nặng:",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Text(
                    weightChanged != null
                        ? "${weightChanged > 0 ? '+' : ''}${weightChanged.toStringAsFixed(1)} kg"
                        : "-- kg",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: weightChanged != null
                          ? (weightChanged <= 0 ? Colors.green[700] : Colors.redAccent)
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tiến trình mỡ cơ thể", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryMetric("Mỡ bắt đầu", startBodyFat != null ? "${startBodyFat.toStringAsFixed(1)}%" : "--%"),
                  _summaryMetric("Mỡ hiện tại", currentBodyFat != null ? "${currentBodyFat.toStringAsFixed(1)}%" : "--%"),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Thay đổi mỡ cơ thể:",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Text(
                    bodyFatChanged != null
                        ? "${bodyFatChanged > 0 ? '+' : ''}${bodyFatChanged.toStringAsFixed(1)}%"
                        : "--%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: bodyFatChanged != null
                          ? (bodyFatChanged <= 0 ? Colors.green[700] : Colors.redAccent)
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

  Widget _buildChartCard(List<WeightLog> history) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Xu hướng 30 ngày qua", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          history.isEmpty || history.length < 2
              ? Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: Text(
                    "Cần ít nhất 2 lượt ghi nhận để hiển thị biểu đồ xu hướng.",
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
                          spots: history.asMap().entries.map((entry) {
                            final idx = entry.key.toDouble();
                            final val = entry.value.weight;
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

  Widget _buildBodyFatCalculatorBanner(double? currentWeight) {
    return InkWell(
      onTap: () => _openBodyFatCalcDialog(currentWeight),
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
            BoxShadow(color: tealAccent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Công cụ tính Tỷ lệ mỡ cơ thể',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Công thức US Navy — nhập số đo, không cần chụp ảnh',
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

  Widget _buildBodyFatHistorySection(List<dynamic> bodyFatHistory) {
    if (bodyFatHistory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch sử phân tích mỡ cơ thể', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bodyFatHistory.length,
          itemBuilder: (context, idx) {
            final rec = bodyFatHistory[idx];
            final bf = (rec['estimatedBodyFat'] as num?)?.toDouble() ?? 0.0;
            final category = rec['category'] ?? '';
            final createdAt = rec['createdAt'] != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(rec['createdAt']).toLocal())
                : '';
            return AnimatedFadeSlide(
              key: ValueKey(rec['id']),
              delay: (idx * 50).clamp(0, 300),
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tealAccent.withValues(alpha: 0.1),
                    child: Text('${bf.round()}%',
                        style: TextStyle(color: tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text('${bf.toStringAsFixed(1)}% — $category'),
                  subtitle: Text(createdAt),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => context.read<WeightCubit>().deleteBodyFatRecord(rec['id']),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogHistorySection(List<WeightLog> logs, double? currentWeight, double? currentBodyFat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch sử ghi nhận cân nặng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        logs.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Text('Chưa có cân nặng nào được ghi nhận.', style: TextStyle(color: Colors.grey[400])),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, idx) {
                  final log = logs[idx];
                  final logTime = log.loggedAt.toLocal();
                  final dateStr = DateFormat('dd/MM/yyyy').format(logTime);
                  final weight = log.weight;
                  final bodyFat = log.bodyFat;

                  return AnimatedFadeSlide(
                    key: ValueKey(log.weightLogId),
                    delay: (idx * 50).clamp(0, 300),
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryGreen.withValues(alpha: 0.1),
                              child: Icon(Icons.monitor_weight_outlined, color: primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${weight.toStringAsFixed(1)} kg',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (bodyFat != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: tealAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${bodyFat.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                            color: tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                  onPressed: () => _openLogWeightDialog(
                                    editLog: log,
                                    currentWeight: currentWeight,
                                    currentBodyFat: currentBodyFat,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Xóa nhật ký'),
                                        content: const Text('Bạn có chắc muốn xóa lượt ghi nhận cân nặng này?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      context.read<WeightCubit>().deleteWeightLog(log.weightLogId);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

class AnimatedFadeSlide extends StatelessWidget {
  final Widget child;
  final int delay;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 15),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isContextLoading = true;
  bool _isScanningImage = false;
  Uint8List? _scannedImageBytes;
  String? _scannedImageBase64;

  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _conversationHistory = [];
  Map<String, dynamic>? _userContext;

  static const Color primaryGreen = Color(0xFF006D44);
  static const Color lightGreen = Color(0xFFE6F4EE);
  static const Color darkBg = Color(0xFFF0FDF4);

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final nutrition = await ApiService.getDailyNutritionSummary(today);
      final weight = await ApiService.getWeightSummary();
      setState(() {
        _userContext = {
          'calories': (nutrition?['caloriesConsumed'] as num?)?.round() ?? 0,
          'calorieTarget': (nutrition?['caloriesTarget'] as num?)?.round() ?? 2000,
          'protein': (nutrition?['proteinConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
          'proteinTarget': (nutrition?['proteinTarget'] as num?)?.round() ?? 150,
          'carbs': (nutrition?['carbConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
          'carbTarget': (nutrition?['carbTarget'] as num?)?.round() ?? 250,
          'fat': (nutrition?['fatConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
          'fatTarget': (nutrition?['fatTarget'] as num?)?.round() ?? 70,
          'weight': (weight?['currentWeight'] as num?)?.toString() ?? 'N/A',
        };
        _isContextLoading = false;
      });
    } catch (e) {
      setState(() => _isContextLoading = false);
    }

    // Add welcome message
    _messages.add(_ChatMessage(
      text: "Xin chào! Tôi là NutriAI, trợ lý dinh dưỡng AI của bạn 🥗\n\nTôi có thể giúp bạn:\n• Tư vấn chế độ ăn uống cá nhân\n• Phân tích dữ liệu dinh dưỡng hôm nay\n• Gợi ý thực đơn và món ăn lành mạnh\n• Giải thích về protein, carbs, fat\n• Hỗ trợ đạt mục tiêu cân nặng\n\nHỏi tôi bất cứ điều gì về dinh dưỡng của bạn!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await ApiService.sendAiNutritionMessage(
      userMessage: text,
      conversationHistory: _conversationHistory,
      userContext: _userContext,
    );

    _conversationHistory.add({"role": "user", "content": text});

    if (reply != null) {
      final content = reply['content'] as String? ?? '';
      final reasoning = reply['reasoning_details'] as String?;

      _conversationHistory.add({
        "role": "assistant",
        "content": content,
        if (reasoning != null) "reasoning_details": reasoning,
      });

      setState(() {
        _messages.add(_ChatMessage(
          text: content,
          isUser: false,
          timestamp: DateTime.now(),
          reasoning: reasoning,
        ));
        _isLoading = false;
      });
    } else {
      setState(() {
        _messages.add(_ChatMessage(
          text: "Xin lỗi, tôi không thể kết nối được lúc này. Vui lòng thử lại sau.",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndScanFoodImage() async {
    if (!kIsWeb) return;
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();

    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;

    final file = input.files![0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    final dataUrl = reader.result as String;
    // Extract base64 part after "data:image/...;base64,"
    final base64Data = dataUrl.split(',').last;
    final bytes = base64Decode(base64Data);

    setState(() {
      _scannedImageBytes = bytes;
      _scannedImageBase64 = base64Data;
      _isScanningImage = true;
      _messages.add(_ChatMessage(
        text: "📸 Đã tải ảnh thức ăn. Đang phân tích dinh dưỡng...",
        isUser: true,
        timestamp: DateTime.now(),
        imageBytes: bytes,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    // Send image to OpenRouter vision model
    final reply = await ApiService.analyzeFoodImage(
      imageBase64: base64Data,
      mimeType: file.type,
      userContext: _userContext,
    );

    setState(() {
      _isScanningImage = false;
      _isLoading = false;
      _scannedImageBase64 = null;
      _scannedImageBytes = null;
    });

    if (reply != null) {
      _conversationHistory.add({"role": "user", "content": "[User uploaded a food image for analysis]"}); 
      _conversationHistory.add({"role": "assistant", "content": reply});

      Map<String, dynamic>? parsedJson;
      try {
        String cleaned = reply.trim();
        if (cleaned.startsWith("```")) {
          final lines = cleaned.split("\n");
          if (lines.first.startsWith("```json") || lines.first.startsWith("```")) {
            lines.removeAt(0);
          }
          if (lines.isNotEmpty && lines.last.startsWith("```")) {
            lines.removeLast();
          }
          cleaned = lines.join("\n").trim();
        }
        parsedJson = jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("Failed to parse vision response as JSON: $e");
      }

      setState(() {
        _messages.add(_ChatMessage(
          text: parsedJson != null && parsedJson['message'] != null ? parsedJson['message'] : reply,
          isUser: false,
          timestamp: DateTime.now(),
          foodScanResult: parsedJson,
        ));
      });
    } else {
      setState(() {
        _messages.add(_ChatMessage(
          text: "Không thể phân tích ảnh. Vui lòng thử lại.",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006D44), Color(0xFF00A86B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_alt, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Nutrition Coach",
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A86B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Online • NutriAI",
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_isContextLoading && _userContext != null)
            IconButton(
              icon: Icon(Icons.info_outline, color: primaryGreen),
              tooltip: "Today's nutrition context",
              onPressed: _showContextPanel,
            ),
        ],
      ),
      body: Column(
        children: [
          // Context summary bar
          if (!_isContextLoading && _userContext != null) _buildContextBar(),

          // Quick prompts
          _buildQuickPrompts(),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildContextBar() {
    final cal = _userContext!['calories'] ?? 0;
    final calTarget = _userContext!['calorieTarget'] ?? 2000;
    final pct = calTarget > 0 ? (cal / calTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: lightGreen,
        border: Border(bottom: BorderSide(color: Colors.green.shade100)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange[700], size: 16),
          const SizedBox(width: 4),
          Text(
            "$cal / $calTarget kcal",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: Colors.green.shade100,
                color: primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "P: ${_userContext!['protein']}g  C: ${_userContext!['carbs']}g  F: ${_userContext!['fat']}g",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    final prompts = [
      "📊 Phân tích dinh dưỡng hôm nay",
      "🥗 Gợi ý bữa tối",
      "💪 Thực phẩm giàu protein",
      "⚖️ Mẹo giảm cân",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: prompts.map((p) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(p, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.green.shade200),
              onPressed: () {
                _messageController.text = p.replaceAll(RegExp(r'[\u{1F300}-\u{1FFFF}]', unicode: true), '').trim();
                _sendMessage();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006D44), Color(0xFF00A86B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_alt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? primaryGreen
                    : msg.isError
                        ? Colors.red.shade50
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        msg.imageBytes!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (msg.reasoning != null && msg.reasoning!.isNotEmpty) ...[
                    ReasoningCollapseWidget(reasoning: msg.reasoning!),
                  ],
                  if (msg.foodScanResult != null) ...[
                    _buildStructuredFoodScan(msg.foodScanResult!),
                  ] else ...[
                    Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: msg.isUser ? Colors.white : const Color(0xFF2D3748),
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: msg.isUser ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006D44), Color(0xFF00A86B)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_alt, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "Hỏi về dinh dưỡng của bạn...",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    prefixIcon: kIsWeb
                        ? IconButton(
                            icon: Icon(Icons.camera_alt_outlined, color: Colors.grey[400], size: 20),
                            tooltip: "Scan food with camera",
                            onPressed: _isScanningImage ? null : _pickAndScanFoodImage,
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006D44), Color(0xFF00A86B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006D44).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Nutrition Data",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3748)),
              ),
              const Text(
                "This data is used to personalize AI responses",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _contextRow(Icons.local_fire_department, "Calories",
                  "${_userContext!['calories']} / ${_userContext!['calorieTarget']} kcal", Colors.orange),
              _contextRow(Icons.fitness_center, "Protein",
                  "${_userContext!['protein']}g / ${_userContext!['proteinTarget']}g", Colors.red.shade400),
              _contextRow(Icons.grain, "Carbs",
                  "${_userContext!['carbs']}g / ${_userContext!['carbTarget']}g", Colors.amber.shade600),
              _contextRow(Icons.water_drop, "Fat",
                  "${_userContext!['fat']}g / ${_userContext!['fatTarget']}g", Colors.blue.shade400),
              _contextRow(Icons.monitor_weight_outlined, "Weight", "${_userContext!['weight']} kg", primaryGreen),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _contextRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        ],
      ),
    );
  }

  Widget _buildStructuredFoodScan(Map<String, dynamic> res) {
    final success = res['success'] ?? true;
    if (!success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                "Không nhận diện được món ăn",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            res['message'] ?? "Vui lòng chụp lại ảnh rõ nét hơn.",
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.4),
          ),
        ],
      );
    }

    final items = res['items'] as List<dynamic>? ?? [];
    final totalNutr = res['total_nutrition'] as Map<String, dynamic>?;
    final healthRating = res['health_rating'] ?? "Chưa đánh giá";
    final advice = res['advice'] ?? "";
    final mealType = res['meal_type'] ?? "";
    final alternatives = res['alternatives'] as List<dynamic>? ?? [];

    Color ratingColor = Colors.grey;
    if (healthRating.toString().contains("Tốt")) ratingColor = Colors.green;
    else if (healthRating.toString().contains("Trung bình")) ratingColor = Colors.orange;
    else if (healthRating.toString().contains("Hạn chế")) ratingColor = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: primaryGreen, size: 20),
                const SizedBox(width: 6),
                const Text(
                  "Phân tích dinh dưỡng",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A202C)),
                ),
              ],
            ),
            if (mealType.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mealType.toString().toUpperCase(),
                  style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
          ],
        ),
        const Divider(height: 20),
        ...items.map((itemObj) {
          final item = itemObj as Map<String, dynamic>;
          final nameVi = item['name_vi'] ?? "Món ăn";
          final nameEn = item['name_en'] ?? "";
          final portion = item['portion_size'] ?? "";
          final multiplier = (item['portion_multiplier'] as num?)?.toDouble() ?? 1.0;
          final weight = (item['weight_grams'] as num?)?.toDouble() ?? 0.0;
          final nutr = item['nutrition'] as Map<String, dynamic>?;
          final ingredients = item['ingredients'] as List<dynamic>? ?? [];
          final flags = item['dietary_flags'] as Map<String, dynamic>? ?? {};

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameVi,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
                ),
                if (nameEn.isNotEmpty)
                  Text(
                    nameEn,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.restaurant_menu, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "Khẩu phần: $portion${multiplier != 1.0 ? ' (${multiplier}x)' : ''}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    if (weight > 0) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "${weight.round()}g",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                if (nutr != null) _buildNutritionGrid(nutr),
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text("Thành phần:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4A5568))),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: ingredients.map((ing) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(ing.toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF4A5568))),
                      );
                    }).toList(),
                  ),
                ],
                if (flags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (flags['vegetarian'] == true) _flagChip("Chay 🌱", Colors.green),
                      if (flags['vegan'] == true) _flagChip("Thuần chay 🟢", Colors.teal),
                      if (flags['gluten_free'] == true) _flagChip("Gluten-Free 🌾", Colors.orange),
                      if (flags['high_protein'] == true) _flagChip("Đạm cao 💪", Colors.blue),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
        if (items.length > 1 && totalNutr != null) ...[
          const Text("Tổng dinh dưỡng bữa ăn:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3748))),
          const SizedBox(height: 6),
          _buildNutritionGrid(totalNutr),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            const Text("Đánh giá sức khỏe: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4A5568))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ratingColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                healthRating.toString(),
                style: TextStyle(color: ratingColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (advice.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: primaryGreen, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    advice.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.green.shade900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (alternatives.isNotEmpty) ...[
          const Text("Gợi ý khác:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF718096))),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: alternatives.map((alt) {
              final name = alt['name'] ?? "";
              final conf = (alt['confidence'] as num?)?.toDouble() ?? 0.0;
              return Text(
                "$name (${(conf * 100).round()}%)",
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _flagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9),
      ),
    );
  }

  Widget _buildNutritionGrid(Map<String, dynamic> nutr) {
    final cal = (nutr['calories'] as num?)?.toInt() ?? 0;
    final prot = (nutr['protein'] as num?)?.toDouble() ?? 0.0;
    final carb = (nutr['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (nutr['fat'] as num?)?.toDouble() ?? 0.0;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 1.6,
      children: [
        _nutrCell("Calories", "$cal kcal", Colors.red),
        _nutrCell("Đạm (P)", "${prot.toStringAsFixed(1)}g", Colors.blue),
        _nutrCell("Carb (C)", "${carb.toStringAsFixed(1)}g", Colors.orange),
        _nutrCell("Béo (F)", "${fat.toStringAsFixed(1)}g", Colors.purple),
      ],
    );
  }

  Widget _nutrCell(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final Uint8List? imageBytes;
  final Map<String, dynamic>? foodScanResult;
  final String? reasoning;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.imageBytes,
    this.foodScanResult,
    this.reasoning,
  });
}

class ReasoningCollapseWidget extends StatefulWidget {
  final String reasoning;
  const ReasoningCollapseWidget({super.key, required this.reasoning});

  @override
  State<ReasoningCollapseWidget> createState() => _ReasoningCollapseWidgetState();
}

class _ReasoningCollapseWidgetState extends State<ReasoningCollapseWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: const Color(0xFF006D44),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isExpanded ? "Ẩn quá trình suy nghĩ..." : "Xem quá trình suy nghĩ...",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF006D44),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
              child: Text(
                widget.reasoning,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

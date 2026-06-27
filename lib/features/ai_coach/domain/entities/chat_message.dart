import 'dart:typed_data';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final Uint8List? imageBytes;
  final Map<String, dynamic>? foodScanResult;
  final String? reasoning;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.imageBytes,
    this.foodScanResult,
    this.reasoning,
  });
}

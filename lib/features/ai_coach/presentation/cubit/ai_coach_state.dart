import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class AiCoachState extends Equatable {
  const AiCoachState();

  @override
  List<Object?> get props => [];
}

class AiCoachInitial extends AiCoachState {}

class AiCoachLoading extends AiCoachState {}

class AiCoachLoaded extends AiCoachState {
  final Map<String, dynamic>? userContext;
  final List<ChatMessage> messages;
  final List<Map<String, dynamic>> conversationHistory;
  final List<Map<String, dynamic>> recentScans;
  final bool isChatLoading;
  final bool isOperationLoading;
  final String? toastMessage;

  const AiCoachLoaded({
    this.userContext,
    required this.messages,
    required this.conversationHistory,
    required this.recentScans,
    this.isChatLoading = false,
    this.isOperationLoading = false,
    this.toastMessage,
  });

  AiCoachLoaded copyWith({
    Map<String, dynamic>? userContext,
    List<ChatMessage>? messages,
    List<Map<String, dynamic>>? conversationHistory,
    List<Map<String, dynamic>>? recentScans,
    bool? isChatLoading,
    bool? isOperationLoading,
    String? toastMessage,
  }) {
    return AiCoachLoaded(
      userContext: userContext ?? this.userContext,
      messages: messages ?? this.messages,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      recentScans: recentScans ?? this.recentScans,
      isChatLoading: isChatLoading ?? this.isChatLoading,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      toastMessage: toastMessage,
    );
  }

  @override
  List<Object?> get props => [
        userContext,
        messages,
        conversationHistory,
        recentScans,
        isChatLoading,
        isOperationLoading,
        toastMessage,
      ];
}

class AiCoachError extends AiCoachState {
  final String message;

  const AiCoachError(this.message);

  @override
  List<Object?> get props => [message];
}

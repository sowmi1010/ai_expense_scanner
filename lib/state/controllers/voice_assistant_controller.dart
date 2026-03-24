import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/voice_intent_parser.dart';
import '../../core/services/voice_service.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repo.dart';
import '../providers/expense_providers.dart';
import '../providers/service_providers.dart';

final voiceAssistantControllerProvider = Provider<VoiceAssistantController>((
  ref,
) {
  final repo = ref.watch(expenseRepositoryProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  return VoiceAssistantController(repo: repo, voiceService: voiceService);
});

class VoiceCommandResult {
  final String message;
  final bool showSnackBar;

  const VoiceCommandResult({required this.message, this.showSnackBar = false});
}

class VoiceAssistantController {
  final ExpenseRepo _repo;
  final VoiceService _voiceService;

  VoiceAssistantController({
    required ExpenseRepo repo,
    required VoiceService voiceService,
  }) : _repo = repo,
       _voiceService = voiceService;

  Future<VoiceListenResult> startListening({
    required VoidCallback onListeningStart,
    required VoidCallback onListeningStop,
    required Future<void> Function(String text) onResult,
  }) {
    return _voiceService.listen(
      onListeningStart: onListeningStart,
      onListeningStop: onListeningStop,
      onResult: onResult,
    );
  }

  Future<VoiceSpeakResult> speak(String text) => _voiceService.speak(text);

  Future<VoiceCommandResult> handleVoiceText(String text) async {
    final intent = VoiceIntentParser.parse(text);

    if (intent.type == VoiceIntentType.addExpense &&
        intent.addExpense != null) {
      final add = intent.addExpense!;
      if (add.amount <= 0) {
        return const VoiceCommandResult(
          message: 'I could not find a valid amount greater than zero.',
        );
      }
      if (add.category.trim().isEmpty) {
        return const VoiceCommandResult(
          message: 'I could not find a valid category.',
        );
      }

      final expense = ExpenseModel(
        amount: add.amount,
        merchant: add.merchant,
        category: add.category,
        paymentMode: add.paymentMode,
        createdAt: add.createdAt,
        rawOcrText: 'voice:$text',
      );
      await _repo.insertExpense(expense);

      final message =
          'Saved ${add.amount.toStringAsFixed(0)} in ${add.category} using ${add.paymentMode}';
      return VoiceCommandResult(message: message, showSnackBar: true);
    }

    if (intent.type == VoiceIntentType.querySummary && intent.query != null) {
      final query = intent.query!;
      final total = await _repo.sumByDateAndCategory(
        query.start,
        query.end,
        query.category,
      );

      final categoryText = query.category != null ? '${query.category} ' : '';
      final response =
          'You spent ${total.toStringAsFixed(0)} in ${categoryText}this period';
      return VoiceCommandResult(message: response);
    }

    return const VoiceCommandResult(
      message: 'I could not understand. Try: paid 300 at store with gpay.',
    );
  }
}

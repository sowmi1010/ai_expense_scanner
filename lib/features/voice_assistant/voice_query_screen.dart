import 'package:flutter/material.dart';

import '../../core/services/voice_intent_parser.dart';
import '../../core/services/voice_service.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

class VoiceQueryScreen extends StatefulWidget {
  const VoiceQueryScreen({super.key});

  @override
  State<VoiceQueryScreen> createState() => _VoiceQueryScreenState();
}

class _VoiceQueryScreenState extends State<VoiceQueryScreen> {
  final _voice = VoiceService();
  final _repo = ExpenseRepository.instance;

  String _heard = 'Tap mic and speak';
  String _status = 'Try: "I paid 250 in gpay for recharge"';
  bool _listening = false;

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    await _voice.listen(
      onListeningStart: () {
        setState(() {
          _listening = true;
          _status = 'Listening...';
        });
      },
      onListeningStop: () {
        if (mounted) {
          setState(() => _listening = false);
        }
      },
      onResult: _handleVoiceText,
    );
  }

  Future<void> _handleVoiceText(String text) async {
    setState(() {
      _heard = text;
      _status = 'Processing command...';
    });

    final intent = VoiceIntentParser.parse(text);

    if (intent.type == VoiceIntentType.addExpense && intent.addExpense != null) {
      final add = intent.addExpense!;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        setState(() => _status = message);
      }
      await _voice.speak(message);
      return;
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

      if (mounted) {
        setState(() => _status = response);
      }
      await _voice.speak(response);
      return;
    }

    const fallback =
        'I could not understand. Try: paid 300 at store with gpay.';
    if (mounted) {
      setState(() => _status = fallback);
    }
    await _voice.speak(fallback);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Assistant')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _heard,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _listening ? null : _startListening,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: _listening ? cs.error : cs.primary,
                  child: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

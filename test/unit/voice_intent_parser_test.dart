import 'package:ai_expense_scanner/core/services/voice_intent_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceIntentParser', () {
    test('parses add-expense command with amount and payment hint', () {
      final result = VoiceIntentParser.parse(
        'I paid 300 in gpay for mobile recharge',
      );

      expect(result.type, VoiceIntentType.addExpense);
      expect(result.addExpense, isNotNull);
      expect(result.addExpense!.amount, 300);
      expect(result.addExpense!.paymentMode, isNotEmpty);
    });

    test('parses summary query with category', () {
      final result = VoiceIntentParser.parse(
        'how much did i spend on food this month',
      );

      expect(result.type, VoiceIntentType.querySummary);
      expect(result.query, isNotNull);
      expect(result.query!.category, 'Food');
    });
  });
}

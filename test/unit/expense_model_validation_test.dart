import 'package:ai_expense_scanner/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseModel.validateOrThrow', () {
    test('throws when amount is less than or equal to zero', () {
      final expense = ExpenseModel(
        amount: 0,
        merchant: 'Store',
        category: 'Food',
        createdAt: DateTime(2026, 3, 23),
      );

      expect(
        expense.validateOrThrow,
        throwsA(isA<ExpenseValidationException>()),
      );
    });

    test('throws when category is blank', () {
      final expense = ExpenseModel(
        amount: 120,
        merchant: 'Store',
        category: '   ',
        createdAt: DateTime(2026, 3, 23),
      );

      expect(
        expense.validateOrThrow,
        throwsA(isA<ExpenseValidationException>()),
      );
    });

    test('passes for valid expense', () {
      final expense = ExpenseModel(
        amount: 120,
        merchant: 'Store',
        category: 'Food',
        createdAt: DateTime(2026, 3, 23),
      );

      expect(expense.validateOrThrow, returnsNormally);
    });
  });
}

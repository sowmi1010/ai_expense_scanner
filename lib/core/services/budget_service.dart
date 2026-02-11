import 'package:shared_preferences/shared_preferences.dart';

class BudgetStatus {
  final double budget;
  final double spent;
  final double percent;
  final bool hit80;
  final bool hit100;

  BudgetStatus({
    required this.budget,
    required this.spent,
    required this.percent,
    required this.hit80,
    required this.hit100,
  });
}

class BudgetService {
  BudgetService._internal();
  static final BudgetService instance = BudgetService._internal();

  static const _kMonthlyBudget = 'monthly_budget';
  static const _kAlert80Key = 'budget_alert_80_month';
  static const _kAlert100Key = 'budget_alert_100_month';

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  Future<double> getMonthlyBudget() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_kMonthlyBudget) ?? 0;
  }

  Future<void> setMonthlyBudget(double value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kMonthlyBudget, value);
  }

  Future<void> resetMonthIfNeeded() async {
    final sp = await SharedPreferences.getInstance();
    final mk = _monthKey(DateTime.now());

    final a80 = sp.getString(_kAlert80Key);
    final a100 = sp.getString(_kAlert100Key);

    // If stored month differs, reset flags by setting to current month but false usage is done in check method.
    // We store month keys; if month changes, treat as not triggered.
    if (a80 != mk) await sp.setString(_kAlert80Key, '');
    if (a100 != mk) await sp.setString(_kAlert100Key, '');
  }

  Future<bool> hasTriggered80ThisMonth() async {
    final sp = await SharedPreferences.getInstance();
    final mk = _monthKey(DateTime.now());
    return sp.getString(_kAlert80Key) == mk;
  }

  Future<bool> hasTriggered100ThisMonth() async {
    final sp = await SharedPreferences.getInstance();
    final mk = _monthKey(DateTime.now());
    return sp.getString(_kAlert100Key) == mk;
  }

  Future<void> markTriggered80ThisMonth() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAlert80Key, _monthKey(DateTime.now()));
  }

  Future<void> markTriggered100ThisMonth() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAlert100Key, _monthKey(DateTime.now()));
  }
}

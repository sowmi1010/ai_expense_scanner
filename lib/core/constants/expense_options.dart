class ExpenseOptions {
  static const String defaultCategory = 'Others';
  static const String defaultPaymentMode = 'Cash';

  static const List<String> categories = [
    'Food',
    'Groceries',
    'Travel',
    'Shopping',
    'Bills',
    'Recharge',
    'Savings',
    'Bank Transfer',
    'Others',
  ];

  static const List<String> paymentModes = [
    'Cash',
    'UPI/GPay',
    'Card',
    'Bank Transfer',
    'Wallet',
    'Net Banking',
    'Others',
  ];

  static String detectCategoryFromText(String text) {
    final t = text.toLowerCase();

    bool hasAny(List<String> keys) => keys.any(t.contains);

    if (hasAny([
      'restaurant',
      'cafe',
      'hotel',
      'biryani',
      'dosa',
      'meals',
      'swiggy',
      'zomato',
      'tea',
      'coffee',
      'pizza',
      'burger',
    ])) {
      return 'Food';
    }

    if (hasAny([
      'grocery',
      'groceries',
      'mart',
      'supermarket',
      'bigbasket',
      'vegetable',
      'milk',
      'provision',
      'dmart',
    ])) {
      return 'Groceries';
    }

    if (hasAny([
      'uber',
      'ola',
      'petrol',
      'fuel',
      'diesel',
      'metro',
      'bus',
      'train',
      'parking',
      'toll',
      'auto',
      'taxi',
    ])) {
      return 'Travel';
    }

    if (hasAny([
      'store',
      'shopping',
      'fashion',
      'cloth',
      'mall',
      'amazon',
      'flipkart',
      'myntra',
      'jeweller',
      'jewellery',
      'jewelry',
      'gold',
      'silver',
    ])) {
      return 'Shopping';
    }

    if (hasAny([
      'electricity',
      'electric bill',
      'power',
      'tnpdcl',
      'tneb',
      'eb bill',
      'broadband',
      'water',
      'gas',
      'lpg',
      'bharatgas',
      'bharat gas',
      'indane',
      'hp gas',
      'cylinder',
      'insurance',
      'bill',
      'postpaid',
      'maintenance',
      'consumer number',
      'due date',
    ])) {
      return 'Bills';
    }

    if (hasAny([
      'recharge',
      'topup',
      'top-up',
      'prepaid',
      'mobile recharge',
      'data pack',
      'validity',
    ])) {
      return 'Recharge';
    }

    if (hasAny([
      'savings',
      'deposit',
      'fd',
      'rd',
      'investment',
      'sip',
      'mutual fund',
    ])) {
      return 'Savings';
    }

    if (hasAny([
      'bank transfer',
      'neft',
      'rtgs',
      'imps',
      'upi transfer',
      'google pay',
      'gpay',
      'phonepe',
      'paytm',
      'beneficiary',
      'account transfer',
    ])) {
      return 'Bank Transfer';
    }

    return defaultCategory;
  }

  static String detectPaymentModeFromText(String text) {
    final t = text.toLowerCase();

    bool hasAny(List<String> keys) => keys.any(t.contains);

    if (hasAny(['google pay', 'gpay', 'upi', 'phonepe', 'paytm', 'bhim'])) {
      return 'UPI/GPay';
    }

    if (hasAny(['bank transfer', 'neft', 'imps', 'rtgs'])) {
      return 'Bank Transfer';
    }

    if (hasAny(['credit card', 'debit card', 'card'])) {
      return 'Card';
    }

    if (hasAny(['wallet'])) {
      return 'Wallet';
    }

    if (hasAny(['net banking', 'internet banking'])) {
      return 'Net Banking';
    }

    if (hasAny(['cash'])) {
      return 'Cash';
    }

    return defaultPaymentMode;
  }
}

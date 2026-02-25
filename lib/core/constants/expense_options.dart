class ExpenseOptions {
  static const String defaultCategory = 'Others';
  static const String defaultPaymentMode = 'Cash';

  static const List<String> categories = [
    'Outside Food',
    'Vegetables',
    'Fruits',
    'Snacks',
    'Non Veg',
    'Petrol',
    'Movies',
    'Shopping Dress',
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

    // Keep Movies before food checks so it is never classified as Food.
    if (hasAny([
      'movie',
      'movies',
      'cinema',
      'theatre',
      'theater',
      'ticket',
      'bookmyshow',
      'pvr',
      'inox',
      'screen',
      'showtime',
    ])) {
      return 'Movies';
    }

    if (hasAny([
      'petrol',
      'fuel',
      'diesel',
      'gasoline',
      'petrol bunk',
      'fuel station',
      'petrol pump',
      'hp petrol',
      'indian oil',
      'shell',
      'bharat petroleum',
      'bpcl',
      'ioc',
    ])) {
      return 'Petrol';
    }

    if (hasAny([
      'dress',
      'clothes',
      'clothing',
      'apparel',
      'garment',
      'boutique',
      'fashion',
      'myntra',
      'ajio',
      'shirt',
      'jeans',
      'saree',
      'kurti',
      'footwear',
      'shoe',
      'shopping dress',
    ])) {
      return 'Shopping Dress';
    }

    if (hasAny([
      'vegetable',
      'vegetables',
      'veggies',
      'greens',
      'onion',
      'tomato',
      'potato',
      'carrot',
      'spinach',
      'cabbage',
      'brinjal',
      'bhindi',
      'drumstick',
    ])) {
      return 'Vegetables';
    }

    if (hasAny([
      'fruit',
      'fruits',
      'apple',
      'banana',
      'orange',
      'grape',
      'mango',
      'watermelon',
      'pomegranate',
      'papaya',
      'guava',
    ])) {
      return 'Fruits';
    }

    if (hasAny([
      'snack',
      'snacks',
      'chips',
      'biscuit',
      'cookies',
      'namkeen',
      'mixture',
      'puffs',
      'samosa',
      'fries',
      'popcorn',
    ])) {
      return 'Snacks';
    }

    if (hasAny([
      'non veg',
      'non-veg',
      'chicken',
      'mutton',
      'fish',
      'seafood',
      'egg',
      'kebab',
      'tandoori',
      'grill',
      'biryani',
    ])) {
      return 'Non Veg';
    }

    if (hasAny([
      'restaurant',
      'cafe',
      'hotel',
      'dosa',
      'idli',
      'meals',
      'swiggy',
      'zomato',
      'tea',
      'coffee',
      'pizza',
      'burger',
      'outside food',
      'dine in',
      'dining',
      'eatery',
      'food court',
    ])) {
      return 'Outside Food';
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

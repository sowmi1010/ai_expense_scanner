class ExpenseModel {
  final int? id;
  final double amount;
  final String merchant;
  final String category;
  final String paymentMode;
  final DateTime createdAt;
  final String? receiptImagePath;
  final String? rawOcrText;

  ExpenseModel({
    this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    this.paymentMode = 'Cash',
    required this.createdAt,
    this.receiptImagePath,
    this.rawOcrText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'payment_mode': paymentMode,
      'created_at': createdAt.toIso8601String(),
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      merchant: (map['merchant'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Others',
      paymentMode: (map['payment_mode'] as String?) ?? 'Cash',
      createdAt: DateTime.parse(map['created_at'] as String),
      receiptImagePath: map['receipt_image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
    );
  }
}

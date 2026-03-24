import 'package:ai_expense_scanner/data/security/sensitive_data_cipher.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryKeyStore implements EncryptionKeyStore {
  String? _key;

  @override
  Future<String?> readKey() async => _key;

  @override
  Future<void> writeKey(String key) async {
    _key = key;
  }
}

void main() {
  group('SensitiveDataCipher', () {
    test('encrypts and decrypts sensitive values', () async {
      final cipher = SensitiveDataCipher(keyStore: _InMemoryKeyStore());

      final encrypted = await cipher.encryptNullable('Merchant Name');
      final decrypted = await cipher.decryptNullable(encrypted);

      expect(encrypted, isNot(equals('Merchant Name')));
      expect(decrypted, 'Merchant Name');
    });

    test('returns legacy plaintext unchanged on decrypt', () async {
      final cipher = SensitiveDataCipher(keyStore: _InMemoryKeyStore());

      final decrypted = await cipher.decryptNullable('legacy-plain-value');

      expect(decrypted, 'legacy-plain-value');
    });

    test('uses random IV so ciphertext changes across calls', () async {
      final cipher = SensitiveDataCipher(keyStore: _InMemoryKeyStore());

      final encryptedA = await cipher.encryptNullable('same-value');
      final encryptedB = await cipher.encryptNullable('same-value');

      expect(encryptedA, isNotNull);
      expect(encryptedB, isNotNull);
      expect(encryptedA, isNot(equals(encryptedB)));
    });
  });
}

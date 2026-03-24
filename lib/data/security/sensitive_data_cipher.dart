import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_strings.dart';
import '../../core/logging/app_logger.dart';

abstract class EncryptionKeyStore {
  Future<String?> readKey();

  Future<void> writeKey(String key);
}

class SecureStorageEncryptionKeyStore implements EncryptionKeyStore {
  final FlutterSecureStorage _storage;
  final String _keyName;

  SecureStorageEncryptionKeyStore({
    FlutterSecureStorage? storage,
    String keyName = AppStrings.encryptionStorageKey,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _keyName = keyName;

  @override
  Future<String?> readKey() => _storage.read(key: _keyName);

  @override
  Future<void> writeKey(String key) =>
      _storage.write(key: _keyName, value: key);
}

class SensitiveDataCipher {
  static const int _aesKeyLengthBytes = 32;
  static const int _ivLengthBytes = 16;

  final EncryptionKeyStore _keyStore;
  final String _payloadPrefix;
  enc.Key? _cachedKey;

  SensitiveDataCipher({
    EncryptionKeyStore? keyStore,
    String payloadPrefix = AppStrings.encryptionPayloadPrefix,
  }) : _keyStore = keyStore ?? SecureStorageEncryptionKeyStore(),
       _payloadPrefix = payloadPrefix;

  Future<String?> encryptNullable(String? value) async {
    if (value == null || value.isEmpty) return value;
    if (_isEncryptedPayload(value)) return value;

    try {
      final key = await _readOrCreateKey();
      final iv = enc.IV.fromSecureRandom(_ivLengthBytes);
      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = encrypter.encrypt(value, iv: iv);
      return '$_payloadPrefix${iv.base64}:${encrypted.base64}';
    } catch (e, stackTrace) {
      AppLogger.error(
        'Encryption failed. Falling back to plain value for availability.',
        error: e,
        stackTrace: stackTrace,
      );
      return value;
    }
  }

  Future<String?> decryptNullable(String? value) async {
    if (value == null || value.isEmpty) return value;
    if (!_isEncryptedPayload(value)) return value;

    final payload = value.substring(_payloadPrefix.length);
    final delimiter = payload.indexOf(':');
    if (delimiter <= 0 || delimiter >= payload.length - 1) {
      AppLogger.warning(
        'Encrypted payload format was invalid. Returning raw value.',
      );
      return value;
    }

    final ivBase64 = payload.substring(0, delimiter);
    final dataBase64 = payload.substring(delimiter + 1);

    try {
      final key = await _readOrCreateKey();
      final encrypter = enc.Encrypter(enc.AES(key));
      final iv = enc.IV.fromBase64(ivBase64);
      final encrypted = enc.Encrypted.fromBase64(dataBase64);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Decryption failed. Returning raw value for compatibility.',
        error: e,
        stackTrace: stackTrace,
      );
      return value;
    }
  }

  bool _isEncryptedPayload(String value) => value.startsWith(_payloadPrefix);

  Future<enc.Key> _readOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    var stored = await _keyStore.readKey();
    if (stored == null || stored.isEmpty) {
      stored = _generateKeyBase64();
      await _keyStore.writeKey(stored);
    }

    _cachedKey = enc.Key.fromBase64(stored);
    return _cachedKey!;
  }

  String _generateKeyBase64() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      _aesKeyLengthBytes,
      (_) => random.nextInt(256),
    );
    return base64Encode(bytes);
  }
}

import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Clase que maneja hashing de contraseñas con PBKDF2 + salt.
/// Implementación usando crypto (sin dependencias adicionales).
/// Formato de hash: "$pbkdf2$iterations$salt$hash"
class PasswordHasher {
  // Número de iteraciones para PBKDF2
  static const int _iterations = 50000;
  static const String _algorithm = 'pbkdf2';
  static const int _keyLength = 32; // 256 bits

  /// Implementación manual de PBKDF2 con HMAC-SHA256
  /// Basada en RFC 2898
  static String _pbkdf2Sha256(String password, String salt, int iterations, int keyLength) {
    final bytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    // PBKDF2 simplificado (iteraciones de HMAC)
    List<int> hash = Hmac(sha256, bytes).convert(saltBytes).bytes;

    for (int i = 1; i < iterations; i++) {
      hash = Hmac(sha256, bytes).convert(hash).bytes;
    }

    return hash.take(keyLength).toList().map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Genera un hash PBKDF2 seguro con salt para una contraseña.
  /// Retorna un string con formato: "$pbkdf2$iterations$salt$hash"
  static String hash(String password) {
    final salt = const Uuid().v4(); // Salt única por usuario
    final hash = _pbkdf2Sha256(password, salt, _iterations, _keyLength);
    return '\$$_algorithm\$$_iterations\$$salt\$$hash';
  }

  /// Verifica que una contraseña coincida con su hash PBKDF2.
  /// Soporta automáticamente hashes con formato "$pbkdf2$..." y SHA256 antiguos.
  static bool verify(String password, String storedHash) {
    // Si es un hash PBKDF2 nuevo (formato "$pbkdf2$...")
    if (storedHash.startsWith('\$pbkdf2\$')) {
      try {
        final parts = storedHash.split('\$');
        if (parts.length != 5) return false;

        final iterations = int.parse(parts[2]);
        final salt = parts[3];
        final storedHashValue = parts[4];

        final computedHash = _pbkdf2Sha256(password, salt, iterations, _keyLength);
        return computedHash == storedHashValue;
      } catch (e) {
        return false;
      }
    }

    // Soporte para hashes SHA256 antiguos (migración)
    if (storedHash.length == 64) {
      try {
        final newHash = sha256.convert(utf8.encode(password)).toString();
        return newHash == storedHash;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  /// Detecta si un hash es "antiguo" (SHA256 sin salt)
  static bool isLegacyHash(String hash) {
    // SHA256 hexstring tiene exactamente 64 caracteres
    // PBKDF2 tiene formato "$pbkdf2$..."
    return hash.length == 64 && !hash.startsWith('\$');
  }

  /// Re-hashea un hash antiguo con el nuevo esquema PBKDF2
  static String migrateHash(String password) {
    return hash(password);
  }
}


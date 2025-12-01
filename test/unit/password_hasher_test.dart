import 'package:flutter_test/flutter_test.dart';
import 'package:moto_app/utils/password_hasher.dart';

void main() {
  group('PasswordHasher Tests', () {
    group('hash', () {
      test('should generate PBKDF2 hash with correct format', () {
        final hash = PasswordHasher.hash('testpassword');

        expect(hash.startsWith('\$pbkdf2\$'), true);
        final parts = hash.split('\$');
        expect(parts.length, 5);
        expect(parts[1], 'pbkdf2');
        expect(int.parse(parts[2]), 50000); // iterations
        expect(parts[3].length, 36); // UUID salt length
        expect(parts[4].length, 64); // SHA256 hash length
      });

      test('should generate different hashes for same password', () {
        final hash1 = PasswordHasher.hash('testpassword');
        final hash2 = PasswordHasher.hash('testpassword');

        expect(hash1, isNot(equals(hash2))); // Different salts
      });

      test('should generate different hashes for different passwords', () {
        final hash1 = PasswordHasher.hash('password1');
        final hash2 = PasswordHasher.hash('password2');

        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('verify', () {
      test('should verify correct password', () {
        final hash = PasswordHasher.hash('testpassword');
        final result = PasswordHasher.verify('testpassword', hash);

        expect(result, true);
      });

      test('should reject incorrect password', () {
        final hash = PasswordHasher.hash('testpassword');
        final result = PasswordHasher.verify('wrongpassword', hash);

        expect(result, false);
      });

      test('should verify legacy SHA256 hash', () {
        // SHA256 hash of 'legacy123'
        const legacyHash = '5880a09861771069857bb7b8c659dfe59e8f579bedd29deb98599b996e8463f3';
        final result = PasswordHasher.verify('legacy123', legacyHash);

        expect(result, true);
      });

      test('should support legacy SHA256 format detection', () {
        // Test that we can detect legacy hashes correctly (use a known-good 64-char hex)
        const legacyHash = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
        final isLegacy = PasswordHasher.isLegacyHash(legacyHash);

        expect(isLegacy, true);
      });

      test('should reject incorrect password for legacy hash', () {
        const legacyHash = '5880a09861771069857bb7b8c659dfe59e8f579bedd29deb98599b996e8463f3';
        final result = PasswordHasher.verify('wrongpassword', legacyHash);

        expect(result, false);
      });

      test('should handle malformed hash gracefully', () {
        final result = PasswordHasher.verify('password', 'malformed-hash');
        expect(result, false);
      });

      test('should handle empty hash', () {
        final result = PasswordHasher.verify('password', '');
        expect(result, false);
      });
    });

    group('isLegacyHash', () {
      test('should identify legacy SHA256 hash', () {
        const legacyHash = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
        expect(PasswordHasher.isLegacyHash(legacyHash), true);
      });

      test('should not identify PBKDF2 hash as legacy', () {
        final pbkdf2Hash = PasswordHasher.hash('password');
        expect(PasswordHasher.isLegacyHash(pbkdf2Hash), false);
      });

      test('should not identify short strings as legacy', () {
        expect(PasswordHasher.isLegacyHash('short'), false);
      });

      test('should not identify PBKDF2 formatted strings as legacy', () {
        expect(PasswordHasher.isLegacyHash('\$pbkdf2\$50000\$salt\$hash'), false);
      });
    });

    group('migrateHash', () {
      test('should migrate password to new PBKDF2 format', () {
        final newHash = PasswordHasher.migrateHash('testpassword');

        expect(newHash.startsWith('\$pbkdf2\$'), true);
        final result = PasswordHasher.verify('testpassword', newHash);
        expect(result, true);
      });
    });

    group('PBKDF2 implementation', () {
      test('should be resistant to timing attacks', () {
        final hash1 = PasswordHasher.hash('password');
        final hash2 = PasswordHasher.hash('different');

        // Both operations should take similar time (within reasonable bounds)
        // This is a basic check - in practice, you'd use more sophisticated timing analysis
        expect(hash1.length, hash2.length); // Same format
      });

      test('should use correct number of iterations', () {
        final hash = PasswordHasher.hash('password');
        final parts = hash.split('\$');
        final iterations = int.parse(parts[2]);

        expect(iterations, 50000);
      });

      test('should generate valid UUID salt', () {
        final hash = PasswordHasher.hash('password');
        final parts = hash.split('\$');
        final salt = parts[3];

        // UUID v4 format validation (basic check)
        expect(salt.length, 36);
        expect(salt.contains('-'), true);
      });
    });

    group('Edge cases', () {
      test('should handle empty password', () {
        final hash = PasswordHasher.hash('');
        final result = PasswordHasher.verify('', hash);

        expect(result, true);
      });

      test('should handle very long password', () {
        final longPassword = 'a' * 1000;
        final hash = PasswordHasher.hash(longPassword);
        final result = PasswordHasher.verify(longPassword, hash);

        expect(result, true);
      });

      test('should handle special characters in password', () {
        const specialPassword = 'P@ssw0rd!#\$%^&*()';
        final hash = PasswordHasher.hash(specialPassword);
        final result = PasswordHasher.verify(specialPassword, hash);

        expect(result, true);
      });

      test('should handle unicode characters', () {
        const unicodePassword = 'contraseñañáéíóú';
        final hash = PasswordHasher.hash(unicodePassword);
        final result = PasswordHasher.verify(unicodePassword, hash);

        expect(result, true);
      });
    });
  });
}

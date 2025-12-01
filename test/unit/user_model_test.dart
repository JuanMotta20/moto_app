import 'package:flutter_test/flutter_test.dart';
import 'package:moto_app/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    group('hashPassword', () {
      test('should hash password using PBKDF2', () {
        final hash = UserModel.hashPassword('testpassword');

        expect(hash.startsWith('\$pbkdf2\$'), true);
        final parts = hash.split('\$');
        expect(parts.length, 5);
        expect(parts[1], 'pbkdf2');
        expect(int.parse(parts[2]), 50000); // iterations
      });

      test('should generate different hashes for same password', () {
        final hash1 = UserModel.hashPassword('password');
        final hash2 = UserModel.hashPassword('password');

        expect(hash1, isNot(equals(hash2))); // Different salts
      });
    });

    group('verifyPassword', () {
      test('should verify correct password', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: UserModel.hashPassword('correctpassword'),
        );

        expect(user.verifyPassword('correctpassword'), true);
      });

      test('should reject incorrect password', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: UserModel.hashPassword('correctpassword'),
        );

        expect(user.verifyPassword('wrongpassword'), false);
      });

      test('should return false when passwordHash is null', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: null,
        );

        expect(user.verifyPassword('anypassword'), false);
      });
    });

    group('withoutPassword', () {
      test('should return user without passwordHash', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: 'somehash',
        );

        final withoutPassword = user.withoutPassword();

        expect(withoutPassword.id, user.id);
        expect(withoutPassword.name, user.name);
        expect(withoutPassword.email, user.email);
        expect(withoutPassword.phone, user.phone);
        expect(withoutPassword.role, user.role);
        expect(withoutPassword.passwordHash, isNull);
      });
    });

    group('copyWith', () {
      test('should copy with modified fields', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: 'originalhash',
        );

        final copied = user.copyWith(
          name: 'Updated Name',
          passwordHash: 'newhash',
        );

        expect(copied.id, user.id);
        expect(copied.name, 'Updated Name');
        expect(copied.email, user.email);
        expect(copied.phone, user.phone);
        expect(copied.role, user.role);
        expect(copied.passwordHash, 'newhash');
      });

      test('should keep original values when not specified', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: 'originalhash',
        );

        final copied = user.copyWith(name: 'Updated Name');

        expect(copied.id, user.id);
        expect(copied.name, 'Updated Name');
        expect(copied.email, user.email);
        expect(copied.phone, user.phone);
        expect(copied.role, user.role);
        expect(copied.passwordHash, 'originalhash');
      });
    });

    group('roleDisplayName', () {
      test('should return correct display name for admin', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Admin User',
          email: 'admin@example.com',
          phone: '1234567890',
          role: UserRole.admin,
        );

        expect(user.roleDisplayName, 'Administrador');
      });

      test('should return correct display name for driver', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Driver User',
          email: 'driver@example.com',
          phone: '1234567890',
          role: UserRole.driver,
        );

        expect(user.roleDisplayName, 'Conductor');
      });

      test('should return correct display name for client', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Client User',
          email: 'client@example.com',
          phone: '1234567890',
          role: UserRole.client,
        );

        expect(user.roleDisplayName, 'Cliente');
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: 'somehash',
        );

        final json = user.toJson();

        expect(json['id'], 'test-id');
        expect(json['name'], 'Test User');
        expect(json['email'], 'test@example.com');
        expect(json['phone'], '1234567890');
        expect(json['role'], 'client');
        expect(json['passwordHash'], 'somehash');
      });

      test('should handle null passwordHash in JSON', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: UserRole.client,
          passwordHash: null,
        );

        final json = user.toJson();

        expect(json['passwordHash'], isNull);
      });
    });

    group('fromJson', () {
      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '1234567890',
          'role': 'client',
          'passwordHash': 'somehash',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'test-id');
        expect(user.name, 'Test User');
        expect(user.email, 'test@example.com');
        expect(user.phone, '1234567890');
        expect(user.role, UserRole.client);
        expect(user.passwordHash, 'somehash');
      });

      test('should handle null passwordHash in JSON', () {
        final json = {
          'id': 'test-id',
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '1234567890',
          'role': 'client',
          'passwordHash': null,
        };

        final user = UserModel.fromJson(json);

        expect(user.passwordHash, isNull);
      });

      test('should handle missing fields gracefully', () {
        final json = {
          'id': 'test-id',
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '1234567890',
          'role': 'client',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'test-id');
        expect(user.name, 'Test User');
        expect(user.email, 'test@example.com');
        expect(user.phone, '1234567890');
        expect(user.role, UserRole.client);
        expect(user.passwordHash, isNull);
      });

      test('should handle invalid role gracefully', () {
        final json = {
          'id': 'test-id',
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '1234567890',
          'role': 'invalid_role',
        };

        final user = UserModel.fromJson(json);

        expect(user.role, UserRole.client); // Default fallback
      });

      test('should handle null values gracefully', () {
        final json = {
          'id': null,
          'name': null,
          'email': null,
          'phone': null,
          'role': null,
        };

        final user = UserModel.fromJson(json);

        expect(user.id, '');
        expect(user.name, '');
        expect(user.email, '');
        expect(user.phone, '');
        expect(user.role, UserRole.client);
        expect(user.passwordHash, isNull);
      });
    });

    group('UserRole enum', () {
      test('should have correct enum values', () {
        expect(UserRole.admin.name, 'admin');
        expect(UserRole.driver.name, 'driver');
        expect(UserRole.client.name, 'client');
      });

      test('should parse role from string correctly', () {
        expect(UserRole.values.firstWhere((r) => r.name == 'admin'), UserRole.admin);
        expect(UserRole.values.firstWhere((r) => r.name == 'driver'), UserRole.driver);
        expect(UserRole.values.firstWhere((r) => r.name == 'client'), UserRole.client);
      });
    });
  });
}

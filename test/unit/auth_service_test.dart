import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:moto_app/models/user_model.dart';
import 'package:moto_app/services/auth_service.dart';
import 'package:moto_app/services/secure_storage_interface.dart';

// Mock para FlutterSecureStorage
class MockFlutterSecureStorage implements SecureStorageInterface {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({required String key}) async => _storage[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<void> delete({required String key}) async => _storage.remove(key);
}

void main() {
  late AuthService authService;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() async {
    // Inicializar Hive en un directorio temporal para tests (evita usar
    // Hive.initFlutter que llama a path_provider y falla en entorno de tests).
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = Directory.systemTemp.createTempSync('moto_app_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('sessionBox');
    await Hive.openBox('usersBox');

    mockSecureStorage = MockFlutterSecureStorage();
    authService = AuthService(secureStorage: mockSecureStorage);
  });

  tearDown(() async {
    await Hive.box('sessionBox').clear();
    await Hive.box('usersBox').clear();
    await Hive.close();
    // Borra cualquier directorio temporal creado por los tests
    // (no eliminamos de forma segura para no fallar si ya fue eliminado)
    try {
      final systemTemp = Directory.systemTemp;
      final dirs = systemTemp.listSync().where((e) => e.path.contains('moto_app_test_'));
      for (final d in dirs) {
        if (d is Directory) {
          d.deleteSync(recursive: true);
        }
      }
    } catch (_) {}
  });

  group('AuthService Tests', () {
    group('initializeDefaultUsers', () {
      test('should create default users on first run', () async {
        await authService.initializeDefaultUsers();

        final usersBox = Hive.box('usersBox');
        expect(usersBox.length, 3);

        final admin = UserModel.fromJson(Map.castFrom(usersBox.values.firstWhere(
          (userData) => UserModel.fromJson(Map.castFrom(userData)).role == UserRole.admin
        )));
        expect(admin.email, 'admin@mototaxi.com');
        expect(admin.role, UserRole.admin);
        expect(admin.passwordHash, isNotNull);
        expect(admin.passwordHash!.startsWith('\$pbkdf2\$'), true);
      });

      test('should not create users if already exist', () async {
        await authService.initializeDefaultUsers();
        final initialCount = Hive.box('usersBox').length;

        await authService.initializeDefaultUsers();
        expect(Hive.box('usersBox').length, initialCount);
      });
    });

    group('register', () {
      test('should register client successfully', () async {
        final result = await authService.register(
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          password: 'password123',
        );

        expect(result, isNotNull);
        expect(result!.name, 'Test User');
        expect(result.email, 'test@example.com');
        expect(result.role, UserRole.client);
        expect(result.passwordHash, isNull); // withoutPassword()
      });

      test('should prevent duplicate email registration', () async {
        await authService.register(
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          password: 'password123',
        );

        expect(
          () => authService.register(
            name: 'Another User',
            email: 'test@example.com',
            phone: '0987654321',
            password: 'password456',
          ),
          throwsException,
        );
      });

      test('should prevent duplicate phone registration', () async {
        await authService.register(
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          password: 'password123',
        );

        expect(
          () => authService.register(
            name: 'Another User',
            email: 'another@example.com',
            phone: '1234567890',
            password: 'password456',
          ),
          throwsException,
        );
      });

      test('should prevent non-client registration', () async {
        expect(
          () => authService.register(
            name: 'Driver User',
            email: 'driver@example.com',
            phone: '1234567890',
            password: 'password123',
            role: UserRole.driver,
          ),
          throwsException,
        );
      });
    });

    group('login', () {
      setUp(() async {
        await authService.initializeDefaultUsers();
      });

      test('should login admin successfully', () async {
        final result = await authService.login(
          identifier: 'admin@mototaxi.com',
          password: 'admin123',
        );

        expect(result, isNotNull);
        expect(result!.email, 'admin@mototaxi.com');
        expect(result.role, UserRole.admin);
        expect(result.passwordHash, isNull); // withoutPassword()
      });

      test('should login with phone number', () async {
        final result = await authService.login(
          identifier: '1111111111', // admin phone
          password: 'admin123',
        );

        expect(result, isNotNull);
        expect(result!.phone, '1111111111');
      });

      test('should fail with wrong password', () async {
        final result = await authService.login(
          identifier: 'admin@mototaxi.com',
          password: 'wrongpassword',
        );

        expect(result, isNull);
      });

      test('should fail with non-existent user', () async {
        final result = await authService.login(
          identifier: 'nonexistent@example.com',
          password: 'password123',
        );

        expect(result, isNull);
      });

      test('should migrate legacy SHA256 hash to PBKDF2', () async {
        // Crear usuario con hash SHA256 antiguo (simulado)
        final usersBox = Hive.box('usersBox');
        final legacyUser = UserModel(
          id: 'legacy-user-id',
          name: 'Legacy User',
          email: 'legacy@example.com',
          phone: '9999999999',
          role: UserRole.client,
          passwordHash: '5880a09861771069857bb7b8c659dfe59e8f579bedd29deb98599b996e8463f3', // SHA256 de 'legacy123'
        );
        await usersBox.put(legacyUser.id, legacyUser.toJson());

        // Login debería migrar automáticamente
        final result = await authService.login(
          identifier: 'legacy@example.com',
          password: 'legacy123',
        );

        expect(result, isNotNull);
        expect(result!.email, 'legacy@example.com');

        // Verificar que el hash fue migrado
        final updatedUserData = usersBox.get(legacyUser.id);
        final updatedUser = UserModel.fromJson(Map.castFrom(updatedUserData));
        expect(updatedUser.passwordHash!.startsWith('\$pbkdf2\$'), true);
      });
    });

    group('createDriver', () {
      setUp(() async {
        await authService.initializeDefaultUsers();
        // Login como admin
        await authService.login(identifier: 'admin@mototaxi.com', password: 'admin123');
      });

      test('should create driver when logged in as admin', () async {
        final result = await authService.createDriver(
          name: 'New Driver',
          email: 'driver@example.com',
          phone: '5555555555',
          password: 'driverpass123',
        );

        expect(result, isNotNull);
        expect(result!.name, 'New Driver');
        expect(result.role, UserRole.driver);
        expect(result.passwordHash, isNull); // withoutPassword()
      });

      test('should fail when not logged in as admin', () async {
        // Logout admin
        await authService.logout();

        expect(
          () => authService.createDriver(
            name: 'New Driver',
            email: 'driver@example.com',
            phone: '5555555555',
            password: 'driverpass123',
          ),
          throwsException,
        );
      });
    });

    group('getCurrentUser', () {
      test('should return null when not logged in', () async {
        final result = await authService.getCurrentUser();
        expect(result, isNull);
      });

      test('should return current user when logged in', () async {
        await authService.initializeDefaultUsers();
        await authService.login(identifier: 'admin@mototaxi.com', password: 'admin123');

        final result = await authService.getCurrentUser();
        expect(result, isNotNull);
        expect(result!.email, 'admin@mototaxi.com');
        expect(result.passwordHash, isNull); // withoutPassword()
      });
    });

    group('logout', () {
      test('should clear session', () async {
        await authService.initializeDefaultUsers();
        await authService.login(identifier: 'admin@mototaxi.com', password: 'admin123');

        expect(await authService.isLoggedIn(), true);
        expect(await authService.getCurrentUser(), isNotNull);

        await authService.logout();

        expect(await authService.isLoggedIn(), false);
        expect(await authService.getCurrentUser(), isNull);
      });
    });

    group('getAllUsers', () {
      setUp(() async {
        await authService.initializeDefaultUsers();
      });

      test('should return all users without password hashes', () async {
        final users = await authService.getAllUsers();

        expect(users.length, 3);
        for (final user in users) {
          expect(user.passwordHash, isNull); // withoutPassword()
        }
      });
    });

    group('deleteUser', () {
      setUp(() async {
        await authService.initializeDefaultUsers();
        await authService.login(identifier: 'admin@mototaxi.com', password: 'admin123');
      });

      test('should delete user when logged in as admin', () async {
        final usersBefore = await authService.getAllUsers();
        expect(usersBefore.length, 3);

        // Delete conductor demo
        final conductorToDelete = usersBefore.firstWhere((u) => u.role == UserRole.driver);
        await authService.deleteUser(conductorToDelete.id);

        final usersAfter = await authService.getAllUsers();
        expect(usersAfter.length, 2);
        expect(usersAfter.any((u) => u.id == conductorToDelete.id), false);
      });

      test('should fail when not logged in as admin', () async {
        await authService.logout();

        expect(
          () => authService.deleteUser('some-user-id'),
          throwsException,
        );
      });
    });
  });
}

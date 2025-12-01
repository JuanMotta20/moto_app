import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'secure_storage_interface.dart';
import '../models/user_model.dart';
import '../utils/password_hasher.dart';

class AuthService {
  // Uuid doesn't provide a const constructor; ignore the prefer_const_constructors lint here.
  // ignore: prefer_const_constructors
  static final _uuid = Uuid();
  
  final SecureStorageInterface _secureStorage;

  AuthService({SecureStorageInterface? secureStorage}) : _secureStorage = secureStorage ?? const FlutterSecureStorageWrapper();

  // Inicializar usuarios por defecto
  Future<void> initializeDefaultUsers() async {
    final usersBox = Hive.box('usersBox');

    // Verificar si ya existen usuarios
    if (usersBox.isNotEmpty) return;

    // Crear usuarios por defecto
    final defaultUsers = [
      UserModel(
        id: _uuid.v4(),
        name: 'Administrador',
        email: 'admin@mototaxi.com',
        phone: '1111111111',
        role: UserRole.admin,
        passwordHash: UserModel.hashPassword('admin123'),
      ),
      UserModel(
        id: _uuid.v4(),
        name: 'Conductor Demo',
        email: 'conductor@mototaxi.com',
        phone: '2222222222',
        role: UserRole.driver,
        passwordHash: UserModel.hashPassword('conductor123'),
      ),
      UserModel(
        id: _uuid.v4(),
        name: 'Cliente Demo',
        email: 'cliente@mototaxi.com',
        phone: '3333333333',
        role: UserRole.client,
        passwordHash: UserModel.hashPassword('cliente123'),
      ),
    ];

    // Guardar usuarios en Hive
    for (final user in defaultUsers) {
      await usersBox.put(user.id, user.toJson());
    }
  }

  // Registro mejorado con validación de roles
  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.client, // Por defecto cliente
    bool allowNonClient = false,
  }) async {
    final usersBox = Hive.box('usersBox');

    // Verificar si el email ya existe
    final existingUsers = usersBox.values.where((userData) {
      final user = UserModel.fromJson(Map.castFrom(userData));
      return user.email == email || user.phone == phone;
    });

    if (existingUsers.isNotEmpty) {
      throw Exception('Ya existe un usuario con este email o teléfono');
    }

    // Solo permitir registro de clientes por la ruta pública. Los conductores
    // pueden crearse internamente por un administrador pasando
    // `allowNonClient: true`.
    if (!allowNonClient && role != UserRole.client) {
      throw Exception('Solo se permite registro de clientes. Los conductores deben ser creados por un administrador.');
    }

    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      phone: phone,
      role: role,
      passwordHash: UserModel.hashPassword(password),
    );

    await usersBox.put(user.id, user.toJson());
    // Devolver usuario sin exposición de passwordHash
    return user.withoutPassword();
  }

  // Login mejorado con verificación de contraseña
  Future<UserModel?> login({required String identifier, required String password}) async {
    final usersBox = Hive.box('usersBox');
    final sessionBox = Hive.box('sessionBox');

    // Buscar usuario por email o teléfono
    UserModel? foundUser;
    for (final userData in usersBox.values) {
      final user = UserModel.fromJson(Map.castFrom(userData));
      if (user.email == identifier || user.phone == identifier) {
        foundUser = user;
        break;
      }
    }

    if (foundUser == null) return null;

    // Verificar contraseña
    if (!foundUser.verifyPassword(password)) return null;

    // Migración automática: si el hash es SHA256 antiguo, rehashear con PBKDF2
    if (foundUser.passwordHash != null && PasswordHasher.isLegacyHash(foundUser.passwordHash!)) {
      final newHashedUser = foundUser.withoutPassword().copyWith(
        passwordHash: UserModel.hashPassword(password),
      );
      await usersBox.put(foundUser.id, newHashedUser.toJson());
    }

    // Guardar sesión: currentUserId en almacenamiento seguro, loggedIn en Hive
    await _secureStorage.write(key: 'currentUserId', value: foundUser.id);
    await sessionBox.put('loggedIn', true);

    return foundUser.withoutPassword();
  }

  Future<void> logout() async {
    await (Hive.box('sessionBox')).put('loggedIn', false);
    await _secureStorage.delete(key: 'currentUserId');
  }

  Future<bool> isLoggedIn() async {
    return (Hive.box('sessionBox')).get('loggedIn', defaultValue: false) as bool;
  }

  Future<UserModel?> getCurrentUser() async {
    final usersBox = Hive.box('usersBox');

    // Recuperar userId desde almacenamiento seguro
    final userId = await _secureStorage.read(key: 'currentUserId');
    if (userId == null) return null;

    final userData = usersBox.get(userId);
    if (userData == null) return null;

    final user = UserModel.fromJson(Map.castFrom(userData));
    return user.withoutPassword();
  }

  // Obtener todos los usuarios (solo para admin)
  Future<List<UserModel>> getAllUsers() async {
    final usersBox = Hive.box('usersBox');
    return usersBox.values.map((userData) {
      final user = UserModel.fromJson(Map.castFrom(userData));
      return user.withoutPassword();
    }).toList();
  }

  // Crear conductor (solo admin)
  Future<UserModel?> createDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser?.role != UserRole.admin) {
      throw Exception('Solo los administradores pueden crear conductores');
    }

    return register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: UserRole.driver,
      allowNonClient: true,
    );
  }

  // Eliminar usuario (solo admin)
  Future<void> deleteUser(String userId) async {
    final currentUser = await getCurrentUser();
    if (currentUser?.role != UserRole.admin) {
      throw Exception('Solo los administradores pueden eliminar usuarios');
    }

    final usersBox = Hive.box('usersBox');
    await usersBox.delete(userId);
  }
}

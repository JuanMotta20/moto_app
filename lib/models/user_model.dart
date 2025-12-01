import '../utils/password_hasher.dart';

enum UserRole { admin, driver, client }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? passwordHash; // Solo para almacenamiento interno

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.passwordHash,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name, // Guardar como string
        'passwordHash': passwordHash,
      };

  factory UserModel.fromJson(Map<dynamic, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (role) => role.name == (json['role'] as String? ?? 'client'),
          orElse: () => UserRole.client,
        ),
        passwordHash: json['passwordHash'] as String?,
      );

  // Crear usuario sin contraseña para mostrar en UI
  UserModel withoutPassword() => UserModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

  // Crear una copia con algunos campos modificados (útil para migración de hashes)
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? passwordHash,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        passwordHash: passwordHash ?? this.passwordHash,
      );

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.driver:
        return 'Conductor';
      case UserRole.client:
        return 'Cliente';
    }
  }

  // Método para hashear contraseñas con PBKDF2 + salt
  static String hashPassword(String password) {
    return PasswordHasher.hash(password);
  }

  // Verificar contraseña contra hash PBKDF2 (soporta migración de SHA256)
  bool verifyPassword(String password) {
    if (passwordHash == null) return false;
    return PasswordHasher.verify(password, passwordHash!);
  }
}

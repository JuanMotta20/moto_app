import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageInterface {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class FlutterSecureStorageWrapper implements SecureStorageInterface {
  const FlutterSecureStorageWrapper();
  static const FlutterSecureStorage _impl = FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String? value}) async {
    await _impl.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _impl.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _impl.delete(key: key);
  }
}

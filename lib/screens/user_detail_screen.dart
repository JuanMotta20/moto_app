import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final user = args is UserModel ? args : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Usuario')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: user == null
              ? const Center(child: Text('Usuario no encontrado'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(user.email),
                    const SizedBox(height: 8),
                    Text('Rol: ${user.roleDisplayName}'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver'),
                        ),
                        const SizedBox(width: 12),
                        if (user.role != UserRole.admin)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error),
                            onPressed: () async {
                              // capture context-bound instances before async gaps
                              final auth = Provider.of<AuthProvider>(context,
                                  listen: false);
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Eliminar usuario'),
                                  content: Text('¿Eliminar a ${user.name}?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(dCtx).pop(false),
                                        child: const Text('Cancelar')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(dCtx).pop(true),
                                        child: const Text('Eliminar')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await auth.deleteUser(user.id);
                                if (!mounted) return;
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('Usuario eliminado')));
                                navigator.pop();
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

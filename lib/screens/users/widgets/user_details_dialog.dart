import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user.dart';
import '../../../core/constants.dart';

class UserDetailsDialog extends StatelessWidget {
  final User user;
  final User currentUser;

  const UserDetailsDialog({
    super.key,
    required this.user,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: user.isActive ? Colors.green : Colors.grey,
                    child: Text(
                      user.firstName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.role.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Información Personal', [
                        _buildDetailRow('Nombre', user.firstName, Icons.person),
                        _buildDetailRow(
                          'Apellido',
                          user.lastName,
                          Icons.person_outline,
                        ),
                        _buildDetailRow('Email', user.email, Icons.email),
                        if (user.phoneNumber != null &&
                            user.phoneNumber!.isNotEmpty)
                          _buildDetailRow(
                            'Teléfono',
                            user.phoneNumber!,
                            Icons.phone,
                          ),
                      ]),
                      const SizedBox(height: 24),

                      _buildDetailSection('Información del Sistema', [
                        _buildDetailRow(
                          'Rol',
                          user.role.displayName,
                          Icons.badge,
                        ),
                        _buildDetailRow(
                          'Estado',
                          user.isActive ? 'Activo' : 'Inactivo',
                          user.isActive ? Icons.check_circle : Icons.cancel,
                          valueColor: user.isActive ? Colors.green : Colors.red,
                        ),
                        _buildDetailRow(
                          'ID de Usuario',
                          '${user.id.substring(0, 8)}...',
                          Icons.fingerprint,
                        ),
                        _buildDetailRow(
                          'Fecha de Creación',
                          _formatDate(user.createdAt),
                          Icons.calendar_today,
                        ),
                        if (user.updatedAt != null)
                          _buildDetailRow(
                            'Última Actualización',
                            _formatDate(user.updatedAt!),
                            Icons.update,
                          ),
                      ]),

                      if (user.id == currentUser.id) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Este es tu usuario actual',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...details,
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

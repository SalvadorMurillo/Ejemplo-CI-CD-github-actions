import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/bap_provider.dart';
import '../../models/models.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import 'add_bap_record_screen.dart';

class BAPDetailScreen extends StatefulWidget {
  final String recordId;

  const BAPDetailScreen({super.key, required this.recordId});

  @override
  State<BAPDetailScreen> createState() => _BAPDetailScreenState();
}

class _BAPDetailScreenState extends State<BAPDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BAPProvider>().loadRecordById(widget.recordId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle BAP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Consumer<BAPProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadRecordById(widget.recordId),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final record = provider.selectedRecord;
          if (record == null) {
            return const Center(child: Text('Registro no encontrado'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderSection(record: record),
              const SizedBox(height: 24),
              _DetailsSection(record: record),
              const SizedBox(height: 24),
              _InterventionsSection(record: record),
              const SizedBox(height: 24),
              _FollowUpsSection(
                record: record,
                onAddFollowUp: () => _showAddFollowUpDialog(context, record),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    final record = context.read<BAPProvider>().selectedRecord;
    if (record != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddBAPRecordScreen(existingRecord: record),
        ),
      ).then((_) {
        context.read<BAPProvider>().loadRecordById(widget.recordId);
      });
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este registro BAP?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<BAPProvider>();
              final success = await provider.deleteRecord(widget.recordId);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddFollowUpDialog(BuildContext context, BAPRecord record) {
    final observationsController = TextEditingController();
    final evolutionController = TextEditingController();
    final strategiesController = TextEditingController();
    final nextStepsController = TextEditingController();
    DateTime followUpDate = DateTime.now();
    DateTime? nextFollowUpDate;
    final strategies = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Seguimiento'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Follow-up date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha de seguimiento'),
                    subtitle: Text(
                      '${followUpDate.day}/${followUpDate.month}/${followUpDate.year}',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: followUpDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => followUpDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Observations
                  TextField(
                    controller: observationsController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Evolution
                  TextField(
                    controller: evolutionController,
                    decoration: const InputDecoration(
                      labelText: 'Evolución',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Updated strategies
                  const Text('Estrategias actualizadas'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: strategiesController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Agregar estrategia...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (strategiesController.text.trim().isNotEmpty) {
                            setState(() {
                              strategies.add(strategiesController.text.trim());
                              strategiesController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (strategies.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: strategies.map((s) {
                        return Chip(
                          label: Text(s),
                          onDeleted: () {
                            setState(() => strategies.remove(s));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Next steps
                  TextField(
                    controller: nextStepsController,
                    decoration: const InputDecoration(
                      labelText: 'Próximos pasos',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Next follow-up date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Próximo seguimiento'),
                    subtitle: Text(
                      nextFollowUpDate != null
                          ? '${nextFollowUpDate!.day}/${nextFollowUpDate!.month}/${nextFollowUpDate!.year}'
                          : 'No programado',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nextFollowUpDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => nextFollowUpDate = null);
                            },
                          ),
                        const Icon(Icons.edit),
                      ],
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: nextFollowUpDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => nextFollowUpDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (observationsController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las observaciones son requeridas'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final authService = AuthService();
                final currentUser = authService.currentUser;

                if (currentUser == null) return;

                final followUp = BAPFollowUp(
                  id: const Uuid().v4(),
                  bapRecordId: record.id,
                  followUpById: currentUser.id,
                  followUpDate: followUpDate,
                  observations: observationsController.text.trim(),
                  evolution: evolutionController.text.trim().isEmpty
                      ? null
                      : evolutionController.text.trim(),
                  updatedStrategies: strategies,
                  nextSteps: nextStepsController.text.trim().isEmpty
                      ? null
                      : nextStepsController.text.trim(),
                  nextFollowUpDate: nextFollowUpDate,
                  attachmentUrls: [],
                  createdAt: DateTime.now(),
                );

                Navigator.pop(context);

                final provider = context.read<BAPProvider>();
                final success = await provider.addFollowUp(record.id, followUp);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seguimiento agregado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final BAPRecord record;

  const _HeaderSection({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTypeColor(record.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(record.type),
                    color: _getTypeColor(record.type),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.type.displayName,
                        style: TextStyle(
                          color: _getTypeColor(record.type),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: record.currentStatus ?? 'active'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(BAPType type) {
    switch (type) {
      case BAPType.learning:
        return Icons.school;
      case BAPType.behavioral:
        return Icons.psychology;
      case BAPType.social:
        return Icons.people;
      case BAPType.emotional:
        return Icons.favorite;
      case BAPType.physical:
        return Icons.accessibility;
      case BAPType.intellectual:
        return Icons.lightbulb;
      case BAPType.sensory:
        return Icons.hearing;
    }
  }

  Color _getTypeColor(BAPType type) {
    switch (type) {
      case BAPType.learning:
        return Colors.blue;
      case BAPType.behavioral:
        return Colors.purple;
      case BAPType.social:
        return Colors.green;
      case BAPType.emotional:
        return Colors.pink;
      case BAPType.physical:
        return Colors.orange;
      case BAPType.intellectual:
        return Colors.amber;
      case BAPType.sensory:
        return Colors.teal;
    }
  }
}

class _DetailsSection extends StatelessWidget {
  final BAPRecord record;

  const _DetailsSection({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Fecha de Detección',
              value: _formatDate(record.detectionDate),
            ),
            _DetailRow(
              icon: Icons.person,
              label: 'Identificado por',
              value: record.identifiedByName ?? 'No disponible',
            ),
            const SizedBox(height: 16),
            const Text(
              'Descripción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(record.description),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InterventionsSection extends StatelessWidget {
  final BAPRecord record;

  const _InterventionsSection({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estrategias de Intervención',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (record.interventionStrategies.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay estrategias definidas',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...record.interventionStrategies.asMap().entries.map(
                (entry) => ListTile(
                  leading: CircleAvatar(child: Text('${entry.key + 1}')),
                  title: Text(entry.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpsSection extends StatelessWidget {
  final BAPRecord record;
  final VoidCallback onAddFollowUp;

  const _FollowUpsSection({required this.record, required this.onAddFollowUp});

  @override
  Widget build(BuildContext context) {
    final sortedFollowUps = List<BAPFollowUp>.from(record.followUps)
      ..sort((a, b) => b.followUpDate.compareTo(a.followUpDate));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seguimientos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: onAddFollowUp,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const Divider(),
            if (sortedFollowUps.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay seguimientos registrados',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...sortedFollowUps.map(
                (followUp) => _FollowUpCard(followUp: followUp),
              ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  final BAPFollowUp followUp;

  const _FollowUpCard({required this.followUp});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDate(followUp.followUpDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (followUp.followUpByName != null)
                  Chip(
                    label: Text(followUp.followUpByName!),
                    avatar: const Icon(Icons.person, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Observaciones:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(followUp.observations),
            if (followUp.evolution != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Evolución:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(followUp.evolution!),
            ],
            if (followUp.updatedStrategies.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Estrategias actualizadas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: followUp.updatedStrategies
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
            ],
            if (followUp.nextSteps != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Próximos pasos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(followUp.nextSteps!),
            ],
            if (followUp.nextFollowUpDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Próximo seguimiento: ${_formatDate(followUp.nextFollowUpDate!)}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.red;
        label = 'Activo';
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'En Progreso';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resuelto';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

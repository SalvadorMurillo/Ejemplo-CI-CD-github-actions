import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bap_provider.dart';
import '../../models/models.dart';
import '../../core/constants.dart';

class BAPProgressReportScreen extends StatefulWidget {
  final String? studentId;

  const BAPProgressReportScreen({super.key, this.studentId});

  @override
  State<BAPProgressReportScreen> createState() =>
      _BAPProgressReportScreenState();
}

class _BAPProgressReportScreenState extends State<BAPProgressReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  BAPType? _selectedType;
  List<BAPRecord> _filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 90));
    _endDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  Future<void> _loadRecords() async {
    final provider = context.read<BAPProvider>();
    if (widget.studentId != null) {
      provider.setStudentFilter(widget.studentId);
    }
    if (_selectedType != null) {
      provider.setTypeFilter(_selectedType);
    }
    await provider.loadRecords(refresh: true);
    _applyFilters();
  }

  void _applyFilters() {
    final provider = context.read<BAPProvider>();
    setState(() {
      _filteredRecords = provider.records.where((record) {
        bool matchesDate = true;
        if (_startDate != null) {
          matchesDate =
              record.detectionDate.isAfter(_startDate!) ||
              record.detectionDate.isAtSameMomentAs(_startDate!);
        }
        if (_endDate != null && matchesDate) {
          matchesDate =
              record.detectionDate.isBefore(_endDate!) ||
              record.detectionDate.isAtSameMomentAs(_endDate!);
        }
        return matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Progreso BAP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _generatePDFReport,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterSection(
            startDate: _startDate,
            endDate: _endDate,
            selectedType: _selectedType,
            onStartDateChanged: (date) {
              setState(() => _startDate = date);
              _applyFilters();
            },
            onEndDateChanged: (date) {
              setState(() => _endDate = date);
              _applyFilters();
            },
            onTypeChanged: (type) {
              setState(() => _selectedType = type);
              _loadRecords();
            },
          ),
          Expanded(
            child: Consumer<BAPProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_filteredRecords.isEmpty) {
                  return const Center(
                    child: Text('No hay registros en el período seleccionado'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SummaryCard(records: _filteredRecords),
                    const SizedBox(height: 16),
                    _TypeBreakdownCard(records: _filteredRecords),
                    const SizedBox(height: 16),
                    _StatusBreakdownCard(records: _filteredRecords),
                    const SizedBox(height: 16),
                    _DetailedRecordsSection(records: _filteredRecords),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _generatePDFReport() {
    // TODO: Implement PDF generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generación de PDF en desarrollo')),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final BAPType? selectedType;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(BAPType?) onTypeChanged;

  const _FilterSection({
    required this.startDate,
    required this.endDate,
    required this.selectedType,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Desde'),
                    subtitle: Text(
                      startDate != null
                          ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                          : 'No seleccionado',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      onStartDateChanged(date);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Hasta'),
                    subtitle: Text(
                      endDate != null
                          ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                          : 'No seleccionado',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      onEndDateChanged(date);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Tipo de Barrera'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: selectedType == null,
                  onSelected: (selected) {
                    if (selected) onTypeChanged(null);
                  },
                ),
                ...BAPType.values.map(
                  (type) => FilterChip(
                    label: Text(type.displayName),
                    selected: selectedType == type,
                    onSelected: (selected) {
                      onTypeChanged(selected ? type : null);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<BAPRecord> records;

  const _SummaryCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final totalFollowUps = records.fold<int>(
      0,
      (sum, record) => sum + record.followUps.length,
    );
    final avgFollowUps = records.isEmpty ? 0 : totalFollowUps / records.length;
    final activeRecords = records
        .where((r) => r.currentStatus == 'active')
        .length;
    final resolvedRecords = records
        .where((r) => r.currentStatus == 'resolved')
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _SummaryRow(label: 'Total de BAP', value: '${records.length}'),
            _SummaryRow(label: 'BAP Activos', value: '$activeRecords'),
            _SummaryRow(label: 'BAP Resueltos', value: '$resolvedRecords'),
            _SummaryRow(
              label: 'Total de Seguimientos',
              value: '$totalFollowUps',
            ),
            _SummaryRow(
              label: 'Promedio de Seguimientos',
              value: avgFollowUps.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBreakdownCard extends StatelessWidget {
  final List<BAPRecord> records;

  const _TypeBreakdownCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final typeBreakdown = <BAPType, int>{};
    for (final record in records) {
      typeBreakdown[record.type] = (typeBreakdown[record.type] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución por Tipo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...typeBreakdown.entries.map(
              (entry) => _SummaryRow(
                label: entry.key.displayName,
                value: '${entry.value}',
                percentage: records.isEmpty
                    ? '0%'
                    : '${((entry.value / records.length) * 100).toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  final List<BAPRecord> records;

  const _StatusBreakdownCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final statusBreakdown = <String, int>{};
    for (final record in records) {
      final status = record.currentStatus ?? 'active';
      statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución por Estado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...statusBreakdown.entries.map(
              (entry) => _SummaryRow(
                label: _getStatusLabel(entry.key),
                value: '${entry.value}',
                percentage: records.isEmpty
                    ? '0%'
                    : '${((entry.value / records.length) * 100).toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'in_progress':
        return 'En Progreso';
      case 'resolved':
        return 'Resuelto';
      default:
        return status;
    }
  }
}

class _DetailedRecordsSection extends StatelessWidget {
  final List<BAPRecord> records;

  const _DetailedRecordsSection({required this.records});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de Registros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...records.map((record) => _RecordDetailTile(record: record)),
          ],
        ),
      ),
    );
  }
}

class _RecordDetailTile extends StatelessWidget {
  final BAPRecord record;

  const _RecordDetailTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: ExpansionTile(
        leading: Icon(_getTypeIcon(record.type)),
        title: Text(record.title),
        subtitle: Text(
          '${record.type.displayName} - ${_getStatusLabel(record.currentStatus ?? "active")}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción: ${record.description}'),
                const SizedBox(height: 8),
                Text('Detectado: ${_formatDate(record.detectionDate)}'),
                const SizedBox(height: 8),
                Text('Seguimientos: ${record.followUps.length}'),
                if (record.interventionStrategies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Estrategias:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...record.interventionStrategies.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('• $s'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'in_progress':
        return 'En Progreso';
      case 'resolved':
        return 'Resuelto';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? percentage;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (percentage != null) ...[
                const SizedBox(width: 8),
                Text(
                  percentage!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

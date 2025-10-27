import '../../core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bap_provider.dart';
import '../../widgets/adaptive_navigation.dart';
import 'add_bap_record_screen.dart';
import 'bap_detail_screen.dart';

class BAPListScreen extends StatefulWidget {
  final String? studentId;

  const BAPListScreen({super.key, this.studentId});

  @override
  State<BAPListScreen> createState() => _BAPListScreenState();
}

class _BAPListScreenState extends State<BAPListScreen> {
  final ScrollController _scrollController = ScrollController();
  BAPType? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BAPProvider>();
      if (widget.studentId != null) {
        provider.setStudentFilter(widget.studentId);
      } else {
        // Clear student filter when viewing all records
        provider.setStudentFilter(null);
      }
      provider.loadRecords(refresh: true);
      provider.loadPendingFollowUps();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = context.read<BAPProvider>();
      if (!provider.isLoading && provider.hasMoreData) {
        provider.loadRecords();
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de Barrera',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _selectedType == null,
                        onSelected: (selected) {
                          setState(() => _selectedType = null);
                        },
                      ),
                      ...BAPType.values.map(
                        (type) => FilterChip(
                          label: Text(_getBAPTypeName(type)),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(
                              () => _selectedType = selected ? type : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Estado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() => _selectedStatus = null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Activo'),
                        selected: _selectedStatus == 'active',
                        onSelected: (selected) {
                          setState(
                            () => _selectedStatus = selected ? 'active' : null,
                          );
                        },
                      ),
                      FilterChip(
                        label: const Text('En Progreso'),
                        selected: _selectedStatus == 'in_progress',
                        onSelected: (selected) {
                          setState(
                            () => _selectedStatus = selected
                                ? 'in_progress'
                                : null,
                          );
                        },
                      ),
                      FilterChip(
                        label: const Text('Resuelto'),
                        selected: _selectedStatus == 'resolved',
                        onSelected: (selected) {
                          setState(
                            () =>
                                _selectedStatus = selected ? 'resolved' : null,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedStatus = null;
              });
              final provider = context.read<BAPProvider>();
              provider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<BAPProvider>();
              provider.setTypeFilter(_selectedType);
              provider.setStatusFilter(_selectedStatus);
              provider.applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMainScreen = widget.studentId == null;

    final appBarWidget = AppBar(
      title: Text(
        widget.studentId != null
            ? 'BAP - Estudiante'
            : 'Barreras de Aprendizaje (BAP)',
      ),
      actions: [
        Consumer<BAPProvider>(
          builder: (context, provider, _) {
            if (provider.pendingFollowUps.isNotEmpty) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showPendingFollowUpsDialog(context),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${provider.pendingFollowUps.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: () => _showStatistics(context),
        ),
      ],
    );

    final fabWidget = FloatingActionButton(
      onPressed: () => _navigateToAdd(context),
      tooltip: 'Agregar BAP',
      child: const Icon(Icons.add),
    );

    final bodyWidget = Consumer<BAPProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.records.isEmpty) {
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
                  onPressed: () => provider.loadRecords(refresh: true),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (provider.records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No hay registros BAP',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agrega el primer registro usando el botón +',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRecords(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.records.length + (provider.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.records.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final record = provider.records[index];
              return _BAPRecordCard(
                record: record,
                onTap: () => _navigateToDetail(context, record.id),
              );
            },
          ),
        );
      },
    );

    // Wrap with adaptive navigation only if it's the main screen
    if (isMainScreen) {
      return AdaptiveNavigationScaffold(
        currentRoute: AppConstants.bapRoute,
        appBar: appBarWidget,
        floatingActionButton: fabWidget,
        body: bodyWidget,
      );
    }

    return Scaffold(
      appBar: appBarWidget,
      floatingActionButton: fabWidget,
      body: bodyWidget,
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBAPRecordScreen(studentId: widget.studentId),
      ),
    ).then((_) {
      context.read<BAPProvider>().loadRecords(refresh: true);
    });
  }

  void _navigateToDetail(BuildContext context, String recordId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BAPDetailScreen(recordId: recordId),
      ),
    ).then((_) {
      context.read<BAPProvider>().loadRecords(refresh: true);
    });
  }

  void _showPendingFollowUpsDialog(BuildContext context) {
    final provider = context.read<BAPProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seguimientos Pendientes'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.pendingFollowUps.length,
            itemBuilder: (context, index) {
              final record = provider.pendingFollowUps[index];
              return ListTile(
                leading: Icon(_getTypeIcon(record.type)),
                title: Text(record.title),
                subtitle: Text(
                  'Último seguimiento: ${record.followUps.isNotEmpty ? _formatDate(record.followUps.last.followUpDate) : "Nunca"}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDetail(context, record.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    final provider = context.read<BAPProvider>();
    final stats = provider.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas BAP'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow(label: 'Total', value: stats['total'].toString()),
              _StatRow(label: 'Activos', value: stats['active'].toString()),
              _StatRow(
                label: 'En Progreso',
                value: stats['in_progress'].toString(),
              ),
              _StatRow(label: 'Resueltos', value: stats['resolved'].toString()),
              const Divider(),
              const Text(
                'Por Tipo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(stats['by_type'] as Map<String, int>).entries.map(
                (entry) => _StatRow(
                  label: BAPType.values
                      .firstWhere((t) => t.name == entry.key)
                      .displayName,
                  value: entry.value.toString(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getBAPTypeName(BAPType type) {
    switch (type) {
      case BAPType.learning:
        return 'Aprendizaje';
      case BAPType.behavioral:
        return 'Conductual';
      case BAPType.social:
        return 'Social';
      case BAPType.emotional:
        return 'Emocional';
      case BAPType.physical:
        return 'Física';
      case BAPType.intellectual:
        return 'Intelectual';
      case BAPType.sensory:
        return 'Sensorial';
    }
  }
}

class _BAPRecordCard extends StatelessWidget {
  final dynamic record;
  final VoidCallback onTap;

  const _BAPRecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(record.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(record.type),
                      color: _getTypeColor(record.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getBAPTypeName(
                            record.type,
                          ), // ✅ Changed from record.type.displayName
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getTypeColor(record.type),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: record.currentStatus ?? 'active'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                record.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Detectado: ${_formatDate(record.detectionDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (record.identifiedByName != null) ...[
                    Icon(Icons.person, size: 14, color: theme.disabledColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        record.identifiedByName!,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (record.followUps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timeline, size: 14, color: theme.disabledColor),
                    const SizedBox(width: 4),
                    Text(
                      '${record.followUps.length} seguimiento(s)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Add this helper method to the _BAPRecordCard class
  String _getBAPTypeName(BAPType type) {
    switch (type) {
      case BAPType.learning:
        return 'Aprendizaje';
      case BAPType.behavioral:
        return 'Conductual';
      case BAPType.social:
        return 'Social';
      case BAPType.emotional:
        return 'Emocional';
      case BAPType.physical:
        return 'Física';
      case BAPType.intellectual:
        return 'Intelectual';
      case BAPType.sensory:
        return 'Sensorial';
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attitude_provider.dart';
import '../../models/models.dart';
import '../../core/constants.dart';
import '../../widgets/adaptive_navigation.dart';
import 'add_attitude_screen.dart';
import 'attitude_analytics_screen.dart';

class AttitudeListScreen extends StatefulWidget {
  final String? studentId;

  const AttitudeListScreen({super.key, this.studentId});

  @override
  State<AttitudeListScreen> createState() => _AttitudeListScreenState();
}

class _AttitudeListScreenState extends State<AttitudeListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupScrollListener();
    });
  }

  void _loadData() {
    final attitudeProvider = context.read<AttitudeProvider>();
    if (widget.studentId != null) {
      attitudeProvider.loadAttitudesForStudent(widget.studentId!);
    } else {
      // Clear student filter when viewing all records
      attitudeProvider.setStudentFilter(null);
      attitudeProvider.loadAttitudes(refresh: true);
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        final attitudeProvider = context.read<AttitudeProvider>();
        if (attitudeProvider.hasMoreData && !attitudeProvider.isLoading) {
          attitudeProvider.loadAttitudes();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMainScreen = widget.studentId == null;

    final appBarWidget = AppBar(
      title: Text(
        widget.studentId != null
            ? 'Actitudes del Estudiante'
            : 'Gestión de Actitudes',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: () => _showStatisticsDialog(context),
        ),
        if (widget.studentId != null)
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _navigateToAnalytics(context),
          ),
      ],
    );

    final fabWidget = FloatingActionButton(
      onPressed: () => _navigateToAddAttitude(context),
      tooltip: 'Registrar Actitud',
      child: const Icon(Icons.add),
    );

    final bodyWidget = Consumer<AttitudeProvider>(
      builder: (context, attitudeProvider, child) {
        if (attitudeProvider.isLoading && attitudeProvider.attitudes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (attitudeProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(attitudeProvider.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    attitudeProvider.clearError();
                    _loadData();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (attitudeProvider.attitudes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_satisfied,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text('No hay registros de actitudes'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddAttitude(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar Primera Actitud'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                attitudeProvider.attitudes.length +
                (attitudeProvider.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == attitudeProvider.attitudes.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final attitude = attitudeProvider.attitudes[index];
              return _buildAttitudeCard(attitude);
            },
          ),
        );
      },
    );

    // Wrap with adaptive navigation only if it's the main screen
    if (isMainScreen) {
      return AdaptiveNavigationScaffold(
        currentRoute: AppConstants.attitudesRoute,
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

  Widget _buildAttitudeCard(AttitudeRecord attitude) {
    final provider = context.read<AttitudeProvider>();
    final color = provider.getAttitudeColor(attitude);
    final icon = provider.getAttitudeIcon(attitude);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAttitudeDetails(context, attitude),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attitude.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          attitude.attitudeTypeDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (attitude.frequency != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        attitude.frequency!,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                attitude.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(attitude.observationDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (attitude.context != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        attitude.context!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                  if (attitude.observedByName != null) ...[
                    const Spacer(),
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      attitude.observedByName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttitudeDetails(BuildContext context, AttitudeRecord attitude) {
    final provider = context.read<AttitudeProvider>();
    final color = provider.getAttitudeColor(attitude);
    final icon = provider.getAttitudeIcon(attitude);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attitude.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  attitude.attitudeTypeDisplayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection(
                        'Descripción',
                        attitude.description,
                        Icons.description,
                      ),
                      if (attitude.context != null)
                        _buildDetailSection(
                          'Contexto',
                          attitude.context!,
                          Icons.location_on,
                        ),
                      if (attitude.frequency != null)
                        _buildDetailSection(
                          'Frecuencia',
                          attitude.frequency!,
                          Icons.repeat,
                        ),
                      if (attitude.interventionApplied != null)
                        _buildDetailSection(
                          'Intervención Aplicada',
                          attitude.interventionApplied!,
                          Icons.build,
                          color: Colors.blue,
                        ),
                      _buildDetailSection(
                        'Fecha de Observación',
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(attitude.observationDate),
                        Icons.calendar_today,
                      ),
                      if (attitude.observedByName != null)
                        _buildDetailSection(
                          'Observado por',
                          attitude.observedByName!,
                          Icons.person,
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(context, attitude);
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color ?? Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color ?? Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final provider = context.read<AttitudeProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Actitudes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tipo de Actitud'),
                subtitle: Text(provider.selectedAttitudeType ?? 'Todos'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showTypeFilterDialog(context);
                },
              ),
              ListTile(
                title: const Text('Rango de Fechas'),
                subtitle: Text(
                  provider.startDate != null
                      ? '${DateFormat('dd/MM/yyyy').format(provider.startDate!)} - ${provider.endDate != null ? DateFormat('dd/MM/yyyy').format(provider.endDate!) : 'Ahora'}'
                      : 'Sin filtro',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangeFilter(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Limpiar Filtros'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showTypeFilterDialog(BuildContext context) {
    final provider = context.read<AttitudeProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Tipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('Todos'),
              value: null,
              groupValue: provider.selectedAttitudeType,
              onChanged: (value) {
                provider.setAttitudeTypeFilter(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String?>(
              title: const Text('Positivas 😊'),
              value: 'positive',
              groupValue: provider.selectedAttitudeType,
              onChanged: (value) {
                provider.setAttitudeTypeFilter(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String?>(
              title: const Text('Negativas 😟'),
              value: 'negative',
              groupValue: provider.selectedAttitudeType,
              onChanged: (value) {
                provider.setAttitudeTypeFilter(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangeFilter(BuildContext context) async {
    final provider = context.read<AttitudeProvider>();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: provider.startDate != null
          ? DateTimeRange(
              start: provider.startDate!,
              end: provider.endDate ?? DateTime.now(),
            )
          : null,
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  void _showStatisticsDialog(BuildContext context) {
    final provider = context.read<AttitudeProvider>();
    final positiveCount = provider.getPositiveAttitudes().length;
    final negativeCount = provider.getNegativeAttitudes().length;
    final byFrequency = provider.getAttitudesByFrequency();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Actitudes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(
                'Total de Actitudes:',
                '${provider.attitudes.length}',
              ),
              _buildStatRow(
                'Actitudes Positivas:',
                '$positiveCount',
                color: Colors.green,
              ),
              _buildStatRow(
                'Actitudes Negativas:',
                '$negativeCount',
                color: Colors.orange,
              ),
              if (byFrequency.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Por Frecuencia:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...byFrequency.entries.map(
                  (e) => _buildStatRow('${e.key}:', '${e.value}'),
                ),
              ],
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

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AttitudeRecord attitude) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Está seguro que desea eliminar este registro de actitud? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<AttitudeProvider>()
                  .deleteAttitude(attitude.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToAddAttitude(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAttitudeScreen(studentId: widget.studentId),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _navigateToAnalytics(BuildContext context) {
    if (widget.studentId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AttitudeAnalyticsScreen(studentId: widget.studentId!),
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medical_provider.dart';
import '../../config/theme.dart';
import '../../core/constants.dart';
import '../../widgets/adaptive_navigation.dart';
import 'medical_record_detail_screen.dart';
import 'medical_record_form_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String? studentId;

  const MedicalRecordsScreen({super.key, this.studentId});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
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
      final provider = context.read<MedicalProvider>();
      if (!provider.isLoading && provider.hasMoreData) {
        provider.loadRecords();
      }
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<MedicalProvider>();
    if (widget.studentId != null) {
      await provider.loadRecordForStudent(widget.studentId!);
    } else {
      await provider.loadRecords(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.studentId != null) {
      return _buildStudentMedicalRecord();
    }
    return _buildMedicalRecordsList();
  }

  Widget _buildStudentMedicalRecord() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expediente Médico'),
        actions: [
          Consumer<MedicalProvider>(
            builder: (context, provider, child) {
              if (provider.selectedRecord != null) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _navigateToEditRecord(provider.selectedRecord!),
                  tooltip: 'Editar expediente',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<MedicalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedRecord == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.selectedRecord == null) {
            return _buildEmptyState(provider);
          }

          return MedicalRecordDetailScreen(
            record: provider.selectedRecord!,
            student: provider.selectedStudent,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(MedicalProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay expediente médico',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un expediente médico para este estudiante',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateRecord(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Expediente'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsList() {
    final appBarWidget = AppBar(
      title: const Text('Expedientes Médicos'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: _showFilterDialog,
          tooltip: 'Filtros',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<MedicalProvider>().loadRecords(refresh: true);
          },
          tooltip: 'Actualizar',
        ),
      ],
    );

    final bodyWidget = Column(
      children: [
        // Search bar removed
        _buildActiveFilters(),
        Expanded(
          child: Consumer<MedicalProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.records.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null && provider.records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.loadRecords(refresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.records.isEmpty) {
                return _buildEmptyListState();
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadRecords(refresh: true),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.records.length + 1,
                  itemBuilder: (context, index) {
                    if (index == provider.records.length) {
                      if (provider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final record = provider.records[index];
                    return _buildRecordCard(record);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    return AdaptiveNavigationScaffold(
      currentRoute: AppConstants.medicalRoute,
      appBar: appBarWidget,
      body: bodyWidget,
    );
  }

  Widget _buildEmptyListState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay expedientes médicos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Los expedientes médicos aparecerán aquí',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(
                      Icons.medical_services,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.studentFullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (record.studentEnrollment != null)
                          Text(
                            'Matrícula: ${record.studentEnrollment}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        if (record.bloodType != null)
                          Text(
                            'Tipo sanguíneo: ${_getBloodTypeDisplay(record.bloodType!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          )
                        else
                          Text(
                            'Tipo sanguíneo: No especificado',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (record.knownAllergies.isNotEmpty)
                    _buildInfoChip(
                      Icons.warning_amber,
                      '${record.knownAllergies.length} Alergias',
                      Colors.orange,
                    ),
                  if (record.chronicConditions.isNotEmpty)
                    _buildInfoChip(
                      Icons.healing,
                      '${record.chronicConditions.length} Condiciones',
                      Colors.blue,
                    ),
                  if (record.diagnoses.isNotEmpty)
                    _buildInfoChip(
                      Icons.medical_information,
                      '${record.diagnoses.length} Diagnósticos',
                      Colors.purple,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to safely get blood type display name
  String _getBloodTypeDisplay(BloodType bloodType) {
    try {
      return bloodType.displayName;
    } catch (e) {
      print('Error getting blood type display name: $e');
      return 'Desconocido';
    }
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      backgroundColor: color.withOpacity(0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _navigateToDetail(record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<MedicalProvider>(),
          child: MedicalRecordDetailScreen(record: record),
        ),
      ),
    );
  }

  void _navigateToCreateRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<MedicalProvider>(),
          child: MedicalRecordFormScreen(studentId: widget.studentId),
        ),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToEditRecord(record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<MedicalProvider>(),
          child: MedicalRecordFormScreen(
            studentId: widget.studentId,
            existingRecord: record,
          ),
        ),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildActiveFilters() {
    return Consumer<MedicalProvider>(
      builder: (context, provider, child) {
        final hasFilters =
            provider.selectedGrade != null ||
            provider.selectedGroup != null ||
            provider.startDate != null ||
            provider.endDate != null;

        if (!hasFilters) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (provider.selectedGrade != null)
                      _buildFilterChip(
                        'Grado: ${provider.selectedGrade}',
                        () => provider.setGradeFilter(null),
                      ),
                    if (provider.selectedGroup != null)
                      _buildFilterChip(
                        'Grupo: ${provider.selectedGroup}',
                        () => provider.setGroupFilter(null),
                      ),
                    if (provider.startDate != null || provider.endDate != null)
                      _buildFilterChip(
                        'Fecha: ${_formatDateRange(provider.startDate, provider.endDate)}',
                        () => provider.setDateRange(null, null),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => provider.clearFilters(),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Limpiar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.primary),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${_formatDate(start)} - ${_formatDate(end)}';
    } else if (start != null) {
      return 'Desde ${_formatDate(start)}';
    } else if (end != null) {
      return 'Hasta ${_formatDate(end)}';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilterDialog() {
    final provider = context.read<MedicalProvider>();
    String? tempGrade = provider.selectedGrade;
    String? tempGroup = provider.selectedGroup;
    DateTime? tempStartDate = provider.startDate;
    DateTime? tempEndDate = provider.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtros'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tempGrade,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Seleccionar grado',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'primero', child: Text('Primero')),
                    DropdownMenuItem(value: 'segundo', child: Text('Segundo')),
                    DropdownMenuItem(value: 'tercero', child: Text('Tercero')),
                  ],
                  onChanged: (value) => setState(() => tempGrade = value),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Grupo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: tempGroup,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ej: A, B, C',
                  ),
                  onChanged: (value) =>
                      tempGroup = value.isEmpty ? null : value,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rango de Fechas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => tempStartDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          tempStartDate != null
                              ? _formatDate(tempStartDate!)
                              : 'Desde',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: tempStartDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => tempEndDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          tempEndDate != null
                              ? _formatDate(tempEndDate!)
                              : 'Hasta',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (tempStartDate != null || tempEndDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        tempStartDate = null;
                        tempEndDate = null;
                      }),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpiar fechas'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                provider.setGradeFilter(tempGrade);
                provider.setGroupFilter(tempGroup);
                provider.setDateRange(tempStartDate, tempEndDate);
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/conduct_provider.dart';
import '../../providers/students_provider.dart';
import '../../models/models.dart';
import '../../core/constants.dart';
import '../../config/theme.dart';
import '../../services/file_service.dart';
import '../../services/database_service.dart';
import '../../services/pdf_report_service.dart';
import '../../widgets/adaptive_navigation.dart';
import 'add_conduct_report_screen.dart';
import 'edit_conduct_report_screen.dart';

class ConductListScreen extends StatefulWidget {
  final String? studentId;

  const ConductListScreen({super.key, this.studentId});

  @override
  State<ConductListScreen> createState() => _ConductListScreenState();
}

class _ConductListScreenState extends State<ConductListScreen> {
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
    final conductProvider = context.read<ConductProvider>();
    if (widget.studentId != null) {
      conductProvider.loadReportsForStudent(widget.studentId!);
    } else {
      // Clear student filter when viewing all records
      conductProvider.setStudentFilter(null);
      conductProvider.loadReports(refresh: true);
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        final conductProvider = context.read<ConductProvider>();
        if (conductProvider.hasMoreData && !conductProvider.isLoading) {
          conductProvider.loadReports();
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
            ? 'Reportes de Conducta'
            : 'Gestión de Conducta',
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
      ],
    );

    final fabWidget = FloatingActionButton(
      onPressed: () => _navigateToAddReport(context),
      tooltip: 'Agregar Reporte',
      child: const Icon(Icons.add),
    );

    final bodyWidget = Consumer<ConductProvider>(
      builder: (context, conductProvider, child) {
        if (conductProvider.isLoading && conductProvider.reports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (conductProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  conductProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (conductProvider.reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay reportes de conducta',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Presiona + para agregar uno',
                  style: TextStyle(color: Colors.grey),
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
                conductProvider.reports.length +
                (conductProvider.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == conductProvider.reports.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final report = conductProvider.reports[index];
              return _buildReportCard(report);
            },
          ),
        );
      },
    );

    // Wrap with adaptive navigation only if it's the main screen (not student-specific)
    if (isMainScreen) {
      return AdaptiveNavigationScaffold(
        currentRoute: AppConstants.conductRoute,
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

  Widget _buildReportCard(ConductReport report) {
    final conductProvider = context.read<ConductProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReportDetails(context, report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    conductProvider.getReportIcon(report),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.type.displayName,
                          style: TextStyle(
                            color: conductProvider.getReportColor(report),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (report.severity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: conductProvider
                            .getReportColor(report)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.severityDisplayName,
                        style: TextStyle(
                          color: conductProvider.getReportColor(report),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.description,
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
                    DateFormat('dd/MM/yyyy').format(report.incidentDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (report.reporterName != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.reporterName!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (report.attachments.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.attach_file, size: 14, color: Colors.grey[600]),
                    Text(
                      '${report.attachments.length}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  void _showReportDetails(BuildContext context, ConductReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final provider = context.read<ConductProvider>();
          final color = provider.getReportColor(report);
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Text(
                            provider.getReportIcon(report),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  report.type.displayName,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: theme.colorScheme.onSurface,
                            ),
                            onSelected: (value) {
                              Navigator.pop(context);
                              if (value == 'edit') {
                                _editReport(context, report);
                              } else if (value == 'delete') {
                                _confirmDeleteReport(context, report);
                              } else if (value == 'pdf') {
                                _generateReportPDF(context, report);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'pdf',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf, size: 20),
                                    SizedBox(width: 8),
                                    Text('Generar PDF'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (report.studentName != null)
                        _buildDetailSection(
                          'Estudiante',
                          report.studentName!,
                          Icons.school,
                        ),
                      _buildDetailSection(
                        'Fecha del Incidente',
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(report.incidentDate),
                        Icons.calendar_today,
                      ),
                      if (report.severity != null)
                        _buildDetailSection(
                          'Gravedad',
                          report.severity!.displayName,
                          Icons.warning,
                          color: color,
                        ),
                      _buildDetailSection(
                        'Descripción',
                        report.description,
                        Icons.description,
                      ),
                      if (report.context != null)
                        _buildDetailSection(
                          'Contexto',
                          report.context!,
                          Icons.info_outline,
                        ),
                      if (report.witnesses != null &&
                          report.witnesses!.isNotEmpty)
                        _buildDetailSection(
                          'Testigos',
                          report.witnesses!,
                          Icons.people,
                        ),
                      if (report.immediateActions != null)
                        _buildDetailSection(
                          'Acciones Inmediatas',
                          report.immediateActions!,
                          Icons.flash_on,
                        ),
                      if (report.reporterName != null)
                        _buildDetailSection(
                          'Reportado por',
                          report.reporterName!,
                          Icons.person,
                        ),
                      if (report.parentSignatureUrl != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Firma del Padre/Tutor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showSignatureImage(
                            context,
                            report.parentSignatureUrl!,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _SignatureImageWidget(
                                signatureUrl: report.parentSignatureUrl!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca para ampliar',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                      if (report.parentAgreements.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Acuerdos con Padres/Tutores',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...report.parentAgreements.map(
                          (agreement) => _buildParentAgreementCard(agreement),
                        ),
                      ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color ?? defaultColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color ?? defaultColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildParentAgreementCard(ParentAgreement agreement) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark
          ? Colors.blue.withOpacity(0.15)
          : Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (agreement.guardianName != null) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    agreement.guardianName!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (agreement.guardianRelationship != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${agreement.guardianRelationship})',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              agreement.agreementDescription,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            if (agreement.specificCommitments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Compromisos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              ...agreement.specificCommitments.map(
                (commitment) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      Expanded(
                        child: Text(
                          commitment,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(agreement.agreementDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (agreement.followUpDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Seguimiento: ${DateFormat('dd/MM/yyyy').format(agreement.followUpDate!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ],
            if (agreement.signatureImageUrl != null) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.verified, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Firmado',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firma del Padre/Tutor:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showSignatureImage(
                        context,
                        agreement.signatureImageUrl!,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _SignatureImageWidget(
                          signatureUrl: agreement.signatureImageUrl!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca para ampliar',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final provider = context.read<ConductProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Reportes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tipo de Reporte'),
                subtitle: DropdownButton<ConductReportType?>(
                  isExpanded: true,
                  value: provider.selectedType,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...ConductReportType.values.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    provider.setTypeFilter(value);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Gravedad'),
                subtitle: DropdownButton<IncidentSeverity?>(
                  isExpanded: true,
                  value: provider.selectedSeverity,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...IncidentSeverity.values.map(
                      (severity) => DropdownMenuItem(
                        value: severity,
                        child: Text(severity.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    provider.setSeverityFilter(value);
                    Navigator.pop(context);
                  },
                ),
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

  void _showStatisticsDialog(BuildContext context) {
    final provider = context.read<ConductProvider>();
    final positiveCount = provider.getPositiveReports().length;
    final negativeCount = provider.getNegativeReports().length;
    final bySeverity = provider.getReportsBySeverity();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total de Reportes:', '${provider.reports.length}'),
              _buildStatRow(
                'Reportes Positivos:',
                '$positiveCount',
                color: AppColors.positive,
              ),
              _buildStatRow(
                'Reportes Negativos:',
                '$negativeCount',
                color: AppColors.severe,
              ),
              if (bySeverity.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Por Gravedad:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...bySeverity.entries.map(
                  (entry) => _buildStatRow('  ${entry.key}:', '${entry.value}'),
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

  void _navigateToAddReport(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddConductReportScreen(studentId: widget.studentId),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _editReport(BuildContext context, ConductReport report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditConductReportScreen(report: report),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _generateReportPDF(
    BuildContext context,
    ConductReport report,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Obtener el estudiante
      final studentsProvider = context.read<StudentsProvider>();
      final student = studentsProvider.students.firstWhere(
        (s) => s.id == report.studentId,
      );

      // Obtener información del reportero
      final currentUser = await DatabaseService().getCurrentUser();
      final reporterName =
          report.reporterName ??
          '${currentUser?.firstName ?? ''} ${currentUser?.lastName ?? ''}'
              .trim();

      // Generar PDF
      final pdfService = PDFReportService();
      final pdfData = await pdfService.generateConductReportPDF(
        report,
        student,
        reporterName,
      );

      if (!mounted) return;

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar opciones para compartir o guardar
      await _showPDFOptionsDialog(context, pdfData, report, student);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPDFOptionsDialog(
    BuildContext context,
    Uint8List pdfData,
    ConductReport report,
    Student student,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Generado'),
        content: const Text('¿Qué desea hacer con el PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _savePDF(context, pdfData, report, student);
            },
            child: const Text('Guardar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sharePDF(context, pdfData, report, student);
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePDF(
    BuildContext context,
    Uint8List pdfData,
    ConductReport report,
    Student student,
  ) async {
    try {
      final pdfService = PDFReportService();
      final fileName =
          'reporte_conducta_${student.enrollment}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await pdfService.savePDFToDevice(pdfData, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF guardado en: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePDF(
    BuildContext context,
    Uint8List pdfData,
    ConductReport report,
    Student student,
  ) async {
    try {
      final pdfService = PDFReportService();
      final fileName =
          'reporte_conducta_${student.enrollment}_${report.isPositive ? 'positivo' : 'negativo'}.pdf';
      await pdfService.sharePDF(pdfData, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteReport(BuildContext context, ConductReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reporte'),
        content: Text(
          '¿Está seguro de que desea eliminar el reporte "${report.title}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReport(context, report);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteReport(BuildContext context, ConductReport report) async {
    final provider = context.read<ConductProvider>();
    final success = await provider.deleteReport(report.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al eliminar el reporte',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSignatureImage(BuildContext context, String imageUrl) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Firma del Padre/Tutor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: _FullSignatureImageWidget(signatureUrl: imageUrl),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Pellizca para hacer zoom',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display signature images with signed URL support
class _SignatureImageWidget extends StatefulWidget {
  final String signatureUrl;

  const _SignatureImageWidget({required this.signatureUrl});

  @override
  State<_SignatureImageWidget> createState() => _SignatureImageWidgetState();
}

class _SignatureImageWidgetState extends State<_SignatureImageWidget> {
  final FileService _fileService = FileService();
  String? _signedUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final signedUrl = await _fileService.getSignedSignatureUrl(
        widget.signatureUrl,
      );

      setState(() {
        _signedUrl = signedUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _signedUrl == null) {
      return Container(
        height: 100,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 4),
              const Text(
                'Error al cargar firma',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _loadSignedUrl,
                child: const Text('Reintentar', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      _signedUrl!,
      height: 100,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 100,
          color: Colors.grey[200],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(height: 4),
                Text('Error al cargar imagen', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 100,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// Full-size signature image widget with signed URL support
class _FullSignatureImageWidget extends StatefulWidget {
  final String signatureUrl;

  const _FullSignatureImageWidget({required this.signatureUrl});

  @override
  State<_FullSignatureImageWidget> createState() =>
      _FullSignatureImageWidgetState();
}

class _FullSignatureImageWidgetState extends State<_FullSignatureImageWidget> {
  final FileService _fileService = FileService();
  String? _signedUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final signedUrl = await _fileService.getSignedSignatureUrl(
        widget.signatureUrl,
      );

      setState(() {
        _signedUrl = signedUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _signedUrl == null) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              const Text('Error al cargar la imagen'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadSignedUrl,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      _signedUrl!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 8),
                Text('Error al cargar la imagen'),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

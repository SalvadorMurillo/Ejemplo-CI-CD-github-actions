import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../services/final_report_service.dart';
import '../../services/student_service.dart';
import '../../widgets/adaptive_navigation.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FinalReportService _finalReportService = FinalReportService();
  final StudentService _studentService = StudentService();

  List<FinalReport> _reports = [];
  List<Student> _students = [];
  bool _isLoading = false;
  String? _selectedSchoolYear;
  String? _selectedStudentId;

  final List<String> _schoolYears = [
    '2024-2025',
    '2023-2024',
    '2022-2023',
    '2021-2022',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSchoolYear = _schoolYears.first;
    _loadReports();
    _loadStudents();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _finalReportService.getFinalReports(
        schoolYear: _selectedSchoolYear,
      );
      setState(() => _reports = reports);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar reportes: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _studentService.getAllStudents();
      setState(() => _students = students.where((s) => s.isActive).toList());
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarWidget = AppBar(title: const Text('Informes Finales'));

    final bodyWidget = _buildReportsListTab();

    return AdaptiveNavigationScaffold(
      currentRoute: AppConstants.reportsRoute,
      appBar: appBarWidget,
      body: bodyWidget,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: _buildGenerateReportTab(),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_circle),
        label: const Text('Generar Nuevo'),
      ),
    );
  }

  Widget _buildReportsListTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
              ? _buildEmptyState()
              : _buildReportsList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface, // theme-aware surface color
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSchoolYear,
              decoration: InputDecoration(
                labelText: 'Ciclo Escolar',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: _schoolYears.map((year) {
                return DropdownMenuItem(value: year, child: Text(year));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSchoolYear = value);
                _loadReports();
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay informes generados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Genera un nuevo informe desde la pestaña "Generar Nuevo"',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(FinalReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getConductClassificationColor(
            report.conductLetter.classification,
          ),
          child: Text(
            report.studentSummary.grade,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          report.studentSummary.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${report.studentSummary.grade} ${report.studentSummary.group}',
            ),
            Text('Ciclo: ${report.schoolYear}'),
            Text(
              'Conducta: ${_getConductClassificationText(report.conductLetter.classification)}',
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Ver Detalles'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'pdf_informe',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text(
                    report.pdfUrl != null && report.pdfUrl!.isNotEmpty
                        ? 'Ver PDF Informe'
                        : 'Generar PDF Informe',
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'pdf_ficha',
              child: Row(
                children: [
                  Icon(Icons.description),
                  SizedBox(width: 8),
                  Text(
                    report.fichaPedagogicaPdfUrl != null &&
                            report.fichaPedagogicaPdfUrl!.isNotEmpty
                        ? 'Ver Ficha Pedagógica'
                        : 'Generar Ficha Pedagógica',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleReportAction(value, report),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildGenerateReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.assessment, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Generar Informe Final',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona un estudiante y el ciclo escolar para generar el informe final y la ficha pedagógica.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _selectedSchoolYear,
                decoration: const InputDecoration(
                  labelText: 'Ciclo Escolar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: _schoolYears.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSchoolYear = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                decoration: const InputDecoration(
                  labelText: 'Estudiante',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _students.map((student) {
                  return DropdownMenuItem(
                    value: student.id,
                    child: Text('${student.fullName} - ${student.gradeGroup}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStudentId = value);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed:
                    _selectedStudentId != null && _selectedSchoolYear != null
                    ? _generateReport
                    : null,
                icon: const Icon(Icons.create),
                label: const Text('Generar Informe'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Contenido del Informe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'Datos Generales',
              'Información completa del estudiante',
            ),
            _buildInfoItem(
              'Historial Conductual',
              'Reportes positivos y negativos del ciclo',
            ),
            _buildInfoItem(
              'Resumen de BAP',
              'Barreras de aprendizaje y su evolución',
            ),
            _buildInfoItem(
              'Situación Médica',
              'Padecimientos activos y medicación',
            ),
            _buildInfoItem(
              'Actitudes Predominantes',
              'Actitudes observadas durante el ciclo',
            ),
            _buildInfoItem(
              'Recomendaciones',
              'Sugerencias para el siguiente ciclo',
            ),
            _buildInfoItem('Áreas de Oportunidad', 'Aspectos a trabajar'),
            _buildInfoItem('Fortalezas', 'Puntos fuertes identificados'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.description, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Ficha Pedagógica',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'La ficha pedagógica incluye información completa para el CONSEJO ESTATAL DE ORIENTACIÓN EDUCATIVA con datos médico-biológicos, socioeconómicos, psicopedagógicos y psicológicos.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_selectedStudentId == null || _selectedSchoolYear == null) return;

    setState(() => _isLoading = true);
    try {
      // Check if report already exists
      final existing = await _finalReportService.getFinalReportByStudentAndYear(
        _selectedStudentId!,
        _selectedSchoolYear!,
      );

      if (existing != null && mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Informe Existente'),
            content: const Text(
              'Ya existe un informe para este estudiante en el ciclo seleccionado. ¿Desea regenerarlo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Regenerar'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          setState(() => _isLoading = false);
          return;
        }

        // Delete existing report
        await _finalReportService.deleteFinalReport(existing.id);
      }

      // Generate new report
      await _finalReportService.generateFinalReport(
        _selectedStudentId!,
        _selectedSchoolYear!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe generado exitosamente')),
        );
        // Close the bottom sheet or dialog that opened the generator (if any)
        try {
          Navigator.pop(context);
        } catch (_) {}
        _loadReports();
        setState(() => _selectedStudentId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar informe: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleReportAction(String action, FinalReport report) async {
    switch (action) {
      case 'view':
        _viewReportDetails(report);
        break;
      case 'pdf_informe':
        await _generatePDF(report, isFichaPedagogica: false);
        break;
      case 'pdf_ficha':
        await _generatePDF(report, isFichaPedagogica: true);
        break;
      case 'delete':
        await _deleteReport(report);
        break;
    }
  }

  void _viewReportDetails(FinalReport report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            children: [
              AppBar(
                title: Text(report.studentSummary.fullName),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildReportDetailsContent(report),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDetailsContent(FinalReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSection('Información del Estudiante', [
          'CURP: ${report.studentSummary.curp}',
          'Matrícula: ${report.studentSummary.enrollment}',
          'Grado y Grupo: ${report.studentSummary.grade} ${report.studentSummary.group}',
          'Ciclo Escolar: ${report.schoolYear}',
        ]),
        _buildDetailSection('Resumen Conductual', [
          'Reportes Positivos: ${report.conductualSummary.totalPositiveReports}',
          'Reportes Negativos: ${report.conductualSummary.totalNegativeReports}',
          'Clasificación: ${_getConductClassificationText(report.conductLetter.classification)}',
          if (report.conductLetter.summary.isNotEmpty)
            report.conductLetter.summary,
        ]),
        if (report.bapSummary.totalActiveBAP > 0)
          _buildDetailSection('Barreras de Aprendizaje', [
            'Total de BAP Activas: ${report.bapSummary.totalActiveBAP}',
            ...report.bapSummary.evolutionSummary.map(
              (e) => '• ${e.title} (${e.type})',
            ),
          ]),
        if (report.medicalSummary.bloodType != null ||
            report.medicalSummary.activeConditions.isNotEmpty)
          _buildDetailSection('Información Médica', [
            if (report.medicalSummary.bloodType != null)
              'Tipo de Sangre: ${report.medicalSummary.bloodType}',
            if (report.medicalSummary.activeConditions.isNotEmpty)
              'Condiciones: ${report.medicalSummary.activeConditions.join(", ")}',
            if (report.medicalSummary.activeAllergies.isNotEmpty)
              'Alergias: ${report.medicalSummary.activeAllergies.join(", ")}',
          ]),
        if (report.recommendations.isNotEmpty)
          _buildDetailSection('Recomendaciones', [report.recommendations]),
        if (report.opportunities.isNotEmpty)
          _buildDetailSection('Áreas de Oportunidad', [report.opportunities]),
        if (report.strengths.isNotEmpty)
          _buildDetailSection('Fortalezas Identificadas', [report.strengths]),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePDF(
    FinalReport report, {
    required bool isFichaPedagogica,
  }) async {
    try {
      // Check if PDF already exists
      final existingPdfUrl = isFichaPedagogica
          ? report.fichaPedagogicaPdfUrl
          : report.pdfUrl;

      // If PDF exists and is not empty, just open it
      if (existingPdfUrl != null && existingPdfUrl.isNotEmpty) {
        final shouldRegenerate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Existente'),
            content: const Text(
              'Ya existe un PDF generado para este informe. ¿Qué deseas hacer?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ver PDF Existente'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Regenerar PDF'),
              ),
            ],
          ),
        );

        if (shouldRegenerate != true) {
          // Just open the existing PDF
          final uri = Uri.parse(existingPdfUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No se pudo abrir el PDF: $existingPdfUrl'),
                ),
              );
            }
          }
          return;
        }
      }

      // Generate new PDF
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String pdfUrl;
      if (isFichaPedagogica) {
        pdfUrl = await _finalReportService.generateFichaPedagogicaPDF(
          report.id,
        );
      } else {
        pdfUrl = await _finalReportService.generateFinalReportPDF(report.id);
      }

      if (mounted) {
        Navigator.pop(context);

        // Open PDF in browser/viewer
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF ${isFichaPedagogica ? "de Ficha Pedagógica" : "de Informe"} generado exitosamente',
              ),
              action: SnackBarAction(
                label: 'Ver nuevamente',
                onPressed: () async {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ),
          );

          // Reload reports to update the UI
          _loadReports();
        } else {
          // If can't launch, show URL in snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF generado. URL: $pdfUrl'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
    }
  }

  Future<void> _deleteReport(FinalReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Está seguro de eliminar el informe de ${report.studentSummary.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _finalReportService.deleteFinalReport(report.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informe eliminado exitosamente')),
          );
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar informe: $e')),
          );
        }
      }
    }
  }

  Color _getConductClassificationColor(String classification) {
    switch (classification) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'needs_attention':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getConductClassificationText(String classification) {
    switch (classification) {
      case 'excellent':
        return 'Excelente';
      case 'good':
        return 'Buena';
      case 'regular':
        return 'Regular';
      case 'needs_attention':
        return 'Requiere Atención';
      default:
        return 'Sin Clasificar';
    }
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../providers/conduct_provider.dart';
import '../../providers/students_provider.dart';
import '../../models/models.dart';
import '../../core/constants.dart';
import '../../config/theme.dart';
import '../../services/file_service.dart';
import '../../services/database_service.dart';
import '../../services/pdf_report_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/conduct_report.dart';

class AddConductReportScreen extends StatefulWidget {
  final String? studentId;

  const AddConductReportScreen({super.key, this.studentId});

  @override
  State<AddConductReportScreen> createState() => _AddConductReportScreenState();
}

class _AddConductReportScreenState extends State<AddConductReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final FileService _fileService = FileService();
  final Uuid _uuid = const Uuid();

  // Form fields
  String? _selectedStudentId;
  ConductReportType _reportType = ConductReportType.negative;
  IncidentSeverity? _severity = IncidentSeverity.mild;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contextController = TextEditingController();
  final _witnessesController = TextEditingController();
  final _immediateActionsController = TextEditingController();
  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();

  // Parent Agreement fields
  bool _hasParentAgreement = false;
  final _agreementDescriptionController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianRelationshipController = TextEditingController();
  final _commitmentsController = TextEditingController();
  final _agreementNotesController = TextEditingController();
  DateTime _agreementDate = DateTime.now();
  DateTime? _followUpDate;
  XFile? _signatureImage;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.studentId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedStudentId == null) {
        context.read<StudentsProvider>().loadStudents(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contextController.dispose();
    _witnessesController.dispose();
    _immediateActionsController.dispose();
    _agreementDescriptionController.dispose();
    _guardianNameController.dispose();
    _guardianRelationshipController.dispose();
    _commitmentsController.dispose();
    _agreementNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte de Conducta'),
        actions: [
          if (_isSubmitting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildReportTypeSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildIncidentDetailsSection(),
            const SizedBox(height: 24),
            _buildAdditionalInfoSection(),
            const SizedBox(height: 24),
            _buildParentAgreementSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Reporte',
              style: AppTextStyles.headline4.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    ConductReportType.positive,
                    '🟢 Positivo',
                    AppColors.positive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    ConductReportType.negative,
                    '🔴 Negativo',
                    AppColors.severe,
                  ),
                ),
              ],
            ),
            if (_reportType == ConductReportType.negative) ...[
              const SizedBox(height: 16),
              Text(
                'Nivel de Gravedad',
                style: AppTextStyles.headline6.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildSeverityDropdown(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(ConductReportType type, String label, Color color) {
    final isSelected = _reportType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _reportType = type;
          if (type == ConductReportType.positive) {
            _severity = null;
          } else {
            _severity ??= IncidentSeverity.mild;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : (isDark ? AppColors.surfaceDark : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? color
                  : (isDark ? AppColors.textPrimaryDark : Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityDropdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<IncidentSeverity>(
      initialValue: _severity,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: IncidentSeverity.values
          .map(
            (severity) => DropdownMenuItem(
              value: severity,
              child: Row(
                children: [
                  Text(_getSeverityIcon(severity)),
                  const SizedBox(width: 8),
                  Text(severity.displayName),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _severity = value),
      validator: (value) {
        if (_reportType == ConductReportType.negative && value == null) {
          return 'Seleccione un nivel de gravedad';
        }
        return null;
      },
    );
  }

  String _getSeverityIcon(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.mild:
        return '🟡';
      case IncidentSeverity.moderate:
        return '🟠';
      case IncidentSeverity.severe:
        return '🔴';
      case IncidentSeverity.verySevere:
        return '⚫';
    }
  }

  Widget _buildBasicInfoSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: AppTextStyles.headline4.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.studentId == null) _buildStudentSelector(),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _titleController,
              label: 'Título del Reporte',
              hintText: 'Ej: Excelente participación en clase',
              prefixIcon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Descripción Detallada',
              hintText: 'Describa el incidente o comportamiento...',
              prefixIcon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese una descripción';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<StudentsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedStudentId,
          decoration: InputDecoration(
            labelText: 'Estudiante',
            prefixIcon: const Icon(Icons.person),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: provider.students
              .map(
                (student) => DropdownMenuItem(
                  value: student.id,
                  child: Text('${student.firstName} ${student.lastName}'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedStudentId = value),
          validator: (value) {
            if (value == null) {
              return 'Seleccione un estudiante';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildIncidentDetailsSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles del Incidente',
              style: AppTextStyles.headline4.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha del Incidente'),
              subtitle: Text(
                '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Hora del Incidente'),
              subtitle: Text(_incidentTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _contextController,
              label: 'Contexto (Opcional)',
              hintText: 'Describa el contexto en el que ocurrió...',
              prefixIcon: Icons.info_outline,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: AppTextStyles.headline4.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _witnessesController,
              label: 'Testigos (Opcional)',
              hintText: 'Nombres separados por comas',
              prefixIcon: Icons.people,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _immediateActionsController,
              label: 'Acciones Inmediatas Tomadas (Opcional)',
              hintText: 'Describa las acciones tomadas...',
              prefixIcon: Icons.flash_on,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentAgreementSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Acuerdo con Padres/Tutores',
                    style: AppTextStyles.headline4.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: _hasParentAgreement,
                  onChanged: (value) =>
                      setState(() => _hasParentAgreement = value),
                ),
              ],
            ),
            if (_hasParentAgreement) ...[
              const SizedBox(height: 16),
              CustomTextField(
                controller: _guardianNameController,
                label: 'Nombre del Padre/Tutor',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (_hasParentAgreement && (value == null || value.isEmpty)) {
                    return 'Ingrese el nombre del tutor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _guardianRelationshipController,
                label: 'Parentesco',
                hintText: 'Ej: Madre, Padre, Tutor legal',
                prefixIcon: Icons.family_restroom,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _agreementDescriptionController,
                label: 'Descripción del Acuerdo',
                hintText: 'Describa el acuerdo establecido...',
                prefixIcon: Icons.handshake,
                maxLines: 4,
                validator: (value) {
                  if (_hasParentAgreement && (value == null || value.isEmpty)) {
                    return 'Ingrese la descripción del acuerdo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _commitmentsController,
                label: 'Compromisos Específicos (Opcional)',
                hintText: 'Compromisos separados por comas',
                prefixIcon: Icons.check_circle_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _agreementNotesController,
                label: 'Notas Adicionales (Opcional)',
                prefixIcon: Icons.note,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Fecha del Acuerdo'),
                subtitle: Text(
                  '${_agreementDate.day}/${_agreementDate.month}/${_agreementDate.year}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectAgreementDate(context),
              ),
              ListTile(
                leading: Icon(Icons.event, color: AppColors.warning),
                title: const Text('Fecha de Seguimiento (Opcional)'),
                subtitle: Text(
                  _followUpDate != null
                      ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                      : 'No establecida',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_followUpDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _followUpDate = null),
                      ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () => _selectFollowUpDate(context),
              ),
              const SizedBox(height: 16),
              _buildSignatureSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Firma del Padre/Tutor',
          style: AppTextStyles.headline6.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (_signatureImage != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                const Expanded(child: Text('Firma capturada')),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => setState(() => _signatureImage = null),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _captureSignatureFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar Foto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickSignatureFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
        child: _isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                'Crear Reporte',
                style: AppTextStyles.button.copyWith(fontSize: 16),
              ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime,
    );
    if (picked != null) {
      setState(() => _incidentTime = picked);
    }
  }

  Future<void> _selectAgreementDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _agreementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _agreementDate = picked);
    }
  }

  Future<void> _selectFollowUpDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _followUpDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  Future<void> _captureSignatureFromCamera() async {
    final XFile? image = await _fileService.pickImageFromCamera();
    if (image != null) {
      setState(() => _signatureImage = image);
    }
  }

  Future<void> _pickSignatureFromGallery() async {
    final XFile? image = await _fileService.pickImageFromGallery();
    if (image != null) {
      setState(() => _signatureImage = image);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStudentId == null) {
      _showErrorDialog('Debe seleccionar un estudiante');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = await DatabaseService().getCurrentUser();
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Combine date and time
      final incidentDateTime = DateTime(
        _incidentDate.year,
        _incidentDate.month,
        _incidentDate.day,
        _incidentTime.hour,
        _incidentTime.minute,
      );

      // Upload signature if exists
      String? signatureUrl;
      if (_signatureImage != null) {
        signatureUrl = await _fileService.uploadSignatureImage(
          _signatureImage!,
          _uuid.v4(),
        );
      }

      // Parse witnesses
      final witnessesText = _witnessesController.text.trim();

      // Create parent agreement data if needed
      String? parentAgreementText;
      DateTime? agreementDateTime;
      if (_hasParentAgreement &&
          _agreementDescriptionController.text.isNotEmpty) {
        parentAgreementText = _agreementDescriptionController.text.trim();
        agreementDateTime = _agreementDate;
      }

      // Create the report with proper field names
      final report = ConductReport(
        id: _uuid.v4(),
        studentId: _selectedStudentId!,
        reporterId: currentUser.id,
        type: _reportType,
        severity: _severity,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        incidentDate: incidentDateTime,
        context: _contextController.text.trim().isEmpty
            ? null
            : _contextController.text.trim(),
        witnesses: witnessesText.isEmpty ? null : witnessesText,
        immediateActions: _immediateActionsController.text.trim().isEmpty
            ? null
            : _immediateActionsController.text.trim(),
        attachments: [], // Empty for now, can be extended later
        parentAgreement: parentAgreementText,
        parentSignatureUrl: signatureUrl,
        agreementDate: agreementDateTime,
        followUpDate: _followUpDate,
        createdAt: DateTime.now(),
      );

      final conductProvider = context.read<ConductProvider>();
      final success = await conductProvider.createReport(report);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Preguntar si desea generar PDF
        final shouldGeneratePDF = await _showPDFGenerationDialog();
        if (shouldGeneratePDF == true && mounted) {
          await _generateAndSharePDF(report, currentUser);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorDialog(
          conductProvider.errorMessage ?? 'Error al crear el reporte',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool?> _showPDFGenerationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar PDF'),
        content: const Text(
          '¿Desea generar y descargar el PDF del reporte de conducta con espacios para firmas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, generar PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePDF(
    ConductReport report,
    User currentUser,
  ) async {
    try {
      // Mostrar indicador de carga
      if (mounted) {
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
      }

      // Obtener el estudiante
      final studentsProvider = context.read<StudentsProvider>();
      final student = studentsProvider.students.firstWhere(
        (s) => s.id == report.studentId,
      );

      // Generar PDF
      final pdfService = PDFReportService();
      final pdfData = await pdfService.generateConductReportPDF(
        report,
        student,
        '${currentUser.firstName} ${currentUser.lastName}',
      );

      if (!mounted) return;

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar opciones para compartir o guardar
      await _showPDFOptionsDialog(pdfData, report, student);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        _showErrorDialog('Error al generar PDF: $e');
      }
    }
  }

  Future<void> _showPDFOptionsDialog(
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
              await _savePDF(pdfData, report, student);
            },
            child: const Text('Guardar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sharePDF(pdfData, report, student);
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePDF(
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
        _showErrorDialog('Error al guardar PDF: $e');
      }
    }
  }

  Future<void> _sharePDF(
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
        _showErrorDialog('Error al compartir PDF: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

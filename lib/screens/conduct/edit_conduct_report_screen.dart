import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/conduct_provider.dart';
import '../../models/models.dart';
import '../../core/constants.dart';
import '../../config/theme.dart';
import '../../services/file_service.dart';
import '../../widgets/custom_text_field.dart';

class EditConductReportScreen extends StatefulWidget {
  final ConductReport report;

  const EditConductReportScreen({super.key, required this.report});

  @override
  State<EditConductReportScreen> createState() =>
      _EditConductReportScreenState();
}

class _EditConductReportScreenState extends State<EditConductReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final FileService _fileService = FileService();

  // Form fields
  late ConductReportType _reportType;
  late IncidentSeverity? _severity;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _contextController;
  late TextEditingController _witnessesController;
  late TextEditingController _immediateActionsController;
  late DateTime _incidentDate;
  late TimeOfDay _incidentTime;

  bool _isSubmitting = false;
  String? _currentSignatureUrl;
  XFile? _newSignatureImage;

  @override
  void initState() {
    super.initState();
    _reportType = widget.report.type;
    _severity = widget.report.severity;
    _titleController = TextEditingController(text: widget.report.title);
    _descriptionController = TextEditingController(
      text: widget.report.description,
    );
    _contextController = TextEditingController(text: widget.report.context);
    _witnessesController = TextEditingController(text: widget.report.witnesses);
    _immediateActionsController = TextEditingController(
      text: widget.report.immediateActions,
    );
    _incidentDate = widget.report.incidentDate;
    _incidentTime = TimeOfDay.fromDateTime(widget.report.incidentDate);
    _currentSignatureUrl = widget.report.parentSignatureUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contextController.dispose();
    _witnessesController.dispose();
    _immediateActionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Reporte de Conducta'),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            const SizedBox(height: 16),
            if (_reportType == ConductReportType.negative) ...[
              _buildSeverityDropdown(),
              const SizedBox(height: 16),
            ],
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            _buildIncidentDetailsSection(),
            const SizedBox(height: 16),
            _buildAdditionalInfoSection(),
            const SizedBox(height: 16),
            _buildSignatureSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Reporte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    ConductReportType.positive,
                    'Positivo',
                    AppColors.positive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    ConductReportType.negative,
                    'Negativo',
                    AppColors.severe,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(ConductReportType type, String label, Color color) {
    final isSelected = _reportType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _reportType = type;
          if (type == ConductReportType.positive) {
            _severity = null;
          } else
            _severity ??= IncidentSeverity.mild;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityDropdown() {
    return DropdownButtonFormField<IncidentSeverity>(
      initialValue: _severity,
      decoration: InputDecoration(
        labelText: 'Gravedad del Incidente',
        filled: true,
        fillColor: Colors.grey[50],
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
          return 'Debe seleccionar la gravedad';
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _titleController,
              label: 'Título del Reporte',
              hintText: 'Ej: Conducta destacada en clase',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El título es requerido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Incidente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hintText: 'Describa detalladamente lo ocurrido',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha del Incidente'),
              subtitle: Text(
                '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
              ),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Hora del Incidente'),
              subtitle: Text(_incidentTime.format(context)),
              onTap: () => _selectTime(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Adicional',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _contextController,
              label: 'Contexto (opcional)',
              hintText: 'Contexto donde ocurrió',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _witnessesController,
              label: 'Testigos (opcional)',
              hintText: 'Nombres de testigos separados por comas',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _immediateActionsController,
              label: 'Acciones Inmediatas (opcional)',
              hintText: 'Acciones tomadas inmediatamente',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firma del Padre/Tutor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_newSignatureImage != null) ...[
              const Text('Nueva firma capturada:'),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: FutureBuilder<List<int>>(
                        future: _newSignatureImage!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              Uint8List.fromList(snapshot.data!),
                              fit: BoxFit.contain,
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() => _newSignatureImage = null);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_currentSignatureUrl != null) ...[
              const Text('Firma actual:'),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: FutureBuilder<String?>(
                        future: _fileService.getSignedSignatureUrl(
                          _currentSignatureUrl!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Center(
                              child: Text('Error al cargar firma'),
                            );
                          }
                          return Image.network(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Error al cargar firma'),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() => _currentSignatureUrl = null);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text('No hay firma adjunta'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureSignatureFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickSignatureFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Actualizar Reporte', style: TextStyle(fontSize: 16)),
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

  Future<void> _captureSignatureFromCamera() async {
    final XFile? image = await _fileService.pickImageFromCamera();
    if (image != null) {
      setState(() => _newSignatureImage = image);
    }
  }

  Future<void> _pickSignatureFromGallery() async {
    final XFile? image = await _fileService.pickImageFromGallery();
    if (image != null) {
      setState(() => _newSignatureImage = image);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Combine date and time
      final incidentDateTime = DateTime(
        _incidentDate.year,
        _incidentDate.month,
        _incidentDate.day,
        _incidentTime.hour,
        _incidentTime.minute,
      );

      // Upload new signature if exists
      String? signatureUrl = _currentSignatureUrl;
      if (_newSignatureImage != null) {
        signatureUrl = await _fileService.uploadSignatureImage(
          _newSignatureImage!,
          widget.report.id,
        );
      }

      // Create updated report
      final updatedReport = widget.report.copyWith(
        type: _reportType,
        severity: _severity,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        incidentDate: incidentDateTime,
        context: _contextController.text.trim().isEmpty
            ? null
            : _contextController.text.trim(),
        witnesses: _witnessesController.text.trim().isEmpty
            ? null
            : _witnessesController.text.trim(),
        immediateActions: _immediateActionsController.text.trim().isEmpty
            ? null
            : _immediateActionsController.text.trim(),
        parentSignatureUrl: signatureUrl,
        updatedAt: DateTime.now(),
      );

      final conductProvider = context.read<ConductProvider>();
      final success = await conductProvider.updateReport(updatedReport);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(
          conductProvider.errorMessage ?? 'Error al actualizar el reporte',
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

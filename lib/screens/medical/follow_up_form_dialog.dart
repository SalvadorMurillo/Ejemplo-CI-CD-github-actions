import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../providers/medical_provider.dart';
import '../../services/file_service.dart';
import '../../core/constants.dart';

class FollowUpFormDialog extends StatefulWidget {
  final String medicalRecordId;

  const FollowUpFormDialog({super.key, required this.medicalRecordId});

  @override
  State<FollowUpFormDialog> createState() => _FollowUpFormDialogState();
}

class _FollowUpFormDialogState extends State<FollowUpFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final FileService _fileService = FileService();
  static const Uuid _uuid = Uuid();

  final TextEditingController _consultationTypeController =
      TextEditingController();
  final TextEditingController _physicianController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _evolutionController = TextEditingController();
  final TextEditingController _schoolObservationsController =
      TextEditingController();
  DateTime _followUpDate = DateTime.now();

  final List<PlatformFile> _selectedFiles = [];
  bool _isUploadingFiles = false;

  @override
  void dispose() {
    _consultationTypeController.dispose();
    _physicianController.dispose();
    _observationsController.dispose();
    _evolutionController.dispose();
    _schoolObservationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      'Nuevo Seguimiento',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha del Seguimiento *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_followUpDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consultationTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Consulta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                    hintText: 'Ej: Consulta de rutina, Control',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _physicianController,
                  decoration: const InputDecoration(
                    labelText: 'Médico Tratante',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Dr. Juan Pérez',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observationsController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones Médicas',
                    border: OutlineInputBorder(),
                    hintText: 'Observaciones del médico',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _evolutionController,
                  decoration: const InputDecoration(
                    labelText: 'Evolución',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                    hintText: 'Evolución del paciente',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _schoolObservationsController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones Escolares',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                    hintText: 'Observaciones del personal escolar',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildAttachmentsSection(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    Consumer<MedicalProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton(
                          onPressed: (provider.isLoading || _isUploadingFiles)
                              ? null
                              : _saveFollowUp,
                          child: (provider.isLoading || _isUploadingFiles)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _followUpDate = picked;
      });
    }
  }

  Future<void> _saveFollowUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<MedicalProvider>();

    // Generate a temporary follow-up ID for file uploads
    final tempFollowUpId = _uuid.v4();

    // Upload files first if any
    List<String> attachmentUrls = [];
    if (_selectedFiles.isNotEmpty) {
      setState(() {
        _isUploadingFiles = true;
      });

      try {
        attachmentUrls = await _fileService.uploadMedicalFollowUpDocuments(
          _selectedFiles,
          widget.medicalRecordId,
          tempFollowUpId,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir archivos: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isUploadingFiles = false;
        });
        return;
      }

      setState(() {
        _isUploadingFiles = false;
      });
    }

    // Save follow-up with attachment URLs
    final success = await provider.addFollowUp(
      medicalRecordId: widget.medicalRecordId,
      followUpDate: _followUpDate,
      consultationType: _consultationTypeController.text.trim().isNotEmpty
          ? _consultationTypeController.text.trim()
          : null,
      attendingPhysician: _physicianController.text.trim().isNotEmpty
          ? _physicianController.text.trim()
          : null,
      observations: _observationsController.text.trim().isNotEmpty
          ? _observationsController.text.trim()
          : null,
      evolution: _evolutionController.text.trim().isNotEmpty
          ? _evolutionController.text.trim()
          : null,
      schoolObservations: _schoolObservationsController.text.trim().isNotEmpty
          ? _schoolObservationsController.text.trim()
          : null,
      attachmentUrls: attachmentUrls,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seguimiento agregado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(
        context,
      ).pop(true); // Return true on success to trigger refresh
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos Adjuntos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _isUploadingFiles ? null : _pickFiles,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Adjuntar'),
            ),
          ],
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...(_selectedFiles.map((file) => _buildFileChip(file)).toList()),
        ],
        const SizedBox(height: 8),
        Text(
          'Formatos permitidos: PDF, imágenes (JPG, PNG)\nTamaño máximo: ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB por archivo',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFileChip(PlatformFile file) {
    final fileSize = _fileService.formatFileSize(file.size);
    final icon = _fileService.isImageFile(file.name)
        ? Icons.image
        : Icons.description;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(
          '${file.name} ($fileSize)',
          overflow: TextOverflow.ellipsis,
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() {
            _selectedFiles.remove(file);
          });
        },
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await _fileService.pickMultipleDocuments();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../providers/medical_provider.dart';
import '../../services/file_service.dart';
import '../../core/constants.dart';

class DiagnosisFormDialog extends StatefulWidget {
  final String medicalRecordId;

  const DiagnosisFormDialog({super.key, required this.medicalRecordId});

  @override
  State<DiagnosisFormDialog> createState() => _DiagnosisFormDialogState();
}

class _DiagnosisFormDialogState extends State<DiagnosisFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final FileService _fileService = FileService();
  static const Uuid _uuid = Uuid();

  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();
  DateTime _diagnosisDate = DateTime.now();

  final List<PlatformFile> _selectedFiles = [];
  bool _isUploadingFiles = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _doctorController.dispose();
    _descriptionController.dispose();
    _treatmentController.dispose();
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
                    const Icon(Icons.medical_information, color: Colors.purple),
                    const SizedBox(width: 12),
                    Text(
                      'Nuevo Diagnóstico',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_information_outlined),
                    hintText: 'Ej: Diabetes tipo 2',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El diagnóstico es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Médico Tratante',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Dr. Juan Pérez',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Diagnóstico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_diagnosisDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    hintText: 'Detalles del diagnóstico',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _treatmentController,
                  decoration: const InputDecoration(
                    labelText: 'Tratamiento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                    hintText: 'Tratamiento prescrito',
                  ),
                  maxLines: 2,
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
                              : _saveDiagnosis,
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
      initialDate: _diagnosisDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _diagnosisDate = picked;
      });
    }
  }

  Future<void> _saveDiagnosis() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<MedicalProvider>();

    // Generate a temporary diagnosis ID for file uploads
    final tempDiagnosisId = _uuid.v4();

    // Upload files first if any
    List<String> attachmentUrls = [];
    if (_selectedFiles.isNotEmpty) {
      setState(() {
        _isUploadingFiles = true;
      });

      try {
        attachmentUrls = await _fileService.uploadMedicalDiagnosisDocuments(
          _selectedFiles,
          widget.medicalRecordId,
          tempDiagnosisId,
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

    // Save diagnosis with attachment URLs
    final success = await provider.addDiagnosis(
      medicalRecordId: widget.medicalRecordId,
      diagnosis: _diagnosisController.text.trim(),
      diagnosingDoctor: _doctorController.text.trim().isNotEmpty
          ? _doctorController.text.trim()
          : null,
      diagnosisDate: _diagnosisDate,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      treatment: _treatmentController.text.trim().isNotEmpty
          ? _treatmentController.text.trim()
          : null,
      attachmentUrls: attachmentUrls,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnóstico agregado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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

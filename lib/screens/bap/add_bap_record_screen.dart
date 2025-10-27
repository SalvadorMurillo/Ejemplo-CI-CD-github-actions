import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/bap_provider.dart';
import '../../providers/students_provider.dart';
import '../../models/models.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';

class AddBAPRecordScreen extends StatefulWidget {
  final String? studentId;
  final BAPRecord? existingRecord;

  const AddBAPRecordScreen({super.key, this.studentId, this.existingRecord});

  @override
  State<AddBAPRecordScreen> createState() => _AddBAPRecordScreenState();
}

class _AddBAPRecordScreenState extends State<AddBAPRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _interventionController = TextEditingController();

  String? _selectedStudentId;
  BAPType _selectedType = BAPType.learning;
  DateTime _detectionDate = DateTime.now();
  String _currentStatus = 'active';
  bool _isLoading = false;
  final List<String> _interventionStrategies = [];

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.studentId;

    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _titleController.text = record.title;
      _descriptionController.text = record.description;
      _selectedType = record.type;
      _detectionDate = record.detectionDate;
      _currentStatus = record.currentStatus ?? 'active';
      _interventionStrategies.addAll(record.interventionStrategies);
    }

    // Load students if no student is preselected
    if (_selectedStudentId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<StudentsProvider>().loadStudents(refresh: true);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _interventionController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un estudiante')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use the existing AuthService from Provider
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser; // No need to await

      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final record = BAPRecord(
        id: widget.existingRecord?.id ?? const Uuid().v4(),
        studentId: _selectedStudentId!,
        identifiedById: currentUser.id,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        detectionDate: _detectionDate,
        interventionStrategies: _interventionStrategies,
        currentStatus: _currentStatus,
        attachmentUrls: widget.existingRecord?.attachmentUrls ?? [],
        createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<BAPProvider>();
      bool success;

      if (widget.existingRecord != null) {
        success = await provider.updateRecord(record);
      } else {
        success = await provider.createRecord(record);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRecord != null
                  ? 'Registro actualizado correctamente'
                  : 'Registro creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addIntervention() {
    final text = _interventionController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _interventionStrategies.add(text);
        _interventionController.clear();
      });
    }
  }

  void _removeIntervention(int index) {
    setState(() {
      _interventionStrategies.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingRecord != null
              ? 'Editar Registro BAP'
              : 'Nuevo Registro BAP',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Student selector (only if no student is preselected)
            if (widget.studentId == null) ...[
              const Text(
                'Estudiante',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Consumer<StudentsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedStudentId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecciona un estudiante',
                    ),
                    items: provider.students.map((student) {
                      return DropdownMenuItem(
                        value: student.id,
                        child: Text('${student.firstName} ${student.lastName}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStudentId = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Selecciona un estudiante';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Type selector
            const Text(
              'Tipo de Barrera',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BAPType.values.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  selected: isSelected,
                  label: Text(type.displayName),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Title
            CustomTextField(
              controller: _titleController,
              label: 'Título',
              hintText: 'Título breve de la barrera identificada',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Descripción Detallada',
              hintText: 'Describe la barrera identificada...',
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Detection date
            const Text(
              'Fecha de Detección',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_detectionDate.day}/${_detectionDate.month}/${_detectionDate.year}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _detectionDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _detectionDate = date);
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 24),

            // Intervention strategies
            const Text(
              'Estrategias de Intervención',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _interventionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Agrega una estrategia...',
                    ),
                    onSubmitted: (_) => _addIntervention(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addIntervention,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_interventionStrategies.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay estrategias agregadas',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...List.generate(
                _interventionStrategies.length,
                (index) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(_interventionStrategies[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeIntervention(index),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Status
            const Text(
              'Estado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currentStatus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Activo')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('En Progreso'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('Resuelto')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currentStatus = value);
                }
              },
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      widget.existingRecord != null
                          ? 'Actualizar Registro'
                          : 'Crear Registro',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/attitude_provider.dart';
import '../../providers/students_provider.dart';
import '../../models/models.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_text_field.dart';

class AddAttitudeScreen extends StatefulWidget {
  final String? studentId;

  const AddAttitudeScreen({super.key, this.studentId});

  @override
  State<AddAttitudeScreen> createState() => _AddAttitudeScreenState();
}

class _AddAttitudeScreenState extends State<AddAttitudeScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  // Form fields
  String? _selectedStudentId;
  String _attitudeType = 'positive'; // 'positive' or 'negative'
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contextController = TextEditingController();
  String? _frequency;
  final _interventionController = TextEditingController();
  DateTime _observationDate = DateTime.now();
  TimeOfDay _observationTime = TimeOfDay.now();

  bool _isSubmitting = false;

  final List<String> _frequencyOptions = [
    'Ocasional',
    'Frecuente',
    'Muy frecuente',
    'Constante',
  ];

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
    _interventionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Actitud'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
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
            _buildAttitudeTypeSection(),
            const SizedBox(height: 16),
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            _buildDetailsSection(),
            const SizedBox(height: 16),
            _buildInterventionSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttitudeTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Actitud',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    'positive',
                    'Positiva 😊',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    'negative',
                    'Negativa 😟',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, String label, Color color) {
    final isSelected = _attitudeType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _attitudeType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
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
            if (_selectedStudentId == null) ...[
              _buildStudentSelector(),
              const SizedBox(height: 16),
            ],
            CustomTextField(
              controller: _titleController,
              label: 'Título de la Actitud *',
              hintText: 'Ej: Participación activa en clase',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Descripción *',
              hintText: 'Describa la actitud observada',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese una descripción';
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
    return Consumer<StudentsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedStudentId,
          decoration: InputDecoration(
            labelText: 'Estudiante *',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: provider.students.map((student) {
            return DropdownMenuItem<String>(
              value: student.id,
              child: Text('${student.firstName} ${student.lastName}'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedStudentId = value),
          validator: (value) =>
              value == null ? 'Por favor seleccione un estudiante' : null,
        );
      },
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de la Observación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _contextController,
              label: 'Contexto',
              hintText: 'Ej: Durante la clase de matemáticas',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: InputDecoration(
                labelText: 'Frecuencia de Aparición',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _frequencyOptions.map((freq) {
                return DropdownMenuItem<String>(value: freq, child: Text(freq));
              }).toList(),
              onChanged: (value) => setState(() => _frequency = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Fecha de Observación'),
              subtitle: Text(
                '${_observationDate.day}/${_observationDate.month}/${_observationDate.year}',
              ),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Hora de Observación'),
              subtitle: Text(_observationTime.format(context)),
              leading: const Icon(Icons.access_time),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectTime(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Intervención',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _interventionController,
              label: 'Estrategia de Intervención Aplicada',
              hintText: _attitudeType == 'positive'
                  ? 'Ej: Se le felicitó públicamente'
                  : 'Ej: Se aplicó diálogo reflexivo',
              maxLines: 3,
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
        onPressed: _isSubmitting ? null : _submitAttitude,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Guardar Registro de Actitud'),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _observationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _observationDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _observationTime,
    );
    if (picked != null) {
      setState(() => _observationTime = picked);
    }
  }

  Future<void> _submitAttitude() async {
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
      final observationDateTime = DateTime(
        _observationDate.year,
        _observationDate.month,
        _observationDate.day,
        _observationTime.hour,
        _observationTime.minute,
      );

      // Create the attitude record
      final attitude = AttitudeRecord(
        id: _uuid.v4(),
        studentId: _selectedStudentId!,
        observedBy: currentUser.id,
        attitudeType: _attitudeType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        context: _contextController.text.trim().isEmpty
            ? null
            : _contextController.text.trim(),
        observationDate: observationDateTime,
        frequency: _frequency,
        interventionApplied: _interventionController.text.trim().isEmpty
            ? null
            : _interventionController.text.trim(),
        createdAt: DateTime.now(),
      );

      final attitudeProvider = context.read<AttitudeProvider>();
      final success = await attitudeProvider.createAttitude(attitude);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro de actitud creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(
          'No se pudo crear el registro. Por favor intente nuevamente.',
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart' as models;
import '../../providers/medical_provider.dart';
import '../../core/constants.dart';

class MedicalRecordFormScreen extends StatefulWidget {
  final String? studentId;
  final models.MedicalRecord? existingRecord;

  const MedicalRecordFormScreen({
    super.key,
    this.studentId,
    this.existingRecord,
  });

  @override
  State<MedicalRecordFormScreen> createState() =>
      _MedicalRecordFormScreenState();
}

class _MedicalRecordFormScreenState extends State<MedicalRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  static const Uuid _uuid = Uuid();

  BloodType? _selectedBloodType;
  final List<String> _knownAllergies = [];
  final List<String> _chronicConditions = [];
  final List<String> _currentMedications = [];
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _insuranceInfoController =
      TextEditingController();

  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    }
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _selectedBloodType = record.bloodType;
    _knownAllergies.addAll(record.knownAllergies);
    _chronicConditions.addAll(record.chronicConditions);
    _currentMedications.addAll(record.currentMedications);
    _emergencyContactController.text = record.emergencyContact ?? '';
    _emergencyPhoneController.text = record.emergencyPhone ?? '';
    _insuranceInfoController.text = record.insuranceInfo ?? '';
  }

  @override
  void dispose() {
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _insuranceInfoController.dispose();
    _allergyController.dispose();
    _conditionController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color.fromARGB(255, 158, 102, 29),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingRecord != null
                ? 'Editar Expediente Médico'
                : 'Nuevo Expediente Médico',
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGeneralInfoSection(),
              const SizedBox(height: 24),
              _buildAllergiesSection(),
              const SizedBox(height: 24),
              _buildChronicConditionsSection(),
              const SizedBox(height: 24),
              _buildMedicationsSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BloodType>(
              initialValue: _selectedBloodType,
              decoration: const InputDecoration(
                labelText: 'Tipo Sanguíneo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bloodtype),
              ),
              items: BloodType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBloodType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Contacto de Emergencia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono de Emergencia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _insuranceInfoController,
              decoration: const InputDecoration(
                labelText: 'Información del Seguro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Alergias Conocidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _allergyController,
                    decoration: const InputDecoration(
                      hintText: 'Agregar alergia',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addAllergy,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildItemsList(_knownAllergies, _removeAllergy, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildChronicConditionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.healing, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Condiciones Médicas Crónicas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _conditionController,
                    decoration: const InputDecoration(
                      hintText: 'Agregar condición',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCondition,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildItemsList(_chronicConditions, _removeCondition, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Medicamentos Actuales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _medicationController,
                    decoration: const InputDecoration(
                      hintText: 'Agregar medicamento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildItemsList(
              _currentMedications,
              _removeMedication,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    List<String> items,
    Function(int) onRemove,
    Color color,
  ) {
    if (items.isEmpty) {
      return Text(
        'No hay items agregados',
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        return Chip(
          label: Text(entry.value),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => onRemove(entry.key),
          backgroundColor: color.withOpacity(0.1),
          deleteIconColor: color,
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<MedicalProvider>(
      builder: (context, provider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _saveRecord,
            child: provider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.existingRecord != null
                        ? 'Actualizar Expediente'
                        : 'Crear Expediente',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        );
      },
    );
  }

  void _addAllergy() {
    if (_allergyController.text.trim().isNotEmpty) {
      setState(() {
        _knownAllergies.add(_allergyController.text.trim());
        _allergyController.clear();
      });
    }
  }

  void _removeAllergy(int index) {
    setState(() {
      _knownAllergies.removeAt(index);
    });
  }

  void _addCondition() {
    if (_conditionController.text.trim().isNotEmpty) {
      setState(() {
        _chronicConditions.add(_conditionController.text.trim());
        _conditionController.clear();
      });
    }
  }

  void _removeCondition(int index) {
    setState(() {
      _chronicConditions.removeAt(index);
    });
  }

  void _addMedication() {
    if (_medicationController.text.trim().isNotEmpty) {
      setState(() {
        _currentMedications.add(_medicationController.text.trim());
        _medicationController.clear();
      });
    }
  }

  void _removeMedication(int index) {
    setState(() {
      _currentMedications.removeAt(index);
    });
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.studentId == null && widget.existingRecord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se especificó el estudiante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<MedicalProvider>();

    final record = models.MedicalRecord(
      id: widget.existingRecord?.id ?? _uuid.v4(),
      studentId: widget.studentId ?? widget.existingRecord!.studentId,
      bloodType: _selectedBloodType,
      knownAllergies: _knownAllergies,
      chronicConditions: _chronicConditions,
      currentMedications: _currentMedications,
      emergencyContact: _emergencyContactController.text.trim().isNotEmpty
          ? _emergencyContactController.text.trim()
          : null,
      emergencyPhone: _emergencyPhoneController.text.trim().isNotEmpty
          ? _emergencyPhoneController.text.trim()
          : null,
      insuranceInfo: _insuranceInfoController.text.trim().isNotEmpty
          ? _insuranceInfoController.text.trim()
          : null,
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      diagnoses: widget.existingRecord?.diagnoses ?? [],
      followUps: widget.existingRecord?.followUps ?? [],
    );

    bool success;
    if (widget.existingRecord != null) {
      success = await provider.updateMedicalRecord(record);
    } else {
      success = await provider.createMedicalRecord(record);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingRecord != null
                ? 'Expediente actualizado correctamente'
                : 'Expediente creado correctamente',
          ),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart' as models;
import '../../providers/medical_provider.dart';
import '../../config/theme.dart';
import '../../core/constants.dart';
import 'diagnosis_form_dialog.dart';
import 'follow_up_form_dialog.dart';
import '../../services/file_service.dart';

class MedicalRecordDetailScreen extends StatefulWidget {
  final models.MedicalRecord record;
  final models.Student? student;

  const MedicalRecordDetailScreen({
    super.key,
    required this.record,
    this.student,
  });

  @override
  State<MedicalRecordDetailScreen> createState() =>
      _MedicalRecordDetailScreenState();
}

class _MedicalRecordDetailScreenState extends State<MedicalRecordDetailScreen> {
  late models.MedicalRecord _currentRecord;
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.record;
    // Listen to changes in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRecord();
    });
  }

  Future<void> _refreshRecord() async {
    final provider = context.read<MedicalProvider>();
    if (provider.selectedRecord != null &&
        provider.selectedRecord!.id == _currentRecord.id) {
      setState(() {
        _currentRecord = provider.selectedRecord!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicalProvider>(
      builder: (context, provider, child) {
        // Update current record if it changed in provider
        if (provider.selectedRecord != null &&
            provider.selectedRecord!.id == _currentRecord.id) {
          _currentRecord = provider.selectedRecord!;
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.student != null
                    ? '${widget.student!.firstName} ${widget.student!.lastName}'
                    : 'Expediente Médico',
              ),
              elevation: 0,
              bottom: const TabBar(
                isScrollable: true,
                indicatorColor: Color.fromARGB(255, 158, 102, 29),
                labelColor: Color.fromARGB(255, 158, 102, 29),
                tabs: [
                  Tab(text: 'General', icon: Icon(Icons.info_outline)),
                  Tab(
                    text: 'Diagnósticos',
                    icon: Icon(Icons.medical_information),
                  ),
                  Tab(text: 'Seguimientos', icon: Icon(Icons.calendar_today)),
                  Tab(text: 'Documentos', icon: Icon(Icons.attach_file)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildGeneralTab(context),
                _buildDiagnosisTab(context),
                _buildFollowUpTab(context),
                _buildDocumentsTab(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            'Información Médica General',
            Icons.health_and_safety,
            [
              if (_currentRecord.bloodType != null)
                _buildInfoRow(
                  'Tipo Sanguíneo',
                  _currentRecord.bloodType!.displayName,
                ),
              if (_currentRecord.emergencyContact != null)
                _buildInfoRow(
                  'Contacto de Emergencia',
                  _currentRecord.emergencyContact!,
                ),
              if (_currentRecord.emergencyPhone != null)
                _buildInfoRow(
                  'Teléfono de Emergencia',
                  _currentRecord.emergencyPhone!,
                ),
              if (_currentRecord.insuranceInfo != null)
                _buildInfoRow('Seguro Médico', _currentRecord.insuranceInfo!),
            ],
          ),
          const SizedBox(height: 16),
          _buildListCard(
            context,
            'Alergias Conocidas',
            Icons.warning_amber,
            _currentRecord.knownAllergies,
            Colors.orange,
            'Sin alergias registradas',
          ),
          const SizedBox(height: 16),
          _buildListCard(
            context,
            'Condiciones Médicas Crónicas',
            Icons.healing,
            _currentRecord.chronicConditions,
            Colors.blue,
            'Sin condiciones crónicas',
          ),
          const SizedBox(height: 16),
          _buildListCard(
            context,
            'Medicamentos Actuales',
            Icons.medication,
            _currentRecord.currentMedications,
            Colors.green,
            'Sin medicamentos actuales',
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTab(BuildContext context) {
    final diagnoses = _currentRecord.diagnoses;
    final activeDiagnoses = diagnoses.where((d) => d.isActive).toList();
    final inactiveDiagnoses = diagnoses.where((d) => !d.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diagnósticos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDiagnosisDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activeDiagnoses.isNotEmpty) ...[
            Text(
              'Activos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.green[700]),
            ),
            const SizedBox(height: 8),
            ...activeDiagnoses.map((d) => _buildDiagnosisCard(context, d)),
            const SizedBox(height: 16),
          ],
          if (inactiveDiagnoses.isNotEmpty) ...[
            Text(
              'Inactivos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ...inactiveDiagnoses.map((d) => _buildDiagnosisCard(context, d)),
          ],
          if (diagnoses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay diagnósticos registrados',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowUpTab(BuildContext context) {
    final followUps = [..._currentRecord.followUps];
    followUps.sort((a, b) => b.followUpDate.compareTo(a.followUpDate));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seguimientos Médicos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddFollowUpDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: followUps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay seguimientos registrados',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: followUps.length,
                  itemBuilder: (context, index) {
                    return _buildFollowUpCard(context, followUps[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    final allDocuments = <String, List<String>>{};

    // Recopilar documentos de diagnósticos
    for (final diagnosis in _currentRecord.diagnoses) {
      if (diagnosis.attachmentUrls.isNotEmpty) {
        allDocuments['Diagnóstico: ${diagnosis.diagnosis}'] =
            diagnosis.attachmentUrls;
      }
    }

    // Recopilar documentos de seguimientos
    for (final followUp in _currentRecord.followUps) {
      if (followUp.attachmentUrls.isNotEmpty) {
        final date = DateFormat('dd/MM/yyyy').format(followUp.followUpDate);
        allDocuments['Seguimiento: $date'] = followUp.attachmentUrls;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Documentos Médicos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allDocuments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay documentos adjuntos',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...allDocuments.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const Icon(Icons.folder, color: AppColors.primary),
                  title: Text(entry.key),
                  subtitle: Text('${entry.value.length} documento(s)'),
                  children: entry.value.map((url) {
                    final fileName = url.split('/').last;
                    return ListTile(
                      leading: Icon(
                        _getFileIcon(fileName),
                        color: Colors.grey[600],
                      ),
                      title: Text(fileName),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _openDocument(url),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
    Color color,
    String emptyMessage,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 8, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard(
    BuildContext context,
    models.MedicalDiagnosis diagnosis,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              diagnosis.diagnosis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: diagnosis.isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              diagnosis.isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: diagnosis.isActive
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy').format(diagnosis.diagnosisDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (diagnosis.diagnosingDoctor != null) ...[
              const SizedBox(height: 8),
              Text(
                'Médico: ${diagnosis.diagnosingDoctor}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (diagnosis.description != null) ...[
              const SizedBox(height: 8),
              Text(
                diagnosis.description!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            if (diagnosis.treatment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        diagnosis.treatment!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (diagnosis.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${diagnosis.attachmentUrls.length} documento(s) adjunto(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(
    BuildContext context,
    models.MedicalFollowUp followUp,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final primaryColor = isDark ? AppColors.accentTeal : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.event, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(followUp.followUpDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (followUp.consultationType != null)
                        Text(
                          followUp.consultationType!,
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (followUp.attendingPhysician != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    followUp.attendingPhysician!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (followUp.observations != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observaciones:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      followUp.observations!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            if (followUp.evolution != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.positive.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.positive.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: isDark
                              ? AppColors.positive.withOpacity(0.9)
                              : AppColors.positive,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Evolución:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      followUp.evolution!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            if (followUp.schoolObservations != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 16,
                          color: isDark
                              ? AppColors.info.withOpacity(0.9)
                              : AppColors.info,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Observaciones Escolares:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      followUp.schoolObservations!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            if (followUp.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${followUp.attachmentUrls.length} documento(s) adjunto(s)',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openDocument(String url) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Abriendo documento...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get signed URL for secure access
      final signedUrl = await _fileService.getSignedUrl(url);

      if (signedUrl == null) {
        throw Exception('No se pudo generar URL de acceso al documento');
      }

      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se puede abrir el documento');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir documento: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showAddDiagnosisDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: context.read<MedicalProvider>(),
        child: DiagnosisFormDialog(medicalRecordId: _currentRecord.id),
      ),
    );

    // Refresh the record after adding
    if (result == true) {
      await _refreshRecord();
    }
  }

  void _showAddFollowUpDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: context.read<MedicalProvider>(),
        child: FollowUpFormDialog(medicalRecordId: _currentRecord.id),
      ),
    );

    // Refresh the record after adding
    if (result == true) {
      await _refreshRecord();
    }
  }
}

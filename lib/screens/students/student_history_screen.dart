import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/student_widgets.dart';
import '../../widgets/app_drawer.dart';

class StudentHistoryScreen extends StatefulWidget {
  final String studentId;

  const StudentHistoryScreen({super.key, required this.studentId});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen>
    with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();

  Student? _student;
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final student = await _studentService.getStudentById(widget.studentId);
      setState(() {
        _student = student;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificado';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_student?.fullName ?? 'Historial del Estudiante'),
        elevation: 0,
        bottom: _student != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.timeline), text: 'Cronología'),
                  Tab(icon: Icon(Icons.assessment), text: 'Reportes'),
                  Tab(icon: Icon(Icons.insights), text: 'Estadísticas'),
                ],
              )
            : null,
      ),
      drawer: const AppDrawer(),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _error != null
            ? _buildErrorState()
            : _student == null
            ? _buildNotFoundState()
            : _buildHistoryContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar historial',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStudent,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Estudiante no encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Column(
      children: [
        // Header con información básica
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              ProfileImageWidget(
                imageUrl: _student!.profileImageUrl,
                size: 60,
                isEditable: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _student!.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_student!.gradeGroup} • ${_student!.enrollment}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs con contenido
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTimelineTab(),
              _buildReportsTab(),
              _buildStatsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab() {
    final List<TimelineEvent> events = _generateTimelineEvents();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (events.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.timeline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay eventos en el historial',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...events.map((event) => _buildTimelineItem(event)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(event.icon, color: event.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(event.date),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Resumen de reportes
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Reportes Positivos',
                  value: '${_student!.positiveReportsCount}',
                  icon: Icons.thumb_up,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Reportes Negativos',
                  value: '${_student!.negativeReportsCount}',
                  icon: Icons.thumb_down,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Lista de reportes (simulada)
          InfoCard(
            title: 'Reportes Recientes',
            icon: Icons.assignment,
            child: Column(
              children: [
                _buildReportItem(
                  'Participación Excepcional',
                  'Mostró gran interés en la clase de matemáticas',
                  DateTime.now().subtract(const Duration(days: 2)),
                  true,
                ),
                const Divider(),
                _buildReportItem(
                  'Llegada Tarde',
                  'Llegó 15 minutos tarde a la primera hora',
                  DateTime.now().subtract(const Duration(days: 5)),
                  false,
                ),
                const Divider(),
                _buildReportItem(
                  'Ayuda a Compañero',
                  'Ayudó a un compañero con dificultades en lectura',
                  DateTime.now().subtract(const Duration(days: 7)),
                  true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón para ver más reportes
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Funcionalidad de reportes detallados en desarrollo',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.more_horiz),
              label: const Text('Ver Todos los Reportes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String title,
    String description,
    DateTime date,
    bool isPositive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.thumb_up : Icons.thumb_down,
              size: 14,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Estadísticas generales
          InfoCard(
            title: 'Estadísticas Generales',
            icon: Icons.analytics,
            child: Column(
              children: [
                InfoRow(
                  label: 'Tiempo en la institución',
                  value: _calculateTimeInSchool(),
                ),
                InfoRow(
                  label: 'Promedio de reportes positivos/mes',
                  value: _calculateAveragePositiveReports(),
                ),
                InfoRow(
                  label: 'Promedio de reportes negativos/mes',
                  value: _calculateAverageNegativeReports(),
                ),
                InfoRow(
                  label: 'Ratio positivo/negativo',
                  value: _calculateRatio(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tendencias
          InfoCard(
            title: 'Tendencias de Comportamiento',
            icon: Icons.trending_up,
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Gráfico de tendencias',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '(Próximamente)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Comparación con el grupo
          InfoCard(
            title: 'Comparación con el Grupo',
            icon: Icons.people,
            child: Column(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Comparación grupal',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '(Próximamente)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TimelineEvent> _generateTimelineEvents() {
    final List<TimelineEvent> events = [];

    // Evento de creación
    events.add(
      TimelineEvent(
        title: 'Registro en el sistema',
        description: 'El estudiante fue registrado en el sistema',
        date: _student!.createdAt,
        icon: Icons.person_add,
        color: Colors.blue,
      ),
    );

    // Evento de fecha de alta si existe
    if (_student!.fechaAlta != null) {
      events.add(
        TimelineEvent(
          title: 'Alta en la institución',
          description: 'Fecha oficial de ingreso a la institución',
          date: _student!.fechaAlta!,
          icon: Icons.school,
          color: Colors.green,
        ),
      );
    }

    // Evento de fecha de baja si existe
    if (_student!.fechaBaja != null) {
      events.add(
        TimelineEvent(
          title: 'Baja de la institución',
          description: _student!.motivoBaja ?? 'Baja de la institución',
          date: _student!.fechaBaja!,
          icon: Icons.exit_to_app,
          color: Colors.red,
        ),
      );
    }

    // Evento de última actualización si existe
    if (_student!.updatedAt != null) {
      events.add(
        TimelineEvent(
          title: 'Información actualizada',
          description: 'Se actualizó la información del estudiante',
          date: _student!.updatedAt!,
          icon: Icons.update,
          color: Colors.orange,
        ),
      );
    }

    // Ordenar eventos por fecha (más reciente primero)
    events.sort((a, b) => b.date.compareTo(a.date));

    return events;
  }

  String _calculateTimeInSchool() {
    final startDate = _student!.fechaAlta ?? _student!.createdAt;
    final endDate = _student!.fechaBaja ?? DateTime.now();
    final difference = endDate.difference(startDate).inDays;

    if (difference < 30) {
      return '$difference días';
    } else if (difference < 365) {
      final months = (difference / 30).round();
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final years = (difference / 365).floor();
      final remainingMonths = ((difference % 365) / 30).round();
      String result = '$years ${years == 1 ? 'año' : 'años'}';
      if (remainingMonths > 0) {
        result +=
            ' y $remainingMonths ${remainingMonths == 1 ? 'mes' : 'meses'}';
      }
      return result;
    }
  }

  String _calculateAveragePositiveReports() {
    final startDate = _student!.fechaAlta ?? _student!.createdAt;
    final months = DateTime.now().difference(startDate).inDays / 30;
    if (months < 1) return '${_student!.positiveReportsCount}';

    final average = _student!.positiveReportsCount / months;
    return average.toStringAsFixed(1);
  }

  String _calculateAverageNegativeReports() {
    final startDate = _student!.fechaAlta ?? _student!.createdAt;
    final months = DateTime.now().difference(startDate).inDays / 30;
    if (months < 1) return '${_student!.negativeReportsCount}';

    final average = _student!.negativeReportsCount / months;
    return average.toStringAsFixed(1);
  }

  String _calculateRatio() {
    if (_student!.negativeReportsCount == 0) {
      return _student!.positiveReportsCount > 0 ? '∞:1' : '0:0';
    }

    final ratio =
        _student!.positiveReportsCount / _student!.negativeReportsCount;
    return '${ratio.toStringAsFixed(1)}:1';
  }
}

class TimelineEvent {
  final String title;
  final String description;
  final DateTime date;
  final IconData icon;
  final Color color;

  TimelineEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.color,
  });
}

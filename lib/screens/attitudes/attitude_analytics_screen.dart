import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attitude_provider.dart';
import '../../providers/students_provider.dart';

class AttitudeAnalyticsScreen extends StatefulWidget {
  final String studentId;

  const AttitudeAnalyticsScreen({super.key, required this.studentId});

  @override
  State<AttitudeAnalyticsScreen> createState() =>
      _AttitudeAnalyticsScreenState();
}

class _AttitudeAnalyticsScreenState extends State<AttitudeAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttitudeProvider>().loadAttitudesForStudent(
        widget.studentId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de Actitudes')),
      body: Consumer<AttitudeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final analysis = provider.getPatternAnalysis(widget.studentId);
          final evolution = provider.getTemporalEvolution(widget.studentId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStudentInfo(),
              const SizedBox(height: 16),
              _buildSummaryCard(analysis),
              const SizedBox(height: 16),
              _buildTrendCard(analysis),
              const SizedBox(height: 16),
              _buildEvolutionCard(evolution),
              const SizedBox(height: 16),
              _buildFrequentBehaviorsCard(analysis),
              const SizedBox(height: 16),
              _buildContextCard(analysis),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Consumer<StudentsProvider>(
      builder: (context, provider, child) {
        final student = provider.students.firstWhere(
          (s) => s.id == widget.studentId,
          orElse: () => provider.students.first,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: student.profileImageUrl != null
                      ? NetworkImage(student.profileImageUrl!)
                      : null,
                  child: student.profileImageUrl == null
                      ? Text(
                          student.firstName[0] + student.lastName[0],
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student.firstName} ${student.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${student.grade} - ${student.group}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> analysis) {
    final total = analysis['totalAttitudes'] as int;
    final positive = analysis['positiveCount'] as int;
    final negative = analysis['negativeCount'] as int;
    final percentage = analysis['positivePercentage'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total', '$total', Icons.list, Colors.blue),
                _buildStatColumn(
                  'Positivas',
                  '$positive',
                  Icons.sentiment_satisfied,
                  Colors.green,
                ),
                _buildStatColumn(
                  'Negativas',
                  '$negative',
                  Icons.sentiment_dissatisfied,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: total > 0 ? percentage / 100 : 0,
              backgroundColor: Colors.orange.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${percentage.toStringAsFixed(1)}% Actitudes Positivas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTrendCard(Map<String, dynamic> analysis) {
    final trend = analysis['trend'] as String;

    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (trend) {
      case 'mejorando':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Mejorando';
        break;
      case 'empeorando':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Necesita Atención';
        break;
      case 'estable':
        trendIcon = Icons.trending_flat;
        trendColor = Colors.blue;
        trendText = 'Estable';
        break;
      default:
        trendIcon = Icons.help_outline;
        trendColor = Colors.grey;
        trendText = 'Sin Datos Suficientes';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendencia (Últimos 30 días)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(trendIcon, size: 64, color: trendColor),
                  const SizedBox(height: 8),
                  Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTrendDescription(trend),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTrendDescription(String trend) {
    switch (trend) {
      case 'mejorando':
        return 'El estudiante muestra una mejora significativa en su comportamiento';
      case 'empeorando':
        return 'Se ha detectado un incremento en actitudes negativas';
      case 'estable':
        return 'El comportamiento se mantiene constante';
      default:
        return 'No hay suficientes datos para determinar una tendencia';
    }
  }

  Widget _buildEvolutionCard(Map<String, Map<String, int>> evolution) {
    if (evolution.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Evolución Temporal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay suficientes datos para mostrar la evolución',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by month
    final sortedMonths = evolution.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolución Temporal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentMonths.length,
                itemBuilder: (context, index) {
                  final monthKey = recentMonths[index];
                  final data = evolution[monthKey]!;
                  final positive = data['positive'] ?? 0;
                  final negative = data['negative'] ?? 0;
                  final total = positive + negative;

                  // Parse month
                  final parts = monthKey.split('-');
                  final year = parts[0].substring(2);
                  final month = _getMonthName(int.parse(parts[1]));

                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (positive > 0)
                                Flexible(
                                  flex: positive,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$positive',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (positive > 0 && negative > 0)
                                const SizedBox(height: 4),
                              if (negative > 0)
                                Flexible(
                                  flex: negative,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$negative',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(month, style: const TextStyle(fontSize: 10)),
                        Text(
                          "'$year",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Positivas', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Negativas', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }

  Widget _buildFrequentBehaviorsCard(Map<String, dynamic> analysis) {
    final behaviors = analysis['frequentBehaviors'] as List<String>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comportamientos Frecuentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (behaviors.isEmpty)
              Text(
                'No se han detectado patrones recurrentes',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...behaviors.map(
                (behavior) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          behavior,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard(Map<String, dynamic> analysis) {
    final context = analysis['mostCommonContext'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contexto Más Común',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 32, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context ?? 'No especificado',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (context != null) ...[
              const SizedBox(height: 12),
              Text(
                'La mayoría de las actitudes se observan en este contexto',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

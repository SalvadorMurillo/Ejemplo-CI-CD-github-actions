import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';
import '../services/database_service.dart';

class AttitudeProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<models.AttitudeRecord> _attitudes = [];
  models.AttitudeRecord? _selectedAttitude;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  String? _selectedStudentId;
  String? _selectedAttitudeType; // 'positive' or 'negative'
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasMoreData = true;

  // Getters
  List<models.AttitudeRecord> get attitudes => _attitudes;
  models.AttitudeRecord? get selectedAttitude => _selectedAttitude;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String? get selectedStudentId => _selectedStudentId;
  String? get selectedAttitudeType => _selectedAttitudeType;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get hasMoreData => _hasMoreData;

  // ***** CARGA DE DATOS *****

  Future<void> loadAttitudes({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _attitudes.clear();
        _currentPage = 0;
        _hasMoreData = true;
      }

      final newAttitudes = await _databaseService.getAttitudeRecords(
        studentId: _selectedStudentId,
        attitudeType: _selectedAttitudeType,
        startDate: _startDate,
        endDate: _endDate,
        offset: _currentPage * AppConstants.defaultPageSize,
      );

      if (newAttitudes.length < AppConstants.defaultPageSize) {
        _hasMoreData = false;
      }

      if (refresh) {
        _attitudes = newAttitudes;
      } else {
        _attitudes.addAll(newAttitudes);
      }

      _currentPage++;
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar actitudes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAttitudesForStudent(String studentId) async {
    _selectedStudentId = studentId;
    await loadAttitudes(refresh: true);
  }

  // ***** FILTROS *****

  void setStudentFilter(String? studentId) {
    if (_selectedStudentId != studentId) {
      _selectedStudentId = studentId;
      _refreshData();
    }
  }

  void setAttitudeTypeFilter(String? type) {
    if (_selectedAttitudeType != type) {
      _selectedAttitudeType = type;
      _refreshData();
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    if (_startDate != start || _endDate != end) {
      _startDate = start;
      _endDate = end;
      _refreshData();
    }
  }

  void clearFilters() {
    _selectedStudentId = null;
    _selectedAttitudeType = null;
    _startDate = null;
    _endDate = null;
    _refreshData();
  }

  void _refreshData() {
    loadAttitudes(refresh: true);
  }

  // ***** CRUD OPERATIONS *****

  Future<bool> createAttitude(models.AttitudeRecord attitude) async {
    try {
      _setLoading(true);
      _clearError();

      final createdAttitude = await _databaseService.createAttitudeRecord(
        attitude,
      );
      _attitudes.insert(0, createdAttitude);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear registro de actitud: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAttitude(models.AttitudeRecord attitude) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedAttitude = await _databaseService.updateAttitudeRecord(
        attitude,
      );
      final index = _attitudes.indexWhere((a) => a.id == attitude.id);
      if (index != -1) {
        _attitudes[index] = updatedAttitude;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar registro de actitud: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAttitude(String attitudeId) async {
    try {
      _setLoading(true);
      _clearError();

      await _databaseService.deleteAttitudeRecord(attitudeId);
      _attitudes.removeWhere((a) => a.id == attitudeId);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar registro de actitud: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ***** ESTADÍSTICAS *****

  Map<String, int> getAttitudesByType() {
    final stats = <String, int>{'Positivas': 0, 'Negativas': 0};

    for (final attitude in _attitudes) {
      if (attitude.isPositive) {
        stats['Positivas'] = (stats['Positivas'] ?? 0) + 1;
      } else {
        stats['Negativas'] = (stats['Negativas'] ?? 0) + 1;
      }
    }

    return stats;
  }

  Map<String, int> getAttitudesByFrequency() {
    final stats = <String, int>{};

    for (final attitude in _attitudes) {
      if (attitude.frequency != null && attitude.frequency!.isNotEmpty) {
        final freq = attitude.frequency!;
        stats[freq] = (stats[freq] ?? 0) + 1;
      }
    }

    return stats;
  }

  List<models.AttitudeRecord> getPositiveAttitudes() {
    return _attitudes.where((attitude) => attitude.isPositive).toList();
  }

  List<models.AttitudeRecord> getNegativeAttitudes() {
    return _attitudes.where((attitude) => attitude.isNegative).toList();
  }

  List<models.AttitudeRecord> getAttitudesForStudent(String studentId) {
    return _attitudes
        .where((attitude) => attitude.studentId == studentId)
        .toList();
  }

  int getPositiveAttitudesCount(String studentId) {
    return _attitudes
        .where(
          (attitude) => attitude.studentId == studentId && attitude.isPositive,
        )
        .length;
  }

  int getNegativeAttitudesCount(String studentId) {
    return _attitudes
        .where(
          (attitude) => attitude.studentId == studentId && attitude.isNegative,
        )
        .length;
  }

  // ***** ANÁLISIS DE PATRONES *****

  Map<String, dynamic> getPatternAnalysis(String studentId) {
    final studentAttitudes = getAttitudesForStudent(studentId);

    if (studentAttitudes.isEmpty) {
      return {
        'totalAttitudes': 0,
        'positiveCount': 0,
        'negativeCount': 0,
        'positivePercentage': 0.0,
        'trend': 'sin_datos',
        'mostCommonContext': null,
        'frequentBehaviors': <String>[],
      };
    }

    final positiveCount = studentAttitudes.where((a) => a.isPositive).length;
    final negativeCount = studentAttitudes.where((a) => a.isNegative).length;
    final total = studentAttitudes.length;

    // Calcular tendencia (últimos 30 días vs anteriores)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentAttitudes = studentAttitudes
        .where((a) => a.observationDate.isAfter(thirtyDaysAgo))
        .toList();

    final olderAttitudes = studentAttitudes
        .where((a) => a.observationDate.isBefore(thirtyDaysAgo))
        .toList();

    String trend = 'estable';
    if (recentAttitudes.isNotEmpty && olderAttitudes.isNotEmpty) {
      final recentPositiveRatio =
          recentAttitudes.where((a) => a.isPositive).length /
          recentAttitudes.length;
      final olderPositiveRatio =
          olderAttitudes.where((a) => a.isPositive).length /
          olderAttitudes.length;

      if (recentPositiveRatio > olderPositiveRatio + 0.1) {
        trend = 'mejorando';
      } else if (recentPositiveRatio < olderPositiveRatio - 0.1) {
        trend = 'empeorando';
      }
    }

    // Contexto más común
    final contextCounts = <String, int>{};
    for (final attitude in studentAttitudes) {
      if (attitude.context != null && attitude.context!.isNotEmpty) {
        contextCounts[attitude.context!] =
            (contextCounts[attitude.context!] ?? 0) + 1;
      }
    }

    String? mostCommonContext;
    int maxCount = 0;
    contextCounts.forEach((context, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonContext = context;
      }
    });

    // Comportamientos frecuentes (títulos más repetidos)
    final behaviorCounts = <String, int>{};
    for (final attitude in studentAttitudes) {
      behaviorCounts[attitude.title] =
          (behaviorCounts[attitude.title] ?? 0) + 1;
    }

    final frequentBehaviors =
        behaviorCounts.entries
            .where((e) => e.value > 1)
            .map((e) => e.key)
            .toList()
          ..sort((a, b) => behaviorCounts[b]!.compareTo(behaviorCounts[a]!));

    return {
      'totalAttitudes': total,
      'positiveCount': positiveCount,
      'negativeCount': negativeCount,
      'positivePercentage': (positiveCount / total * 100),
      'trend': trend,
      'mostCommonContext': mostCommonContext,
      'frequentBehaviors': frequentBehaviors.take(5).toList(),
    };
  }

  // Obtener evolución temporal (por mes)
  Map<String, Map<String, int>> getTemporalEvolution(String studentId) {
    final studentAttitudes = getAttitudesForStudent(studentId);
    final evolution = <String, Map<String, int>>{};

    for (final attitude in studentAttitudes) {
      final monthKey =
          '${attitude.observationDate.year}-${attitude.observationDate.month.toString().padLeft(2, '0')}';

      if (!evolution.containsKey(monthKey)) {
        evolution[monthKey] = {'positive': 0, 'negative': 0};
      }

      if (attitude.isPositive) {
        evolution[monthKey]!['positive'] =
            evolution[monthKey]!['positive']! + 1;
      } else {
        evolution[monthKey]!['negative'] =
            evolution[monthKey]!['negative']! + 1;
      }
    }

    return evolution;
  }

  // ***** UTILIDADES *****

  void selectAttitude(models.AttitudeRecord attitude) {
    _selectedAttitude = attitude;
    notifyListeners();
  }

  void clearSelectedAttitude() {
    _selectedAttitude = null;
    notifyListeners();
  }

  Color getAttitudeColor(models.AttitudeRecord attitude) {
    return attitude.isPositive ? Colors.green : Colors.orange;
  }

  String getAttitudeIcon(models.AttitudeRecord attitude) {
    return attitude.isPositive ? '😊' : '😟';
  }

  // ***** ESTADO *****

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _attitudes.clear();
    _selectedAttitude = null;
    super.dispose();
  }
}

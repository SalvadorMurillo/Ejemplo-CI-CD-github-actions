import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';
import '../config/theme.dart';
import '../services/database_service.dart';

class ConductProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<models.ConductReport> _reports = [];
  models.ConductReport? _selectedReport;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  String? _selectedStudentId;
  ConductReportType? _selectedType;
  IncidentSeverity? _selectedSeverity;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasMoreData = true;

  // Getters
  List<models.ConductReport> get reports => _reports;
  models.ConductReport? get selectedReport => _selectedReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String? get selectedStudentId => _selectedStudentId;
  ConductReportType? get selectedType => _selectedType;
  IncidentSeverity? get selectedSeverity => _selectedSeverity;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get hasMoreData => _hasMoreData;

  // ***** CARGA DE DATOS *****

  Future<void> loadReports({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _reports.clear();
        _currentPage = 0;
        _hasMoreData = true;
      }

      final newReports = await _databaseService.getConductReports(
        studentId: _selectedStudentId,
        type: _selectedType,
        severity: _selectedSeverity,
        startDate: _startDate,
        endDate: _endDate,
        offset: _currentPage * AppConstants.defaultPageSize,
      );

      if (newReports.length < AppConstants.defaultPageSize) {
        _hasMoreData = false;
      }

      if (refresh) {
        _reports = newReports;
      } else {
        _reports.addAll(newReports);
      }

      _currentPage++;
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar reportes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReportsForStudent(String studentId) async {
    _selectedStudentId = studentId;
    await loadReports(refresh: true);
  }

  // ***** FILTROS *****

  void setStudentFilter(String? studentId) {
    if (_selectedStudentId != studentId) {
      _selectedStudentId = studentId;
      _refreshData();
    }
  }

  void setTypeFilter(ConductReportType? type) {
    if (_selectedType != type) {
      _selectedType = type;
      _refreshData();
    }
  }

  void setSeverityFilter(IncidentSeverity? severity) {
    if (_selectedSeverity != severity) {
      _selectedSeverity = severity;
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
    _selectedType = null;
    _selectedSeverity = null;
    _startDate = null;
    _endDate = null;
    _refreshData();
  }

  void _refreshData() {
    loadReports(refresh: true);
  }

  // ***** CRUD OPERATIONS *****

  Future<bool> createReport(models.ConductReport report) async {
    try {
      _setLoading(true);
      _clearError();

      final createdReport = await _databaseService.createConductReport(report);
      _reports.insert(0, createdReport);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear reporte: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReport(models.ConductReport report) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedReport = await _databaseService.updateConductReport(report);

      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _reports[index] = updatedReport;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar reporte: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      _setLoading(true);
      _clearError();

      await _databaseService.deleteConductReport(reportId);

      _reports.removeWhere((r) => r.id == reportId);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar reporte: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ***** ESTADÍSTICAS *****

  Map<String, int> getReportsByType() {
    final stats = <String, int>{};

    for (final report in _reports) {
      final type = report.type.displayName;
      stats[type] = (stats[type] ?? 0) + 1;
    }

    return stats;
  }

  Map<String, int> getReportsBySeverity() {
    final stats = <String, int>{};

    for (final report in _reports) {
      if (report.severity != null) {
        final severity = report.severity!.displayName;
        stats[severity] = (stats[severity] ?? 0) + 1;
      }
    }

    return stats;
  }

  List<models.ConductReport> getPositiveReports() {
    return _reports.where((report) => report.isPositive).toList();
  }

  List<models.ConductReport> getNegativeReports() {
    return _reports.where((report) => report.isNegative).toList();
  }

  List<models.ConductReport> getReportsForStudent(String studentId) {
    return _reports.where((report) => report.studentId == studentId).toList();
  }

  int getPositiveReportsCount(String studentId) {
    return _reports
        .where((report) => report.studentId == studentId && report.isPositive)
        .length;
  }

  int getNegativeReportsCount(String studentId) {
    return _reports
        .where((report) => report.studentId == studentId && report.isNegative)
        .length;
  }

  // ***** UTILIDADES *****

  void selectReport(models.ConductReport report) {
    _selectedReport = report;
    notifyListeners();
  }

  void clearSelectedReport() {
    _selectedReport = null;
    notifyListeners();
  }

  Color getReportColor(models.ConductReport report) {
    if (report.isPositive) {
      return AppColors.positive;
    }

    switch (report.severity) {
      case IncidentSeverity.mild:
        return AppColors.mild;
      case IncidentSeverity.moderate:
        return AppColors.moderate;
      case IncidentSeverity.severe:
        return AppColors.severe;
      case IncidentSeverity.verySevere:
        return AppColors.verySevere;
      default:
        return AppColors.primary;
    }
  }

  String getReportIcon(models.ConductReport report) {
    if (report.isPositive) {
      return '🟢';
    }

    switch (report.severity) {
      case IncidentSeverity.mild:
        return '🟡';
      case IncidentSeverity.moderate:
        return '🟠';
      case IncidentSeverity.severe:
        return '🔴';
      case IncidentSeverity.verySevere:
        return '⚫';
      default:
        return '🔘';
    }
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
    _reports.clear();
    _selectedReport = null;
    super.dispose();
  }
}

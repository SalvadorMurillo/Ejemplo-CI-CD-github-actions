import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';
import '../services/database_service.dart';

class BAPProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<models.BAPRecord> _records = [];
  models.BAPRecord? _selectedRecord;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  String? _selectedStudentId;
  BAPType? _selectedType;
  String? _selectedStatus;
  bool _hasMoreData = true;
  List<models.BAPRecord> _pendingFollowUps = [];

  // Getters
  List<models.BAPRecord> get records => _records;
  models.BAPRecord? get selectedRecord => _selectedRecord;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String? get selectedStudentId => _selectedStudentId;
  BAPType? get selectedType => _selectedType;
  String? get selectedStatus => _selectedStatus;
  bool get hasMoreData => _hasMoreData;
  List<models.BAPRecord> get pendingFollowUps => _pendingFollowUps;

  // ***** CARGA DE DATOS *****

  Future<void> loadRecords({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _records.clear();
        _currentPage = 0;
        _hasMoreData = true;
      }

      final newRecords = await _databaseService.getBAPRecords(
        studentId: _selectedStudentId,
        type: _selectedType,
        status: _selectedStatus,
        limit: AppConstants.defaultPageSize,
        offset: _currentPage * AppConstants.defaultPageSize,
      );

      if (newRecords.length < AppConstants.defaultPageSize) {
        _hasMoreData = false;
      }

      if (refresh) {
        _records = newRecords;
      } else {
        _records.addAll(newRecords);
      }

      _currentPage++;
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar registros BAP: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRecordById(String id) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedRecord = await _databaseService.getBAPRecordById(id);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar registro BAP: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingFollowUps() async {
    try {
      _pendingFollowUps = await _databaseService
          .getBAPRecordsWithPendingFollowUp();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar seguimientos pendientes: ${e.toString()}');
    }
  }

  // ***** CREACIÓN Y ACTUALIZACIÓN *****

  Future<bool> createRecord(models.BAPRecord record) async {
    try {
      _setLoading(true);
      _clearError();

      final newRecord = await _databaseService.createBAPRecord(record);
      _records.insert(0, newRecord);
      _selectedRecord = newRecord;

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear registro BAP: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRecord(models.BAPRecord record) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedRecord = await _databaseService.updateBAPRecord(record);

      final index = _records.indexWhere((r) => r.id == updatedRecord.id);
      if (index != -1) {
        _records[index] = updatedRecord;
      }

      if (_selectedRecord?.id == updatedRecord.id) {
        _selectedRecord = updatedRecord;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar registro BAP: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addFollowUp(String recordId, models.BAPFollowUp followUp) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedRecord = await _databaseService.addBAPFollowUp(
        recordId,
        followUp,
      );

      final index = _records.indexWhere((r) => r.id == updatedRecord.id);
      if (index != -1) {
        _records[index] = updatedRecord;
      }

      if (_selectedRecord?.id == updatedRecord.id) {
        _selectedRecord = updatedRecord;
      }

      // Recargar seguimientos pendientes
      await loadPendingFollowUps();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al agregar seguimiento: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      _setLoading(true);
      _clearError();

      await _databaseService.deleteBAPRecord(id);
      _records.removeWhere((r) => r.id == id);

      if (_selectedRecord?.id == id) {
        _selectedRecord = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar registro BAP: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ***** FILTROS *****

  void setStudentFilter(String? studentId) {
    _selectedStudentId = studentId;
    notifyListeners();
  }

  void setTypeFilter(BAPType? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _selectedStudentId = null;
    _selectedType = null;
    _selectedStatus = null;
    notifyListeners();
  }

  void applyFilters() {
    loadRecords(refresh: true);
  }

  // ***** ESTADÍSTICAS *****

  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    stats['total'] = _records.length;
    stats['active'] = _records.where((r) => r.currentStatus == 'active').length;
    stats['in_progress'] = _records
        .where((r) => r.currentStatus == 'in_progress')
        .length;
    stats['resolved'] = _records
        .where((r) => r.currentStatus == 'resolved')
        .length;

    // Estadísticas por tipo
    final typeStats = <String, int>{};
    for (var type in BAPType.values) {
      typeStats[type.name] = _records.where((r) => r.type == type).length;
    }
    stats['by_type'] = typeStats;

    return stats;
  }

  // ***** HELPERS *****

  void selectRecord(models.BAPRecord record) {
    _selectedRecord = record;
    notifyListeners();
  }

  void clearSelection() {
    _selectedRecord = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _records.clear();
    _pendingFollowUps.clear();
    super.dispose();
  }
}

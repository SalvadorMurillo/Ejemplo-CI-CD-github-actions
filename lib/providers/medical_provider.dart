import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';
import '../services/medical_service.dart';
import '../services/database_service.dart';

class MedicalProvider extends ChangeNotifier {
  final MedicalService _medicalService = MedicalService();
  final DatabaseService _databaseService = DatabaseService();
  static const Uuid _uuid = Uuid();

  List<models.MedicalRecord> _records = [];
  models.MedicalRecord? _selectedRecord;
  models.Student? _selectedStudent;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  String? _searchQuery;
  String? _selectedGrade;
  String? _selectedGroup;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasMoreData = true;

  // Getters
  List<models.MedicalRecord> get records => _records;
  models.MedicalRecord? get selectedRecord => _selectedRecord;
  models.Student? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String? get searchQuery => _searchQuery;
  String? get selectedGrade => _selectedGrade;
  String? get selectedGroup => _selectedGroup;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get hasMoreData => _hasMoreData;

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

      final newRecords = await _medicalService.getMedicalRecords(
        search: _searchQuery,
        grade: _selectedGrade,
        group: _selectedGroup,
        startDate: _startDate,
        endDate: _endDate,
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
      _setError('Error al cargar expedientes médicos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRecordForStudent(String studentId) async {
    try {
      _setLoading(true);
      _clearError();

      // Cargar información del estudiante
      final student = await _databaseService.getStudentById(studentId);
      _selectedStudent = student;

      // Cargar expediente médico
      final record = await _medicalService.getMedicalRecordByStudentId(
        studentId,
      );
      _selectedRecord = record;

      notifyListeners();
    } catch (e) {
      _setError('Error al cargar expediente médico: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ***** BÚSQUEDA Y FILTROS *****

  void setSearchQuery(String? query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      loadRecords(refresh: true);
    }
  }

  void setGradeFilter(String? grade) {
    if (_selectedGrade != grade) {
      _selectedGrade = grade;
      loadRecords(refresh: true);
    }
  }

  void setGroupFilter(String? group) {
    if (_selectedGroup != group) {
      _selectedGroup = group;
      loadRecords(refresh: true);
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    if (_startDate != start || _endDate != end) {
      _startDate = start;
      _endDate = end;
      loadRecords(refresh: true);
    }
  }

  void clearSearch() {
    setSearchQuery(null);
  }

  void clearFilters() {
    _searchQuery = null;
    _selectedGrade = null;
    _selectedGroup = null;
    _startDate = null;
    _endDate = null;
    loadRecords(refresh: true);
  }

  // ***** CRUD EXPEDIENTE MÉDICO *****

  Future<bool> createMedicalRecord(models.MedicalRecord record) async {
    try {
      _setLoading(true);
      _clearError();

      final createdRecord = await _medicalService.createMedicalRecord(record);
      _records.insert(0, createdRecord);

      if (_selectedRecord == null && _selectedStudent?.id == record.studentId) {
        _selectedRecord = createdRecord;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear expediente médico: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMedicalRecord(models.MedicalRecord record) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedRecord = await _medicalService.updateMedicalRecord(record);

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
      _setError('Error al actualizar expediente médico: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMedicalRecord(String id) async {
    try {
      _setLoading(true);
      _clearError();

      await _medicalService.deleteMedicalRecord(id);
      _records.removeWhere((r) => r.id == id);

      if (_selectedRecord?.id == id) {
        _selectedRecord = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar expediente médico: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ***** DIAGNÓSTICOS *****

  Future<bool> addDiagnosis({
    required String medicalRecordId,
    required String diagnosis,
    String? diagnosingDoctor,
    required DateTime diagnosisDate,
    String? description,
    List<String> attachmentUrls = const [],
    String? treatment,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final newDiagnosis = models.MedicalDiagnosis(
        id: _uuid.v4(),
        medicalRecordId: medicalRecordId,
        diagnosis: diagnosis,
        diagnosingDoctor: diagnosingDoctor,
        diagnosisDate: diagnosisDate,
        description: description,
        attachmentUrls: attachmentUrls,
        treatment: treatment,
        createdAt: DateTime.now(),
      );

      final updatedRecord = await _medicalService.addDiagnosis(
        medicalRecordId,
        newDiagnosis,
      );

      _updateRecordInLists(updatedRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al agregar diagnóstico: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDiagnosis({
    required String medicalRecordId,
    required models.MedicalDiagnosis diagnosis,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedDiagnosis = diagnosis.copyWith(updatedAt: DateTime.now());

      final updatedRecord = await _medicalService.updateDiagnosis(
        medicalRecordId,
        updatedDiagnosis,
      );

      _updateRecordInLists(updatedRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar diagnóstico: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteDiagnosis({
    required String medicalRecordId,
    required String diagnosisId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedRecord = await _medicalService.deleteDiagnosis(
        medicalRecordId,
        diagnosisId,
      );

      _updateRecordInLists(updatedRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar diagnóstico: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ***** SEGUIMIENTOS MÉDICOS *****

  Future<bool> addFollowUp({
    required String medicalRecordId,
    required DateTime followUpDate,
    String? consultationType,
    String? observations,
    String? attendingPhysician,
    String? evolution,
    String? schoolObservations,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final newFollowUp = models.MedicalFollowUp(
        id: _uuid.v4(),
        medicalRecordId: medicalRecordId,
        followUpDate: followUpDate,
        consultationType: consultationType,
        observations: observations,
        attendingPhysician: attendingPhysician,
        evolution: evolution,
        schoolObservations: schoolObservations,
        attachmentUrls: attachmentUrls,
        createdAt: DateTime.now(),
      );

      final updatedRecord = await _medicalService.addFollowUp(
        medicalRecordId,
        newFollowUp,
      );

      _updateRecordInLists(updatedRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al agregar seguimiento: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateFollowUp({
    required String medicalRecordId,
    required models.MedicalFollowUp followUp,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedRecord = await _medicalService.updateFollowUp(
        medicalRecordId,
        followUp,
      );

      _updateRecordInLists(updatedRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar seguimiento: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteFollowUp({
    required String medicalRecordId,
    required String followUpId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedRecord = await _medicalService.deleteFollowUp(
        medicalRecordId,
        followUpId,
      );

      _updateRecordInLists(updatedRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar seguimiento: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ***** ESTADÍSTICAS *****

  List<models.MedicalDiagnosis> getActiveDiagnoses() {
    if (_selectedRecord == null) return [];
    return _selectedRecord!.diagnoses.where((d) => d.isActive).toList();
  }

  List<models.MedicalFollowUp> getRecentFollowUps({int limit = 5}) {
    if (_selectedRecord == null) return [];

    final sortedFollowUps = [..._selectedRecord!.followUps];
    sortedFollowUps.sort((a, b) => b.followUpDate.compareTo(a.followUpDate));

    return sortedFollowUps.take(limit).toList();
  }

  int getTotalDiagnosesCount() {
    if (_selectedRecord == null) return 0;
    return _selectedRecord!.diagnoses.length;
  }

  int getActiveDiagnosesCount() {
    if (_selectedRecord == null) return 0;
    return _selectedRecord!.diagnoses.where((d) => d.isActive).length;
  }

  int getTotalFollowUpsCount() {
    if (_selectedRecord == null) return 0;
    return _selectedRecord!.followUps.length;
  }

  bool hasAllergies() {
    return _selectedRecord != null &&
        _selectedRecord!.knownAllergies.isNotEmpty;
  }

  bool hasChronicConditions() {
    return _selectedRecord != null &&
        _selectedRecord!.chronicConditions.isNotEmpty;
  }

  bool hasCurrentMedications() {
    return _selectedRecord != null &&
        _selectedRecord!.currentMedications.isNotEmpty;
  }

  // ***** HELPERS *****

  void _updateRecordInLists(models.MedicalRecord updatedRecord) {
    final index = _records.indexWhere((r) => r.id == updatedRecord.id);
    if (index != -1) {
      _records[index] = updatedRecord;
    }

    if (_selectedRecord?.id == updatedRecord.id) {
      _selectedRecord = updatedRecord;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearSelectedRecord() {
    _selectedRecord = null;
    _selectedStudent = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _records.clear();
    _selectedRecord = null;
    _selectedStudent = null;
    super.dispose();
  }
}

// Extension para MedicalDiagnosis copyWith
extension MedicalDiagnosisCopyWith on models.MedicalDiagnosis {
  models.MedicalDiagnosis copyWith({
    String? id,
    String? medicalRecordId,
    String? diagnosis,
    String? diagnosingDoctor,
    DateTime? diagnosisDate,
    String? description,
    List<String>? attachmentUrls,
    bool? isActive,
    String? treatment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return models.MedicalDiagnosis(
      id: id ?? this.id,
      medicalRecordId: medicalRecordId ?? this.medicalRecordId,
      diagnosis: diagnosis ?? this.diagnosis,
      diagnosingDoctor: diagnosingDoctor ?? this.diagnosingDoctor,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      description: description ?? this.description,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isActive: isActive ?? this.isActive,
      treatment: treatment ?? this.treatment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

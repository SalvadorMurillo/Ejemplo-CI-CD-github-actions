import 'package:flutter/foundation.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';
import '../services/database_service.dart';

class StudentsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<models.Student> _students = [];
  models.Student? _selectedStudent;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  String _searchQuery = '';
  SchoolGrade? _selectedGrade;
  String? _selectedGroup;
  bool _hasMoreData = true;

  // Getters
  List<models.Student> get students => _students;
  models.Student? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String get searchQuery => _searchQuery;
  SchoolGrade? get selectedGrade => _selectedGrade;
  String? get selectedGroup => _selectedGroup;
  bool get hasMoreData => _hasMoreData;

  // ***** CARGA DE DATOS *****

  Future<void> loadStudents({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _students.clear();
        _currentPage = 0;
        _hasMoreData = true;
      }

      final newStudents = await _databaseService.getStudents(
        offset: _currentPage * AppConstants.defaultPageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        grade: _selectedGrade,
        group: _selectedGroup,
        isActive: true,
      );

      if (newStudents.length < AppConstants.defaultPageSize) {
        _hasMoreData = false;
      }

      if (refresh) {
        _students = newStudents;
      } else {
        _students.addAll(newStudents);
      }

      _currentPage++;
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar estudiantes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStudentById(String studentId) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedStudent = await _databaseService.getStudentById(studentId);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar estudiante: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ***** BÚSQUEDA Y FILTROS *****

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _refreshData();
    }
  }

  void setGradeFilter(SchoolGrade? grade) {
    if (_selectedGrade != grade) {
      _selectedGrade = grade;
      _refreshData();
    }
  }

  void setGroupFilter(String? group) {
    if (_selectedGroup != group) {
      _selectedGroup = group;
      _refreshData();
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedGrade = null;
    _selectedGroup = null;
    _refreshData();
  }

  void _refreshData() {
    loadStudents(refresh: true);
  }

  // ***** CRUD OPERATIONS *****

  Future<bool> createStudent(models.Student student) async {
    try {
      _setLoading(true);
      _clearError();

      final createdStudent = await _databaseService.createStudent(student);
      _students.insert(0, createdStudent);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear estudiante: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStudent(models.Student student) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedStudent = await _databaseService.updateStudent(student);

      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = updatedStudent;
      }

      if (_selectedStudent?.id == student.id) {
        _selectedStudent = updatedStudent;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar estudiante: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deactivateStudent(String studentId) async {
    try {
      _setLoading(true);
      _clearError();

      await _databaseService.deactivateStudent(studentId);

      _students.removeWhere((s) => s.id == studentId);

      if (_selectedStudent?.id == studentId) {
        _selectedStudent = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al desactivar estudiante: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> reactivateStudent(String studentId) async {
    try {
      _setLoading(true);
      _clearError();

      await _databaseService.reactivateStudent(studentId);

      // Recargar la lista para mostrar el estudiante reactivado
      await loadStudents(refresh: true);

      return true;
    } catch (e) {
      _setError('Error al reactivar estudiante: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ***** UTILIDADES *****

  void selectStudent(models.Student student) {
    _selectedStudent = student;
    notifyListeners();
  }

  void clearSelectedStudent() {
    _selectedStudent = null;
    notifyListeners();
  }

  List<models.Student> getStudentsByGradeAndGroup(
    SchoolGrade grade,
    String group,
  ) {
    return _students
        .where(
          (student) =>
              student.grade == grade &&
              student.group.toLowerCase() == group.toLowerCase(),
        )
        .toList();
  }

  models.Student? findStudentByCURP(String curp) {
    try {
      return _students.firstWhere(
        (student) => student.curp.toLowerCase() == curp.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  models.Student? findStudentByInstitutionalId(String institutionalId) {
    try {
      return _students.firstWhere(
        (student) =>
            student.institutionalId.toLowerCase() ==
            institutionalId.toLowerCase(),
      );
    } catch (e) {
      return null;
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
    _students.clear();
    _selectedStudent = null;
    super.dispose();
  }
}

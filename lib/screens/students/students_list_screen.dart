import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/adaptive_navigation.dart';
import '../../core/constants.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final StudentService _studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;

  // Filtros
  SchoolGrade? _selectedGrade;
  String? _selectedGroup;
  bool _showActiveOnly =
      false; // Changed to false to show all students by default

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final students = await _studentService.getAllStudents();
      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
      });
      _filterStudents();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _students.where((student) {
        // Filtro de búsqueda por texto
        final query = _searchController.text.toLowerCase();
        final matchesSearch =
            query.isEmpty ||
            student.fullName.toLowerCase().contains(query) ||
            student.curp.toLowerCase().contains(query) ||
            student.enrollment.toLowerCase().contains(query) ||
            student.institutionalId.toLowerCase().contains(query);

        // Filtro por grado
        final matchesGrade =
            _selectedGrade == null || student.grade == _selectedGrade;

        // Filtro por grupo
        final matchesGroup =
            _selectedGroup == null ||
            student.group.toLowerCase() == _selectedGroup!.toLowerCase();

        // Filtro por estado activo
        final matchesActive = !_showActiveOnly || student.isActive;

        return matchesSearch && matchesGrade && matchesGroup && matchesActive;
      }).toList();

      // Ordenar por apellido
      _filteredStudents.sort((a, b) => a.lastName.compareTo(b.lastName));
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<SchoolGrade?>(
                initialValue: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Grado',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<SchoolGrade?>(
                    value: null,
                    child: Text('Todos los grados'),
                  ),
                  ...SchoolGrade.values.map(
                    (grade) => DropdownMenuItem(
                      value: grade,
                      child: Text(grade.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedGrade = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Grupo',
                  hintText: 'A, B, C...',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedGroup,
                onChanged: (value) {
                  setDialogState(() {
                    _selectedGroup = value.isEmpty ? null : value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Solo estudiantes activos'),
                value: _showActiveOnly,
                onChanged: (value) {
                  setDialogState(() {
                    _showActiveOnly = value ?? true;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedGrade = null;
                _selectedGroup = null;
                _showActiveOnly = true;
              });
              _filterStudents();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _filterStudents();
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStudentScreen()),
    );

    if (result == true) {
      _loadStudents();
    }
  }

  void _navigateToStudentDetail(Student student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailScreen(studentId: student.id),
      ),
    );

    if (result == true) {
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      currentRoute: AppConstants.studentsRoute,
      appBar: AppBar(
        title: const Text('Estudiantes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddStudent,
        tooltip: 'Agregar Estudiante',
        child: const Icon(Icons.add),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, CURP, matrícula...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  if (_selectedGrade != null ||
                      _selectedGroup != null ||
                      _showActiveOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (_selectedGrade != null)
                            Chip(
                              label: Text(
                                'Grado: ${_selectedGrade!.displayName}',
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedGrade = null;
                                });
                                _filterStudents();
                              },
                            ),
                          if (_selectedGroup != null)
                            Chip(
                              label: Text('Grupo: $_selectedGroup'),
                              onDeleted: () {
                                setState(() {
                                  _selectedGroup = null;
                                });
                                _filterStudents();
                              },
                            ),
                          if (_showActiveOnly)
                            Chip(
                              label: const Text('Solo activos'),
                              onDeleted: () {
                                setState(() {
                                  _showActiveOnly = false;
                                });
                                _filterStudents();
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Estadísticas rápidas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip(
                    'Total',
                    '${_filteredStudents.length}',
                    Colors.blue,
                  ),
                  _buildStatChip(
                    'Activos',
                    '${_filteredStudents.where((s) => s.isActive).length}',
                    Colors.green,
                  ),
                  _buildStatChip(
                    'Inactivos',
                    '${_filteredStudents.where((s) => !s.isActive).length}',
                    Colors.grey,
                  ),
                ],
              ),
            ),

            // Lista de estudiantes
            Expanded(
              child: _error != null
                  ? _buildErrorState()
                  : _filteredStudents.isEmpty
                  ? _buildEmptyState()
                  : _buildStudentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
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
            'Error al cargar estudiantes',
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
            onPressed: _loadStudents,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay estudiantes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron estudiantes con los filtros aplicados'
                : 'Aún no hay estudiantes registrados',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (_searchController.text.isEmpty)
            ElevatedButton.icon(
              onPressed: _navigateToAddStudent,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Primer Estudiante'),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: student.isActive
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          backgroundImage: student.profileImageUrl != null
              ? CachedNetworkImageProvider(student.profileImageUrl!)
              : null,
          child: student.profileImageUrl == null
              ? Icon(
                  Icons.person,
                  color: student.isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                )
              : null,
        ),
        title: Text(
          student.fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: student.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${student.gradeGroup} • Matrícula: ${student.enrollment}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thumb_up, size: 12, color: Colors.green),
                      const SizedBox(width: 2),
                      Text(
                        '${student.positiveReportsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thumb_down, size: 12, color: Colors.red),
                      const SizedBox(width: 2),
                      Text(
                        '${student.negativeReportsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!student.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'INACTIVO',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _navigateToStudentDetail(student);
                break;
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddStudentScreen(studentId: student.id),
                  ),
                ).then((result) {
                  if (result == true) _loadStudents();
                });
                break;
              case 'toggle_status':
                _toggleStudentStatus(student);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Ver detalle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: ListTile(
                leading: Icon(
                  student.isActive ? Icons.block : Icons.check_circle,
                  color: student.isActive ? Colors.red : Colors.green,
                ),
                title: Text(student.isActive ? 'Desactivar' : 'Activar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToStudentDetail(student),
      ),
    );
  }

  Future<void> _toggleStudentStatus(Student student) async {
    try {
      if (student.isActive) {
        await _studentService.deleteStudent(student.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estudiante desactivado'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Para reactivar, necesitaríamos un método específico
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad de reactivación en desarrollo'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }

      _loadStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

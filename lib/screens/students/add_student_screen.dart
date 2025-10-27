import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';
import '../../services/file_service.dart';
import '../../widgets/student_widgets.dart';
import '../../widgets/grade_photos_widget.dart';
import '../../widgets/app_drawer.dart';
import '../../core/constants.dart';

class AddStudentScreen extends StatefulWidget {
  final String? studentId;
  final Student? student;

  const AddStudentScreen({super.key, this.studentId, this.student});

  bool get isEditing => studentId != null || student != null;

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final StudentService _studentService = StudentService();

  late TabController _tabController;
  Student? _currentStudent;
  bool _isLoading = false;
  bool _isSaving = false;

  // Controladores para los tutores
  final List<Map<String, dynamic>> _guardians = [];

  // Taller selection
  String? _selectedTaller;
  bool _showOtroTallerField = false;

  XFile? _selectedProfileImage;

  // Grade-specific images
  XFile? _selectedGrade1Image;
  XFile? _selectedGrade2Image;
  XFile? _selectedGrade3Image;

  // CURP document
  PlatformFile? _selectedCurpDocument;
  XFile? _selectedCurpImage;
  String? _currentCurpDocumentUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStudent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    if (!widget.isEditing) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Student? student;

      if (widget.student != null) {
        student = widget.student;
      } else if (widget.studentId != null) {
        student = await _studentService.getStudentById(widget.studentId!);
      }

      if (student != null) {
        setState(() {
          _currentStudent = student;
          _guardians.clear();
          _guardians.addAll(
            student!.guardians
                .map(
                  (g) => {
                    'firstName': g.firstName,
                    'lastName': g.lastName,
                    'relationshipType': g.relationshipType,
                    'phoneNumber': g.phoneNumber ?? '',
                    'emergencyPhone': g.emergencyPhone ?? '',
                    'email': g.email ?? '',
                    'isPrimary': g.isPrimary,
                  },
                )
                .toList(),
          );

          // Initialize taller selection
          if (student.grupoTaller != null && student.grupoTaller!.isNotEmpty) {
            if (TallerOptions.talleres.contains(student.grupoTaller)) {
              _selectedTaller = student.grupoTaller;
              _showOtroTallerField = student.grupoTaller == 'Otro';
            } else {
              _selectedTaller = 'Otro';
              _showOtroTallerField = true;
            }
          }

          // Initialize CURP document URL
          _currentCurpDocumentUrl = student.curpDocumentUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estudiante: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final formData = _formKey.currentState!.value;

      // Helper function to parse numeric values safely
      int? parseInt(dynamic value) {
        if (value == null || value == '') return null;
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        return null;
      }

      double? parseDouble(dynamic value) {
        if (value == null || value == '') return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
      }

      // Crear el objeto Student
      final student = Student(
        id: _currentStudent?.id ?? '',
        curp: formData['curp'],
        institutionalId: formData['institutional_id'],
        enrollment: formData['enrollment'],
        firstName: formData['first_name'],
        lastName: formData['last_name'],
        middleName: formData['middle_name'],
        grade: formData['grade'],
        group: formData['group'],
        currentSchoolYear: formData['current_school_year'],
        positiveReportsCount: _currentStudent?.positiveReportsCount ?? 0,
        negativeReportsCount: _currentStudent?.negativeReportsCount ?? 0,
        profileImageUrl: _currentStudent?.profileImageUrl,
        isActive: formData['is_active'] ?? true,
        createdAt: _currentStudent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        guardians: _guardians
            .map(
              (g) => Guardian(
                id: '',
                studentId: '',
                firstName: g['firstName'],
                lastName: g['lastName'],
                relationshipType: g['relationshipType'],
                phoneNumber: g['phoneNumber'].isNotEmpty
                    ? g['phoneNumber']
                    : null,
                emergencyPhone: g['emergencyPhone'].isNotEmpty
                    ? g['emergencyPhone']
                    : null,
                email: g['email'].isNotEmpty ? g['email'] : null,
                isPrimary: g['isPrimary'],
                createdAt: DateTime.now(),
              ),
            )
            .toList(),
        // Campos adicionales
        cct: formData['cct'],
        turno: formData['turno'],
        sexo: formData['sexo'],
        birthDate: formData['birth_date'],
        numeroLista: parseInt(formData['numero_lista']),
        grupoTaller: formData['grupo_taller'] == 'Otro'
            ? formData['grupo_taller_otro']
            : formData['grupo_taller'],
        numeroListaTaller: parseInt(formData['numero_lista_taller']),
        situacion: formData['situacion'],
        repetidor: formData['repetidor'],
        fechaAlta: formData['fecha_alta'],
        fechaBaja: formData['fecha_baja'],
        motivoBaja: formData['motivo_baja'],
        discapacidad: formData['discapacidad'],
        indigena: formData['indigena'],
        nee: formData['nee'],
        usaer: formData['usaer'],
        beca: formData['beca'],
        calle: formData['calle'],
        numero: formData['numero'],
        colonia: formData['colonia'],
        localidad: formData['localidad'],
        municipio: formData['municipio'],
        telefono: formData['telefono'],
        codigoPostal: formData['codigo_postal'],
        tutor: formData['tutor'],
        nacionalidad: formData['nacionalidad'],
        primariaProcedencia: formData['primaria_procedencia'],
        promedioPrimaria: parseDouble(formData['promedio_primaria']),
        peso: parseDouble(formData['peso']),
        estatura: parseDouble(formData['estatura']),
        uniformeA: formData['uniforme_a'],
        uniformeB: formData['uniforme_b'],
        padre: formData['padre'],
        fechaPadre: formData['fecha_padre'],
        curpPadre: formData['curp_padre'],
        estudiosPadre: formData['estudios_padre'],
        madre: formData['madre'],
        fechaMadre: formData['fecha_madre'],
        curpMadre: formData['curp_madre'],
        estudiosMadre: formData['estudios_madre'],
      );

      Student savedStudent;
      if (widget.isEditing) {
        savedStudent = await _studentService.updateStudent(student);
      } else {
        savedStudent = await _studentService.createStudent(student);
      }

      // Subir imagen si se seleccionó una
      if (_selectedProfileImage != null) {
        try {
          debugPrint('Attempting to upload student profile image...');
          final imageUrl = await _studentService.updateStudentProfileImage(
            savedStudent.id,
            _selectedProfileImage!,
          );
          debugPrint('Image uploaded successfully: $imageUrl');
        } catch (imageError) {
          debugPrint('Error uploading image: $imageError');
          // Show warning but don't fail the entire save operation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Advertencia: Error al subir imagen - $imageError',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }

      // Subir imágenes por grado si se seleccionaron
      if (_selectedGrade1Image != null) {
        try {
          await _studentService.updateStudentGradeProfileImage(
            savedStudent.id,
            _selectedGrade1Image!,
            SchoolGrade.primero,
          );
        } catch (e) {
          debugPrint('Error uploading grade 1 image: $e');
        }
      }

      if (_selectedGrade2Image != null) {
        try {
          await _studentService.updateStudentGradeProfileImage(
            savedStudent.id,
            _selectedGrade2Image!,
            SchoolGrade.segundo,
          );
        } catch (e) {
          debugPrint('Error uploading grade 2 image: $e');
        }
      }

      if (_selectedGrade3Image != null) {
        try {
          await _studentService.updateStudentGradeProfileImage(
            savedStudent.id,
            _selectedGrade3Image!,
            SchoolGrade.tercero,
          );
        } catch (e) {
          debugPrint('Error uploading grade 3 image: $e');
        }
      }

      // Upload CURP document if selected
      if (_selectedCurpDocument != null || _selectedCurpImage != null) {
        try {
          final FileService fileService = FileService();
          String? curpDocumentUrl;

          if (_selectedCurpImage != null) {
            // Upload image from camera/gallery
            curpDocumentUrl = await fileService.uploadCurpImageFromXFile(
              _selectedCurpImage!,
              savedStudent.id,
            );
          } else if (_selectedCurpDocument != null) {
            // Upload document
            curpDocumentUrl = await fileService.uploadCurpDocument(
              _selectedCurpDocument!,
              savedStudent.id,
            );
          }

          if (curpDocumentUrl != null) {
            // Update student with CURP document URL and upload date
            await _studentService.updateStudent(
              savedStudent.copyWith(
                curpDocumentUrl: curpDocumentUrl,
                curpDocumentUploadDate: DateTime.now(),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error uploading CURP document: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Advertencia: Error al subir documento CURP - $e',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Estudiante actualizado correctamente'
                  : 'Estudiante creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar estudiante: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Show loading indicator while student data is being loaded in edit mode
    if (_isLoading && widget.isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        drawer: const AppDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar Estudiante' : 'Agregar Estudiante',
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveStudent,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: isDark
                  ? colorScheme.primary
                  : const Color.fromARGB(255, 158, 102, 29),
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: isDark
                  ? colorScheme.primary
                  : const Color.fromARGB(255, 158, 102, 29),
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Básico'),
                Tab(icon: Icon(Icons.family_restroom), text: 'Tutores'),
                Tab(icon: Icon(Icons.school), text: 'Académico'),
                Tab(icon: Icon(Icons.info), text: 'Adicional'),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: FormBuilder(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicTab(),
            _buildGuardiansTab(),
            _buildAcademicTab(),
            _buildAdditionalTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveStudent,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(widget.isEditing ? 'Actualizar' : 'Guardar'),
        backgroundColor: _isSaving
            ? Colors.grey
            : Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Foto de perfil
          Center(
            child: ProfileImageWidget(
              imageUrl: _currentStudent?.profileImageUrl,
              size: 120,
              isEditable: true,
              onImageSelected: (file) {
                setState(() {
                  _selectedProfileImage = file;
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          // Grade Photos (for editing)
          if (widget.isEditing && _currentStudent != null)
            GradePhotosWidget(
              student: _currentStudent!,
              isEditable: true,
              isCollapsible: true,
              initiallyExpanded: true,
              onImageSelected: (grade, file) {
                setState(() {
                  switch (grade) {
                    case SchoolGrade.primero:
                      _selectedGrade1Image = file;
                      break;
                    case SchoolGrade.segundo:
                      _selectedGrade2Image = file;
                      break;
                    case SchoolGrade.tercero:
                      _selectedGrade3Image = file;
                      break;
                  }
                });
              },
              onImageRemoved: (grade) async {
                try {
                  await _studentService.removeStudentGradeProfileImage(
                    _currentStudent!.id,
                    grade,
                  );
                  // Reload student to refresh UI
                  await _loadStudent();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto eliminada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar foto: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),

          const SizedBox(height: 16),

          // Información básica obligatoria
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Básica *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'curp',
                    initialValue: _currentStudent?.curp,
                    decoration: const InputDecoration(
                      labelText: 'CURP *',
                      hintText: 'Ej: ABCD123456HDFRRL09',
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.minLength(18),
                      FormBuilderValidators.maxLength(18),
                    ]),
                    textCapitalization: TextCapitalization.characters,
                  ),

                  const SizedBox(height: 16),

                  // CURP Document Upload Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documento CURP',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sube una foto o documento del CURP (para casos de cambio de CURP)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (_currentCurpDocumentUrl != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Documento actual subido',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                if (_currentStudent?.curpDocumentUploadDate !=
                                    null)
                                  Text(
                                    'Fecha: ${_currentStudent!.curpDocumentUploadDate!.day}/${_currentStudent!.curpDocumentUploadDate!.month}/${_currentStudent!.curpDocumentUploadDate!.year}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_selectedCurpDocument != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.description,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Nuevo documento: ${_selectedCurpDocument!.name}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCurpDocument = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_selectedCurpImage != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.image, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Nueva imagen seleccionada',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCurpImage = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickCurpFromCamera,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Cámara'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _pickCurpFromGallery,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Galería'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _pickCurpDocument,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Documento'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'institutional_id',
                    initialValue: _currentStudent?.institutionalId,
                    decoration: const InputDecoration(
                      labelText: 'Folio Institucional *',
                    ),
                    validator: FormBuilderValidators.required(),
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'enrollment',
                    initialValue: _currentStudent?.enrollment,
                    decoration: const InputDecoration(labelText: 'Matrícula *'),
                    validator: FormBuilderValidators.required(),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'first_name',
                          initialValue: _currentStudent?.firstName,
                          decoration: const InputDecoration(
                            labelText: 'Nombre(s) *',
                          ),
                          validator: FormBuilderValidators.required(),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'last_name',
                          initialValue: _currentStudent?.lastName,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos *',
                          ),
                          validator: FormBuilderValidators.required(),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'middle_name',
                    initialValue: _currentStudent?.middleName,
                    decoration: const InputDecoration(
                      labelText: 'Segundo Nombre',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información escolar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Escolar *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderDropdown<SchoolGrade>(
                          name: 'grade',
                          initialValue: _currentStudent?.grade,
                          decoration: const InputDecoration(
                            labelText: 'Grado *',
                          ),
                          validator: FormBuilderValidators.required(),
                          items: SchoolGrade.values
                              .map(
                                (grade) => DropdownMenuItem(
                                  value: grade,
                                  child: Text(grade.displayName),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'group',
                          initialValue: _currentStudent?.group,
                          decoration: const InputDecoration(
                            labelText: 'Grupo *',
                            hintText: 'A, B, C...',
                          ),
                          validator: FormBuilderValidators.required(),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'current_school_year',
                    initialValue:
                        _currentStudent?.currentSchoolYear ?? '2024-2025',
                    decoration: const InputDecoration(
                      labelText: 'Ciclo Escolar *',
                      hintText: '2024-2025',
                    ),
                    validator: FormBuilderValidators.required(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información personal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Personal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderDropdown<String>(
                          name: 'sexo',
                          initialValue: _currentStudent?.sexo,
                          decoration: const InputDecoration(labelText: 'Sexo'),
                          items: const [
                            DropdownMenuItem(
                              value: 'M',
                              child: Text('Masculino'),
                            ),
                            DropdownMenuItem(
                              value: 'F',
                              child: Text('Femenino'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderDateTimePicker(
                          name: 'birth_date',
                          initialValue: _currentStudent?.birthDate,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Nacimiento',
                          ),
                          inputType: InputType.date,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'nacionalidad',
                    initialValue: _currentStudent?.nacionalidad ?? 'Mexicana',
                    decoration: const InputDecoration(
                      labelText: 'Nacionalidad',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Estado
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderSwitch(
                    name: 'is_active',
                    initialValue: _currentStudent?.isActive ?? true,
                    title: const Text('Estudiante Activo'),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardiansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Lista de tutores
          if (_guardians.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.family_restroom,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay tutores agregados',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addGuardian,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Tutor'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._guardians.asMap().entries.map((entry) {
              final index = entry.key;
              final guardian = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tutor ${index + 1}${guardian['isPrimary'] ? ' (Principal)' : ''}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeGuardian(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: guardian['firstName'],
                              decoration: const InputDecoration(
                                labelText: 'Nombre *',
                              ),
                              onChanged: (value) {
                                guardian['firstName'] = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: guardian['lastName'],
                              decoration: const InputDecoration(
                                labelText: 'Apellidos *',
                              ),
                              onChanged: (value) {
                                guardian['lastName'] = value;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: guardian['relationshipType'],
                        decoration: const InputDecoration(
                          labelText: 'Relación *',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Padre',
                            child: Text('Padre'),
                          ),
                          DropdownMenuItem(
                            value: 'Madre',
                            child: Text('Madre'),
                          ),
                          DropdownMenuItem(
                            value: 'Tutor',
                            child: Text('Tutor'),
                          ),
                          DropdownMenuItem(
                            value: 'Abuelo',
                            child: Text('Abuelo'),
                          ),
                          DropdownMenuItem(
                            value: 'Abuela',
                            child: Text('Abuela'),
                          ),
                          DropdownMenuItem(value: 'Tío', child: Text('Tío')),
                          DropdownMenuItem(value: 'Tía', child: Text('Tía')),
                          DropdownMenuItem(
                            value: 'Hermano',
                            child: Text('Hermano'),
                          ),
                          DropdownMenuItem(
                            value: 'Hermana',
                            child: Text('Hermana'),
                          ),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          guardian['relationshipType'] = value;
                        },
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: guardian['phoneNumber'],
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                guardian['phoneNumber'] = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: guardian['emergencyPhone'],
                              decoration: const InputDecoration(
                                labelText: 'Teléfono Emergencia',
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                guardian['emergencyPhone'] = value;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: guardian['email'],
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          guardian['email'] = value;
                        },
                      ),

                      const SizedBox(height: 16),

                      CheckboxListTile(
                        title: const Text('Tutor Principal'),
                        value: guardian['isPrimary'],
                        onChanged: (value) {
                          setState(() {
                            // Solo puede haber un tutor principal
                            for (var g in _guardians) {
                              g['isPrimary'] = false;
                            }
                            guardian['isPrimary'] = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),

          // Botón para agregar tutor
          if (_guardians.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addGuardian,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Otro Tutor'),
              ),
            ),

          const SizedBox(height: 24),

          // Información de padres
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de Padres',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información del padre
                  Text(
                    'Padre',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  FormBuilderTextField(
                    name: 'padre',
                    initialValue: _currentStudent?.padre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Padre',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'curp_padre',
                    initialValue: _currentStudent?.curpPadre,
                    decoration: const InputDecoration(
                      labelText: 'CURP del Padre',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'estudios_padre',
                    initialValue: _currentStudent?.estudiosPadre,
                    decoration: const InputDecoration(
                      labelText: 'Estudios del Padre',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 24),

                  // Información de la madre
                  Text(
                    'Madre',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  FormBuilderTextField(
                    name: 'madre',
                    initialValue: _currentStudent?.madre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Madre',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'curp_madre',
                    initialValue: _currentStudent?.curpMadre,
                    decoration: const InputDecoration(
                      labelText: 'CURP de la Madre',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'estudios_madre',
                    initialValue: _currentStudent?.estudiosMadre,
                    decoration: const InputDecoration(
                      labelText: 'Estudios de la Madre',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Información académica
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Académica',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'primaria_procedencia',
                    initialValue: _currentStudent?.primariaProcedencia,
                    decoration: const InputDecoration(
                      labelText: 'Primaria de Procedencia',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'promedio_primaria',
                    initialValue: _currentStudent?.promedioPrimaria?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Promedio de Primaria',
                      hintText: '8.5',
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.min(5.0),
                      FormBuilderValidators.max(10.0),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Necesidades educativas especiales
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Necesidades Educativas Especiales',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'discapacidad',
                    initialValue: _currentStudent?.discapacidad,
                    decoration: const InputDecoration(
                      labelText: 'Discapacidad',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'nee',
                    initialValue: _currentStudent?.nee,
                    decoration: const InputDecoration(
                      labelText: 'NEE (Necesidades Educativas Especiales)',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'beca',
                    initialValue: _currentStudent?.beca,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Beca',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderCheckbox(
                    name: 'indigena',
                    initialValue: _currentStudent?.indigena ?? false,
                    title: const Text('Pertenece a grupo indígena'),
                  ),

                  FormBuilderCheckbox(
                    name: 'usaer',
                    initialValue: _currentStudent?.usaer ?? false,
                    title: const Text('Requiere apoyo USAER'),
                  ),

                  FormBuilderCheckbox(
                    name: 'repetidor',
                    initialValue: _currentStudent?.repetidor ?? false,
                    title: const Text('Es repetidor'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información física
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Física',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'peso',
                          initialValue: _currentStudent?.peso?.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            hintText: '45.5',
                          ),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.numeric(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'estatura',
                          initialValue: _currentStudent?.estatura?.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Estatura (cm)',
                            hintText: '150',
                          ),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.numeric(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'uniforme_a',
                          initialValue: _currentStudent?.uniformeA,
                          decoration: const InputDecoration(
                            labelText: 'Talla Uniforme A',
                            hintText: 'M, L, XL...',
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'uniforme_b',
                          initialValue: _currentStudent?.uniformeB,
                          decoration: const InputDecoration(
                            labelText: 'Talla Uniforme B',
                            hintText: 'M, L, XL...',
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Información escolar adicional
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Escolar Adicional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'cct',
                    initialValue: _currentStudent?.cct ?? '10DES0002V',
                    decoration: const InputDecoration(
                      labelText: 'CCT (Clave del Centro de Trabajo)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),

                  const SizedBox(height: 16),

                  FormBuilderDropdown<String>(
                    name: 'turno',
                    initialValue: _currentStudent?.turno,
                    decoration: const InputDecoration(labelText: 'Turno'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Matutino',
                        child: Text('Matutino'),
                      ),
                      DropdownMenuItem(
                        value: 'Vespertino',
                        child: Text('Vespertino'),
                      ),
                      DropdownMenuItem(
                        value: 'Nocturno',
                        child: Text('Nocturno'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'numero_lista',
                          initialValue: _currentStudent?.numeroLista
                              ?.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Número de Lista',
                          ),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.integer(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'situacion',
                          initialValue: _currentStudent?.situacion,
                          decoration: const InputDecoration(
                            labelText: 'Situación Economica',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FormBuilderDropdown<String>(
                    name: 'grupo_taller',
                    initialValue: _selectedTaller,
                    decoration: const InputDecoration(
                      labelText: 'Grupo Taller',
                      hintText: 'Seleccione un taller',
                    ),
                    items: TallerOptions.talleres
                        .map(
                          (taller) => DropdownMenuItem(
                            value: taller,
                            child: Text(taller),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTaller = value;
                        _showOtroTallerField = value == 'Otro';
                      });
                    },
                  ),

                  if (_showOtroTallerField) ...[
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'grupo_taller_otro',
                      initialValue:
                          _currentStudent?.grupoTaller != null &&
                              !TallerOptions.talleres.contains(
                                _currentStudent?.grupoTaller,
                              )
                          ? _currentStudent?.grupoTaller
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Especifique el taller',
                        hintText: 'Ingrese el nombre del taller',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: FormBuilderValidators.required(
                        errorText: 'Por favor especifique el taller',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información de contacto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de Contacto',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'calle',
                          initialValue: _currentStudent?.calle,
                          decoration: const InputDecoration(labelText: 'Calle'),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'numero',
                          initialValue: _currentStudent?.numero,
                          decoration: const InputDecoration(
                            labelText: 'Número',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'colonia',
                    initialValue: _currentStudent?.colonia,
                    decoration: const InputDecoration(labelText: 'Colonia'),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'localidad',
                          initialValue: _currentStudent?.localidad,
                          decoration: const InputDecoration(
                            labelText: 'Localidad',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'municipio',
                          initialValue: _currentStudent?.municipio,
                          decoration: const InputDecoration(
                            labelText: 'Municipio',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'codigo_postal',
                          initialValue: _currentStudent?.codigoPostal,
                          decoration: const InputDecoration(
                            labelText: 'Código Postal',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'telefono',
                          initialValue: _currentStudent?.telefono,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fechas importantes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fechas Importantes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderDateTimePicker(
                          name: 'fecha_alta',
                          initialValue: _currentStudent?.fechaAlta,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Alta',
                          ),
                          inputType: InputType.date,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderDateTimePicker(
                          name: 'fecha_baja',
                          initialValue: _currentStudent?.fechaBaja,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Baja',
                          ),
                          inputType: InputType.date,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'motivo_baja',
                    initialValue: _currentStudent?.motivoBaja,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de Baja',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addGuardian() {
    setState(() {
      _guardians.add({
        'firstName': '',
        'lastName': '',
        'relationshipType': 'Padre',
        'phoneNumber': '',
        'emergencyPhone': '',
        'email': '',
        'isPrimary': _guardians.isEmpty, // El primero es principal por defecto
      });
    });
  }

  void _removeGuardian(int index) {
    setState(() {
      _guardians.removeAt(index);
    });
  }

  // CURP Document Methods
  Future<void> _pickCurpFromCamera() async {
    try {
      final FileService fileService = FileService();
      final XFile? image = await fileService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedCurpImage = image;
          _selectedCurpDocument = null; // Clear document if image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCurpFromGallery() async {
    try {
      final FileService fileService = FileService();
      final XFile? image = await fileService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedCurpImage = image;
          _selectedCurpDocument = null; // Clear document if image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCurpDocument() async {
    try {
      final FileService fileService = FileService();
      final FilePickerResult? result = await fileService.pickDocument();
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedCurpDocument = result.files.first;
          _selectedCurpImage = null; // Clear image if document is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/student.dart';
import '../core/constants.dart';

/// Widget to display and manage student photos for each grade
class GradePhotosWidget extends StatefulWidget {
  final Student student;
  final bool isEditable;
  final Function(SchoolGrade, XFile?)? onImageSelected;
  final Function(SchoolGrade)? onImageRemoved;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const GradePhotosWidget({
    super.key,
    required this.student,
    this.isEditable = false,
    this.onImageSelected,
    this.onImageRemoved,
    this.isCollapsible = true,
    this.initiallyExpanded = false,
  });

  @override
  State<GradePhotosWidget> createState() => _GradePhotosWidgetState();
}

class _GradePhotosWidgetState extends State<GradePhotosWidget> {
  int _getPhotoCount() {
    int count = 0;
    if (widget.student.profileImageUrlGrade1 != null &&
        widget.student.profileImageUrlGrade1!.isNotEmpty) {
      count++;
    }
    if (widget.student.profileImageUrlGrade2 != null &&
        widget.student.profileImageUrlGrade2!.isNotEmpty) {
      count++;
    }
    if (widget.student.profileImageUrlGrade3 != null &&
        widget.student.profileImageUrlGrade3!.isNotEmpty) {
      count++;
    }
    return count;
  }

  Widget _buildGradePhotosRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildGradePhoto(
          context,
          SchoolGrade.primero,
          widget.student.profileImageUrlGrade1,
        ),
        _buildGradePhoto(
          context,
          SchoolGrade.segundo,
          widget.student.profileImageUrlGrade2,
        ),
        _buildGradePhoto(
          context,
          SchoolGrade.tercero,
          widget.student.profileImageUrlGrade3,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = _getPhotoCount();

    if (widget.isCollapsible) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(
              Icons.photo_library,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Fotos por Grado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$photoCount de 3 fotos agregadas',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            initiallyExpanded: widget.initiallyExpanded,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aquí puedes ver/agregar fotos del estudiante para cada grado escolar',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    _buildGradePhotosRow(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Non-collapsible version
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fotos por Grado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí puedes ver/agregar fotos del estudiante para cada grado escolar',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildGradePhotosRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGradePhoto(
    BuildContext context,
    SchoolGrade grade,
    String? imageUrl,
  ) {
    final isCurrentGrade = widget.student.grade == grade;
    final canEdit = widget.isEditable && _canEditGrade(grade);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isCurrentGrade
                      ? Theme.of(context).primaryColor
                      : canEdit
                      ? Colors.grey.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.2),
                  width: isCurrentGrade ? 3 : 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  // Photo circle
                  GestureDetector(
                    onTap: imageUrl != null
                        ? () => _showFullScreenImage(context, imageUrl, grade)
                        : null,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholder(grade, canEdit);
                                },
                              )
                            : _buildPlaceholder(grade, canEdit),
                      ),
                    ),
                  ),
                  // Grade label overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrentGrade
                            ? Theme.of(context).primaryColor
                            : canEdit
                            ? Colors.grey[700]
                            : Colors.grey[400],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                      child: Text(
                        grade.displayName.replaceAll(' -', '°'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isCurrentGrade
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Lock icon for grades that cannot be edited
                  if (!canEdit && widget.isEditable)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Action buttons
            if (canEdit)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imageUrl == null || imageUrl.isEmpty)
                    IconButton(
                      icon: const Icon(Icons.add_a_photo, size: 20),
                      onPressed: () => _pickImage(context, grade),
                      tooltip: 'Agregar foto',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _pickImage(context, grade),
                          tooltip: 'Cambiar foto',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeImage(context, grade),
                          tooltip: 'Eliminar foto',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                ],
              )
            else if (widget.isEditable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bloqueado',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Determines if a grade can be edited based on student's current grade
  bool _canEditGrade(SchoolGrade targetGrade) {
    // Can always edit current grade
    if (targetGrade == widget.student.grade) {
      return true;
    }

    // Can edit past grades (grades lower than current)
    final gradeOrder = {
      SchoolGrade.primero: 1,
      SchoolGrade.segundo: 2,
      SchoolGrade.tercero: 3,
    };

    final currentGradeNumber = gradeOrder[widget.student.grade] ?? 1;
    final targetGradeNumber = gradeOrder[targetGrade] ?? 1;

    return targetGradeNumber < currentGradeNumber;
  }

  Widget _buildPlaceholder(SchoolGrade grade, bool canEdit) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            canEdit ? Icons.person_outline : Icons.person_off_outlined,
            size: 40,
            color: canEdit ? Colors.grey[400] : Colors.grey[300],
          ),
          const SizedBox(height: 4),
          Text(
            'Sin foto',
            style: TextStyle(
              fontSize: 10,
              color: canEdit ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    String imageUrl,
    SchoolGrade grade,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Foto de ${grade.displayName.replaceAll(' -', '°')} Grado',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Error al cargar la imagen'),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage(BuildContext context, SchoolGrade grade) async {
    if (!_canEditGrade(grade)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes agregar fotos para ${grade.displayName.replaceAll(' -', '°')} grado. '
            'Solo puedes editar el grado actual (${widget.student.grade.displayName.replaceAll(' -', '°')}) '
            'o grados anteriores.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      try {
        final pickedFile = await ImagePicker().pickImage(
          source: result,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null && widget.onImageSelected != null) {
          widget.onImageSelected!(grade, pickedFile);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al seleccionar imagen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removeImage(BuildContext context, SchoolGrade grade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la foto de ${grade.displayName.replaceAll(' -', '°')} grado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onImageRemoved?.call(grade);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Compact version for displaying in lists
class GradePhotosCompactWidget extends StatelessWidget {
  final Student student;
  final VoidCallback? onTap;

  const GradePhotosCompactWidget({
    super.key,
    required this.student,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.photo_library,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fotos por Grado',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPhotosSummary(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniPhoto(student.profileImageUrlGrade1),
                const SizedBox(width: 4),
                _buildMiniPhoto(student.profileImageUrlGrade2),
                const SizedBox(width: 4),
                _buildMiniPhoto(student.profileImageUrlGrade3),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPhoto(String? imageUrl) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: 16, color: Colors.grey[500]);
                },
              )
            : Icon(Icons.person, size: 16, color: Colors.grey[500]),
      ),
    );
  }

  String _getPhotosSummary() {
    int count = 0;
    if (student.profileImageUrlGrade1 != null &&
        student.profileImageUrlGrade1!.isNotEmpty) {
      count++;
    }
    if (student.profileImageUrlGrade2 != null &&
        student.profileImageUrlGrade2!.isNotEmpty) {
      count++;
    }
    if (student.profileImageUrlGrade3 != null &&
        student.profileImageUrlGrade3!.isNotEmpty) {
      count++;
    }

    return '$count de 3 fotos agregadas';
  }
}

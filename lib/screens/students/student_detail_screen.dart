import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/student.dart';
import '../../providers/medical_provider.dart';
import '../../services/pdf_report_service.dart';
import '../../services/student_service.dart';
import '../../services/file_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/student_widgets.dart';
import '../../widgets/grade_photos_widget.dart';
import 'add_student_screen.dart';
import 'student_history_screen.dart';
import '../medical/medical_records_screen.dart';
import '../attitudes/attitude_list_screen.dart';
import '../conduct/conduct_list_screen.dart';
import '../bap/bap_list_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();
  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificado';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Student? _student;
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

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

  void _navigateToEdit() async {
    if (_student == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentScreen(studentId: _student!.id),
      ),
    );

    if (result == true) {
      _loadStudent();
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Fix localhost URLs to use the correct network IP for physical devices
  String _fixLocalhostUrl(String url) {
    if (!kIsWeb && (url.contains('localhost') || url.contains('127.0.0.1'))) {
      // Replace localhost with the local network IP
      const localNetworkIp = '192.168.100.11'; // Match your SUPABASE_URL_Phone
      return url
          .replaceAll('http://localhost:8000', 'http://$localNetworkIp:8000')
          .replaceAll('http://127.0.0.1:8000', 'http://$localNetworkIp:8000')
          .replaceAll('localhost', localNetworkIp)
          .replaceAll('127.0.0.1', localNetworkIp);
    }
    return url;
  }

  void _showFullScreenImage(BuildContext context) {
    if (_student?.profileImageUrl == null) return;

    // Fix localhost URLs for physical devices
    String correctedUrl = _fixLocalhostUrl(_student!.profileImageUrl!);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _student!.fullName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: Hero(
              tag: 'student_image_${_student!.id}',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child:
                    _student!.profileImageUrl != null &&
                        _student!.profileImageUrl!.isNotEmpty
                    ? Image.network(
                        correctedUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Error al cargar la imagen',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          );
                        },
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: Colors.white54, size: 100),
                          SizedBox(height: 16),
                          Text(
                            'Sin imagen de perfil',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePDFReport() async {
    if (_student == null) return;

    try {
      final pdfService = PDFReportService();

      // Mostrar diálogo de opciones
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Generar Reporte PDF'),
          content: const Text(
            'Selecciona el tipo de reporte que deseas generar:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'simple'),
              child: const Text('Reporte Simple'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'complete'),
              child: const Text('Reporte Completo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (result == null) return;

      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Generar PDF
      final pdfData = result == 'simple'
          ? await pdfService.generateSimpleStudentReport(_student!)
          : await pdfService.generateStudentReport(_student!);

      // Cerrar loading
      if (mounted) {
        Navigator.pop(context);
      }

      // Mostrar opciones de acción
      if (mounted) {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reporte Generado'),
            content: const Text('¿Qué deseas hacer con el reporte?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'share'),
                child: const Text('Compartir'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'print'),
                child: const Text('Imprimir'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'save'),
                child: const Text('Guardar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );

        if (action != null && mounted) {
          switch (action) {
            case 'share':
              await pdfService.sharePDF(
                pdfData,
                'reporte_${_student!.fullName.replaceAll(' ', '_')}.pdf',
              );
              break;
            case 'print':
              await pdfService.printPDF(pdfData);
              break;
            case 'save':
              final path = await pdfService.savePDFToDevice(
                pdfData,
                'reporte_${_student!.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF guardado en: $path'),
                  backgroundColor: Colors.green,
                ),
              );
              break;
          }
        }
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewCurpDocument() async {
    if (_student?.curpDocumentUrl == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get signed URL from Supabase storage
      final fileService = FileService();
      String? viewUrl = await fileService.getSignedUrl(
        _student!.curpDocumentUrl!,
        expiresIn: 3600, // 1 hour
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Use the signed URL, or fallback to original if null
      String correctedUrl = _fixLocalhostUrl(
        viewUrl ?? _student!.curpDocumentUrl!,
      );

      // Check if it's an image or document based on URL
      final isImage = correctedUrl.toLowerCase().contains(
        RegExp(r'\.(jpg|jpeg|png|gif|webp)'),
      );

      if (isImage) {
        // Show image in full screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Documento CURP',
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _downloadCurpDocument(correctedUrl),
                    tooltip: 'Descargar',
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    correctedUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error al cargar la imagen',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _downloadCurpDocument(correctedUrl),
                            child: const Text('Descargar documento'),
                          ),
                        ],
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // For PDFs and other documents, show options dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Documento CURP'),
            content: const Text('¿Qué deseas hacer con el documento?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _downloadCurpDocument(correctedUrl);
                },
                child: const Text('Descargar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openCurpDocumentInBrowser(correctedUrl);
                },
                child: const Text('Abrir en navegador'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadCurpDocument(String url) async {
    try {
      // Simply open the URL in browser for both web and mobile
      _openCurpDocumentInBrowser(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo documento...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openCurpDocumentInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el documento'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_student?.fullName ?? 'Detalle del Estudiante'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: _student != null
            ? PreferredSize(
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
                    unselectedLabelColor: colorScheme.onSurface.withOpacity(
                      0.6,
                    ),
                    indicatorColor: isDark
                        ? colorScheme.primary
                        : const Color.fromARGB(255, 158, 102, 29),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(icon: Icon(Icons.person), text: 'General'),
                      Tab(icon: Icon(Icons.family_restroom), text: 'Tutores'),
                      Tab(icon: Icon(Icons.school), text: 'Académico'),
                      Tab(icon: Icon(Icons.assessment), text: 'Reportes'),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _error != null
            ? _buildErrorState()
            : _student == null
            ? _buildNotFoundState()
            : _buildStudentDetail(),
      ),
      floatingActionButton: _student != null
          ? FloatingActionButton(
              onPressed: _navigateToEdit,
              tooltip: 'Editar estudiante',
              backgroundColor: isDark
                  ? colorScheme.primary
                  : const Color.fromARGB(255, 158, 102, 29),
              child: const Icon(Icons.edit), // Dark gray color for light theme
            )
          : null,
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
            'Error al cargar estudiante',
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
          SizedBox(height: 8),
          Text(
            'El estudiante solicitado no existe o no está disponible',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDetail() {
    return Column(
      children: [
        // Tabs con información detallada
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralTab(),
              _buildGuardiansTab(),
              _buildAcademicTab(),
              _buildReportsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          if (isSmallScreen)
            // Mobile layout - stacked vertically
            _buildMobileHeader()
          else
            // Desktop/Tablet layout - horizontal
            _buildDesktopHeader(),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        // Profile image and name
        Row(
          children: [
            GestureDetector(
              onTap: () => _showFullScreenImage(context),
              child: Hero(
                tag: 'student_image_${_student!.id}',
                child: ProfileImageWidget(
                  imageUrl: _student!.profileImageUrl,
                  size: 70,
                  isEditable: false,
                ),
              ),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _student!.gradeGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_student!.isActive ? Colors.green : Colors.grey)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _student!.isActive ? Icons.check_circle : Icons.cancel,
                color: _student!.isActive ? Colors.green : Colors.grey,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Statistics row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCompactStat(
              '',
              '',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_student!.positiveReportsCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Positivos',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              color: Colors.green,
            ),
            _buildCompactStat(
              '',
              '',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_student!.negativeReportsCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Negativos',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.medical_services, size: 18),
                label: const Text('Médico', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sentiment_satisfied, size: 18),
                label: const Text('Actitudes', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Foto de perfil
        GestureDetector(
          onTap: () => _showFullScreenImage(context),
          child: Hero(
            tag: 'student_image_${_student!.id}',
            child: ProfileImageWidget(
              imageUrl: _student!.profileImageUrl,
              size: 80,
              isEditable: false,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name and grade info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _student!.fullName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _student!.gradeGroup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status badge with label
        Row(
          children: [
            Text(
              'Estado: ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_student!.isActive ? Colors.green : Colors.grey)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _student!.isActive ? Icons.check_circle : Icons.cancel,
                color: _student!.isActive ? Colors.green : Colors.grey,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),

        // Statistics
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCompactStat(
              '',
              '',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reportes +',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_student!.positiveReportsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildCompactStat(
              '',
              '',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reportes - ',
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_student!.negativeReportsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(width: 12),

        // Action buttons column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => MedicalProvider(),
                        child: MedicalRecordsScreen(studentId: _student!.id),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.medical_services, size: 16),
                label: const Text('Médico', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 100,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AttitudeListScreen(studentId: _student!.id),
                    ),
                  );
                },
                icon: const Icon(Icons.sentiment_satisfied, size: 16),
                label: const Text('Actitudes', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactStat(
    String label,
    String value, {
    IconData? icon,
    Widget? leading,
    Color color = Colors.black,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null)
          leading
        else if (icon != null)
          Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header only in General tab
          _buildHeader(),
          const SizedBox(height: 16),

          // Grade Photos
          GradePhotosWidget(
            student: _student!,
            isEditable: false,
            isCollapsible: true,
            initiallyExpanded: false,
          ),

          // Información básica
          InfoCard(
            title: 'Información Básica',
            icon: Icons.person,
            child: Column(
              children: [
                InfoRow(
                  label: 'CURP',
                  customValue: Row(
                    children: [
                      Expanded(child: Text(_student!.curp)),
                      IconButton(
                        onPressed: () =>
                            _copyToClipboard(_student!.curp, 'CURP'),
                        icon: const Icon(Icons.copy, size: 16),
                      ),
                    ],
                  ),
                  isImportant: true,
                ),
                // CURP Document section
                if (_student!.curpDocumentUrl != null) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Documento CURP',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (_student!.curpDocumentUploadDate != null)
                                Text(
                                  'Subido: ${_formatDate(_student!.curpDocumentUploadDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _viewCurpDocument(),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Ver'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                ],
                InfoRow(
                  label: 'Folio Institucional',
                  value: _student!.institutionalId,
                  isImportant: true,
                ),
                InfoRow(
                  label: 'Matrícula',
                  value: _student!.enrollment,
                  isImportant: true,
                ),
                InfoRow(label: 'Sexo', value: _student!.sexo),
                InfoRow(
                  label: 'Fecha de Nacimiento',
                  value: _formatDate(_student!.birthDate),
                ),
                InfoRow(label: 'Nacionalidad', value: _student!.nacionalidad),
              ],
            ),
          ),

          // Información escolar
          InfoCard(
            title: 'Información Escolar',
            icon: Icons.school,
            child: Column(
              children: [
                InfoRow(label: 'CCT', value: _student!.cct),
                InfoRow(label: 'Turno', value: _student!.turno),
                InfoRow(
                  label: 'Ciclo Escolar',
                  value: _student!.currentSchoolYear,
                ),
                InfoRow(
                  label: 'Número de Lista',
                  value: _student!.numeroLista?.toString(),
                ),
                InfoRow(label: 'Grupo Taller', value: _student!.grupoTaller),
                InfoRow(
                  label: 'Situación Economica',
                  value: _student!.situacion,
                ),
                InfoRow(
                  label: 'Repetidor',
                  value: _student!.repetidor == true ? 'Sí' : 'No',
                ),
              ],
            ),
          ),

          // Información de contacto
          InfoCard(
            title: 'Información de Contacto',
            icon: Icons.contact_phone,
            child: Column(
              children: [
                InfoRow(label: 'Calle', value: _student!.calle),
                InfoRow(label: 'Número', value: _student!.numero),
                InfoRow(label: 'Colonia', value: _student!.colonia),
                InfoRow(label: 'Localidad', value: _student!.localidad),
                InfoRow(label: 'Municipio', value: _student!.municipio),
                InfoRow(label: 'Código Postal', value: _student!.codigoPostal),
                InfoRow(label: 'Teléfono', value: _student!.telefono),
              ],
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
          if (_student!.guardians.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay tutores registrados',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ..._student!.guardians.asMap().entries.map((entry) {
              final index = entry.key;
              final guardian = entry.value;

              return InfoCard(
                title:
                    'Tutor ${index + 1}${guardian.isPrimary ? ' (Principal)' : ''}',
                icon: Icons.person,
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Nombre',
                      value: guardian.fullName,
                      isImportant: true,
                    ),
                    InfoRow(
                      label: 'Relación',
                      value: guardian.relationshipType,
                    ),
                    InfoRow(label: 'Teléfono', value: guardian.phoneNumber),
                    InfoRow(
                      label: 'Teléfono Emergencia',
                      value: guardian.emergencyPhone,
                    ),
                    InfoRow(label: 'Email', value: guardian.email),
                    if (guardian.address != null)
                      InfoRow(
                        label: 'Dirección',
                        value: guardian.address!.fullAddress,
                      ),
                  ],
                ),
              );
            }),

          // Información de padres
          if (_student!.padre != null || _student!.madre != null) ...[
            InfoCard(
              title: 'Información de Padres',
              icon: Icons.family_restroom,
              child: Column(
                children: [
                  if (_student!.padre != null) ...[
                    InfoRow(
                      label: 'Padre',
                      value: _student!.padre,
                      isImportant: true,
                    ),
                    InfoRow(label: 'CURP Padre', value: _student!.curpPadre),
                    InfoRow(
                      label: 'Estudios Padre',
                      value: _student!.estudiosPadre,
                    ),
                    if (_student!.fechaPadre != null)
                      InfoRow(
                        label: 'Fecha Nac. Padre',
                        value: _formatDate(_student!.fechaPadre),
                      ),
                  ],
                  if (_student!.madre != null) ...[
                    const Divider(),
                    InfoRow(
                      label: 'Madre',
                      value: _student!.madre,
                      isImportant: true,
                    ),
                    InfoRow(label: 'CURP Madre', value: _student!.curpMadre),
                    InfoRow(
                      label: 'Estudios Madre',
                      value: _student!.estudiosMadre,
                    ),
                    if (_student!.fechaMadre != null)
                      InfoRow(
                        label: 'Fecha Nac. Madre',
                        value: _formatDate(_student!.fechaMadre),
                      ),
                  ],
                ],
              ),
            ),
          ],
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
          InfoCard(
            title: 'Información Académica',
            icon: Icons.school,
            child: Column(
              children: [
                InfoRow(
                  label: 'Primaria de Procedencia',
                  value: _student!.primariaProcedencia,
                ),
                InfoRow(
                  label: 'Promedio Primaria',
                  value: _student!.promedioPrimaria?.toString(),
                ),
              ],
            ),
          ),

          // Información especial
          InfoCard(
            title: 'Necesidades Educativas',
            icon: Icons.accessibility,
            child: Column(
              children: [
                InfoRow(label: 'Discapacidad', value: _student!.discapacidad),
                InfoRow(
                  label: 'Indígena',
                  value: _student!.indigena == true ? 'Sí' : 'No',
                ),
                InfoRow(label: 'NEE', value: _student!.nee),
                InfoRow(
                  label: 'USAER',
                  value: _student!.usaer == true ? 'Sí' : 'No',
                ),
                InfoRow(label: 'Beca', value: _student!.beca),
              ],
            ),
          ),

          // Información física
          InfoCard(
            title: 'Información Física',
            icon: Icons.monitor_weight,
            child: Column(
              children: [
                InfoRow(
                  label: 'Peso',
                  value: _student!.peso != null ? '${_student!.peso} kg' : null,
                ),
                InfoRow(
                  label: 'Estatura',
                  value: _student!.estatura != null
                      ? '${_student!.estatura} cm'
                      : null,
                ),
                InfoRow(label: 'Uniforme A', value: _student!.uniformeA),
                InfoRow(label: 'Uniforme B', value: _student!.uniformeB),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Estadísticas de reportes
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

          const SizedBox(height: 16),

          // Quick access buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acceso Rápido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ConductListScreen(studentId: _student!.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment),
                          label: const Text('Conducta'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BAPListScreen(studentId: _student!.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.psychology),
                          label: const Text('BAP'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información de fechas
          InfoCard(
            title: 'Información de Registro',
            icon: Icons.date_range,
            child: Column(
              children: [
                InfoRow(
                  label: 'Fecha de Alta',
                  value: _formatDate(_student!.fechaAlta),
                ),
                InfoRow(
                  label: 'Fecha de Baja',
                  value: _formatDate(_student!.fechaBaja),
                ),
                InfoRow(label: 'Motivo de Baja', value: _student!.motivoBaja),
                InfoRow(
                  label: 'Fecha de Creación',
                  value: _formatDate(_student!.createdAt),
                ),
                InfoRow(
                  label: 'Última Actualización',
                  value: _student!.updatedAt != null
                      ? _formatDate(_student!.updatedAt!)
                      : 'No actualizado',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  text: 'Ver Historial Completo',
                  icon: Icons.history,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentHistoryScreen(studentId: _student!.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ActionButton(
                  text: 'Generar Reporte',
                  icon: Icons.picture_as_pdf,
                  onPressed: () => _generatePDFReport(),
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

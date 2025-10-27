import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import 'database_service.dart';

class FileService {
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  static const Uuid _uuid = Uuid();

  // Buckets de Supabase Storage
  static const String studentProfileImagesBucket = 'student-profile-images';
  static const String documentsBucket = 'documents';
  static const String signaturesBucket = 'signatures';
  static const String reportAttachmentsBucket = 'report-attachments';
  static const String curpDocumentsBucket =
      'documents'; // Using documents bucket for CURP documents

  // ***** IMÁGENES *****

  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<String?> uploadStudentProfileImage(
    XFile imageFile,
    String studentId,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Get file extension - works on both web and mobile
      String fileExt = 'jpg'; // default
      if (imageFile.name.isNotEmpty) {
        final nameParts = imageFile.name.split('.');
        if (nameParts.length > 1) {
          fileExt = nameParts.last.toLowerCase();
        }
      }

      // Determine content type
      String contentType = 'image/jpeg'; // default
      if (imageFile.mimeType != null) {
        contentType = imageFile.mimeType!;
      } else {
        // Fallback based on extension
        switch (fileExt) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
        }
      }

      final fileName = '$studentId.$fileExt';
      final filePath = fileName;

      debugPrint(
        'Uploading image to bucket: $studentProfileImagesBucket, path: $filePath, contentType: $contentType',
      );

      await _databaseService.client.storage
          .from(studentProfileImagesBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final imageUrl = _databaseService.client.storage
          .from(studentProfileImagesBucket)
          .getPublicUrl(filePath);

      debugPrint('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading student profile image: $e');
      rethrow;
    }
  }

  Future<String?> uploadStudentGradeProfileImage(
    XFile imageFile,
    String studentId,
    dynamic grade, // Can be SchoolGrade enum
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Get file extension - works on both web and mobile
      String fileExt = 'jpg'; // default
      if (imageFile.name.isNotEmpty) {
        final nameParts = imageFile.name.split('.');
        if (nameParts.length > 1) {
          fileExt = nameParts.last.toLowerCase();
        }
      }

      // Determine content type
      String contentType = 'image/jpeg'; // default
      if (imageFile.mimeType != null) {
        contentType = imageFile.mimeType!;
      } else {
        // Fallback based on extension
        switch (fileExt) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
        }
      }

      // Get grade name for file path
      String gradeName = grade.toString().split('.').last; // e.g., "primero"
      final fileName = '${studentId}_grade_$gradeName.$fileExt';
      final filePath = fileName;

      debugPrint(
        'Uploading grade image to bucket: $studentProfileImagesBucket, path: $filePath, contentType: $contentType',
      );

      await _databaseService.client.storage
          .from(studentProfileImagesBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final imageUrl = _databaseService.client.storage
          .from(studentProfileImagesBucket)
          .getPublicUrl(filePath);

      debugPrint('Grade image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading student grade profile image: $e');
      rethrow;
    }
  }

  Future<String?> uploadSignatureImage(XFile imageFile, String reportId) async {
    try {
      final bytes = await imageFile.readAsBytes();

      if (!_isValidImageSize(bytes)) {
        throw Exception(
          'La imagen es demasiado grande. Máximo ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB',
        );
      }

      // Get file extension from name instead of path (works on web)
      String extension = 'jpg'; // default
      if (imageFile.name.isNotEmpty) {
        final nameParts = imageFile.name.split('.');
        if (nameParts.length > 1) {
          extension = nameParts.last.toLowerCase();
        }
      }

      if (!AppConstants.allowedImageFormats.contains(extension)) {
        throw Exception('Formato de imagen no permitido');
      }

      final fileName = 'signature_${reportId}_${_uuid.v4()}.$extension';
      final path = 'signatures/$fileName';

      return await _databaseService.uploadFile(signaturesBucket, path, bytes);
    } catch (e) {
      debugPrint('Error uploading signature: $e');
      throw Exception('Error al subir firma: ${e.toString()}');
    }
  }

  // ***** DOCUMENTOS *****

  Future<FilePickerResult?> pickDocument() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...AppConstants.allowedDocumentFormats,
          ...AppConstants.allowedImageFormats,
        ],
        allowMultiple: false,
      );
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }

  Future<FilePickerResult?> pickMultipleDocuments() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...AppConstants.allowedDocumentFormats,
          ...AppConstants.allowedImageFormats,
        ],
        allowMultiple: true,
      );
    } catch (e) {
      debugPrint('Error picking documents: $e');
      return null;
    }
  }

  Future<String?> uploadDocument(PlatformFile file, String folder) async {
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = file.bytes;
      } else {
        if (file.path == null) throw Exception('Ruta de archivo no válida');
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) throw Exception('No se pudo leer el archivo');

      if (!_isValidFileSize(bytes)) {
        throw Exception(
          'El archivo es demasiado grande. Máximo ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB',
        );
      }

      final extension = file.extension?.toLowerCase() ?? '';
      final allowedFormats = [
        ...AppConstants.allowedDocumentFormats,
        ...AppConstants.allowedImageFormats,
      ];

      if (!allowedFormats.contains(extension)) {
        throw Exception('Formato de archivo no permitido');
      }

      final fileName = '${_uuid.v4()}_${file.name}';
      final path = '$folder/$fileName';

      return await _databaseService.uploadFile(documentsBucket, path, bytes);
    } catch (e) {
      debugPrint('Error uploading document: $e');
      throw Exception('Error al subir documento: ${e.toString()}');
    }
  }

  Future<List<String>> uploadMultipleDocuments(
    List<PlatformFile> files,
    String folder,
  ) async {
    final uploadedUrls = <String>[];

    for (final file in files) {
      try {
        final url = await uploadDocument(file, folder);
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        debugPrint('Error uploading file ${file.name}: $e');
        // Continuar con los demás archivos
      }
    }

    return uploadedUrls;
  }

  // ***** ADJUNTOS DE REPORTES *****

  Future<String?> uploadReportAttachment(
    PlatformFile file,
    String reportId,
  ) async {
    try {
      final folder = 'reports/$reportId';
      return await uploadDocument(file, folder);
    } catch (e) {
      debugPrint('Error uploading report attachment: $e');
      throw Exception('Error al subir adjunto: ${e.toString()}');
    }
  }

  // ***** DOCUMENTOS CURP *****

  /// Sube un documento CURP para un estudiante
  /// Puede ser imagen o documento PDF
  Future<String?> uploadCurpDocument(
    PlatformFile file,
    String studentId,
  ) async {
    try {
      final folder = 'curp-documents/$studentId';
      return await uploadDocument(file, folder);
    } catch (e) {
      debugPrint('Error uploading CURP document: $e');
      throw Exception('Error al subir documento CURP: ${e.toString()}');
    }
  }

  /// Sube una imagen CURP desde XFile (para cámara o galería)
  Future<String?> uploadCurpImageFromXFile(
    XFile imageFile,
    String studentId,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Get file extension
      String fileExt = 'jpg'; // default
      if (imageFile.name.isNotEmpty) {
        final nameParts = imageFile.name.split('.');
        if (nameParts.length > 1) {
          fileExt = nameParts.last.toLowerCase();
        }
      }

      // Determine content type
      String contentType = 'image/jpeg'; // default
      if (imageFile.mimeType != null) {
        contentType = imageFile.mimeType!;
      } else {
        switch (fileExt) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
        }
      }

      final fileName = 'curp_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'curp-documents/$studentId/$fileName';

      await _databaseService.client.storage
          .from(documentsBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final imageUrl = _databaseService.client.storage
          .from(documentsBucket)
          .getPublicUrl(filePath);

      debugPrint('CURP image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading CURP image: $e');
      rethrow;
    }
  }

  // ***** VALIDACIONES *****

  bool _isValidImageSize(Uint8List bytes) {
    return bytes.length <= AppConstants.maxFileSize;
  }

  bool _isValidFileSize(Uint8List bytes) {
    return bytes.length <= AppConstants.maxFileSize;
  }

  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return AppConstants.allowedImageFormats.contains(extension);
  }

  bool isDocumentFile(String fileName) {
    final extension = getFileExtension(fileName);
    return AppConstants.allowedDocumentFormats.contains(extension);
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // ***** ELIMINACIÓN *****

  Future<void> deleteFile(String url) async {
    try {
      // Extraer bucket y path de la URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3) {
        final bucket = pathSegments[pathSegments.length - 3];
        final path = pathSegments.sublist(pathSegments.length - 2).join('/');

        await _databaseService.deleteFile(bucket, path);
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
      // No lanzar excepción para no interrumpir otros procesos
    }
  }

  // ***** DOCUMENTOS MÉDICOS *****

  /// Subir documentos médicos a la carpeta de diagnósticos
  Future<String?> uploadMedicalDiagnosisDocument(
    PlatformFile file,
    String medicalRecordId,
    String diagnosisId,
  ) async {
    try {
      final folder = 'medical/$medicalRecordId/diagnoses/$diagnosisId';
      return await uploadDocument(file, folder);
    } catch (e) {
      debugPrint('Error uploading diagnosis document: $e');
      throw Exception(
        'Error al subir documento del diagnóstico: ${e.toString()}',
      );
    }
  }

  /// Subir documentos médicos a la carpeta de seguimientos
  Future<String?> uploadMedicalFollowUpDocument(
    PlatformFile file,
    String medicalRecordId,
    String followUpId,
  ) async {
    try {
      final folder = 'medical/$medicalRecordId/follow-ups/$followUpId';
      return await uploadDocument(file, folder);
    } catch (e) {
      debugPrint('Error uploading follow-up document: $e');
      throw Exception(
        'Error al subir documento del seguimiento: ${e.toString()}',
      );
    }
  }

  /// Subir múltiples documentos médicos para diagnóstico
  Future<List<String>> uploadMedicalDiagnosisDocuments(
    List<PlatformFile> files,
    String medicalRecordId,
    String diagnosisId,
  ) async {
    final uploadedUrls = <String>[];

    for (final file in files) {
      try {
        final url = await uploadMedicalDiagnosisDocument(
          file,
          medicalRecordId,
          diagnosisId,
        );
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        debugPrint('Error uploading file ${file.name}: $e');
        // Continuar con los demás archivos
      }
    }

    return uploadedUrls;
  }

  /// Subir múltiples documentos médicos para seguimiento
  Future<List<String>> uploadMedicalFollowUpDocuments(
    List<PlatformFile> files,
    String medicalRecordId,
    String followUpId,
  ) async {
    final uploadedUrls = <String>[];

    for (final file in files) {
      try {
        final url = await uploadMedicalFollowUpDocument(
          file,
          medicalRecordId,
          followUpId,
        );
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        debugPrint('Error uploading file ${file.name}: $e');
        // Continuar con los demás archivos
      }
    }

    return uploadedUrls;
  }

  /// Obtener URL firmada para acceder a un documento privado
  Future<String?> getSignedUrl(String url, {int expiresIn = 3600}) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the bucket and path from the URL
      // URL format: .../storage/v1/object/{access-type}/{bucket}/{path}
      final objectIndex = pathSegments.indexOf('object');
      if (objectIndex == -1 || objectIndex + 2 >= pathSegments.length) {
        throw Exception('Invalid URL format');
      }

      final bucket = pathSegments[objectIndex + 2];
      final filePath = pathSegments.sublist(objectIndex + 3).join('/');

      // Create signed URL
      final signedUrl = await _databaseService.client.storage
          .from(bucket)
          .createSignedUrl(filePath, expiresIn);

      return signedUrl;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }

  /// Obtener URL firmada para firma de padre/tutor
  /// Returns a signed URL that expires in 1 hour (default) for signature images
  Future<String?> getSignedSignatureUrl(String signatureUrl) async {
    try {
      // Try to parse and extract path from the URL
      final extractedInfo = extractBucketAndPath(signatureUrl);

      if (extractedInfo != null) {
        final bucket = extractedInfo['bucket']!;
        final filePath = extractedInfo['path']!;

        // Create signed URL valid for 1 hour
        final signedUrl = await _databaseService.client.storage
            .from(bucket)
            .createSignedUrl(filePath, 3600);

        return signedUrl;
      }

      // If URL doesn't match expected format, try direct approach
      // Assume it's in signatures bucket
      if (signatureUrl.contains('signatures/')) {
        final pathMatch = RegExp(r'signatures/(.+)$').firstMatch(signatureUrl);
        if (pathMatch != null) {
          final filePath = 'signatures/${pathMatch.group(1)}';
          final signedUrl = await _databaseService.client.storage
              .from(signaturesBucket)
              .createSignedUrl(filePath, 3600);
          return signedUrl;
        }
      }

      // Last resort: return original URL (might work if bucket is public)
      return signatureUrl;
    } catch (e) {
      debugPrint('Error getting signed signature URL: $e');
      // Return original URL as fallback
      return signatureUrl;
    }
  }

  /// Extraer información del bucket y path desde una URL de Supabase
  Map<String, String>? extractBucketAndPath(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      final objectIndex = pathSegments.indexOf('object');
      if (objectIndex == -1 || objectIndex + 2 >= pathSegments.length) {
        return null;
      }

      final bucket = pathSegments[objectIndex + 2];
      final filePath = pathSegments.sublist(objectIndex + 3).join('/');

      return {'bucket': bucket, 'path': filePath};
    } catch (e) {
      debugPrint('Error extracting bucket and path: $e');
      return null;
    }
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/final_report.dart';
import '../models/conduct_report.dart';
import '../core/constants.dart';
import 'database_service.dart';

class PDFReportService {
  static final PDFReportService _instance = PDFReportService._internal();
  factory PDFReportService() => _instance;
  PDFReportService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Genera un reporte completo del estudiante en PDF
  Future<Uint8List> generateStudentReport(Student student) async {
    final pdf = pw.Document();

    // Cargar fuente
    final fontData = await PdfGoogleFonts.notoSansRegular();
    final boldFontData = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(student, boldFontData),
            pw.SizedBox(height: 20),
            _buildBasicInfo(student, fontData, boldFontData),
            pw.SizedBox(height: 20),
            _buildGuardiansInfo(student, fontData, boldFontData),
            pw.SizedBox(height: 20),
            _buildAcademicInfo(student, fontData, boldFontData),
            pw.SizedBox(height: 20),
            _buildReportsInfo(student, fontData, boldFontData),
            pw.SizedBox(height: 20),
            _buildFooter(fontData),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Genera un reporte simplificado del estudiante
  Future<Uint8List> generateSimpleStudentReport(Student student) async {
    final pdf = pw.Document();

    // Cargar fuente
    final fontData = await PdfGoogleFonts.notoSansRegular();
    final boldFontData = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(student, boldFontData),
              pw.SizedBox(height: 20),
              _buildBasicInfo(student, fontData, boldFontData),
              pw.SizedBox(height: 20),
              _buildReportsSummary(student, fontData, boldFontData),
              pw.Spacer(),
              _buildFooter(fontData),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Guarda el PDF en el dispositivo
  Future<String> savePDFToDevice(Uint8List pdfData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfData);
      return file.path;
    } catch (e) {
      throw Exception('Error al guardar PDF: $e');
    }
  }

  /// Comparte el PDF
  Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    try {
      await Printing.sharePdf(bytes: pdfData, filename: fileName);
    } catch (e) {
      throw Exception('Error al compartir PDF: $e');
    }
  }

  /// Imprime el PDF
  Future<void> printPDF(Uint8List pdfData) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
      );
    } catch (e) {
      throw Exception('Error al imprimir PDF: $e');
    }
  }

  // Métodos privados para construir secciones del PDF

  pw.Widget _buildHeader(Student student, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'REPORTE DE ESTUDIANTE',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 20,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            student.fullName,
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.Text(
            '${student.gradeGroup} • ${student.enrollment}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado: ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBasicInfo(Student student, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMACIÓN BÁSICA',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('CURP:', student.curp, font, boldFont),
              _buildInfoRow(
                'Folio Institucional:',
                student.institutionalId,
                font,
                boldFont,
              ),
              _buildInfoRow('Matrícula:', student.enrollment, font, boldFont),
              _buildInfoRow(
                'Ciclo Escolar:',
                student.currentSchoolYear,
                font,
                boldFont,
              ),
              _buildInfoRow(
                'Sexo:',
                student.sexo ?? 'No especificado',
                font,
                boldFont,
              ),
              _buildInfoRow(
                'Fecha de Nacimiento:',
                _formatDate(student.birthDate),
                font,
                boldFont,
              ),
              _buildInfoRow(
                'Nacionalidad:',
                student.nacionalidad ?? 'No especificada',
                font,
                boldFont,
              ),
              _buildInfoRow(
                'Estado:',
                student.isActive ? 'Activo' : 'Inactivo',
                font,
                boldFont,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildGuardiansInfo(
    Student student,
    pw.Font font,
    pw.Font boldFont,
  ) {
    if (student.guardians.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMACIÓN DE TUTORES',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        ...student.guardians.asMap().entries.map((entry) {
          final index = entry.key;
          final guardian = entry.value;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Tutor ${index + 1}${guardian.isPrimary ? ' (Principal)' : ''}',
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                _buildInfoRow('Nombre:', guardian.fullName, font, boldFont),
                _buildInfoRow(
                  'Relación:',
                  guardian.relationshipType,
                  font,
                  boldFont,
                ),
                _buildInfoRow(
                  'Teléfono:',
                  guardian.phoneNumber ?? 'No especificado',
                  font,
                  boldFont,
                ),
                _buildInfoRow(
                  'Email:',
                  guardian.email ?? 'No especificado',
                  font,
                  boldFont,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildAcademicInfo(
    Student student,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMACIÓN ACADÉMICA',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow(
                'Primaria de Procedencia:',
                student.primariaProcedencia ?? 'No especificada',
                font,
                boldFont,
              ),
              _buildInfoRow(
                'Promedio de Primaria:',
                student.promedioPrimaria?.toString() ?? 'No especificado',
                font,
                boldFont,
              ),
              _buildInfoRow('NEE:', student.nee ?? 'Ninguna', font, boldFont),
              _buildInfoRow(
                'Discapacidad:',
                student.discapacidad ?? 'Ninguna',
                font,
                boldFont,
              ),
              _buildInfoRow('Beca:', student.beca ?? 'Ninguna', font, boldFont),
              _buildInfoRow(
                'USAER:',
                student.usaer == true ? 'Sí' : 'No',
                font,
                boldFont,
              ),
              _buildInfoRow(
                'Repetidor:',
                student.repetidor == true ? 'Sí' : 'No',
                font,
                boldFont,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReportsInfo(Student student, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMACIÓN DE REPORTES',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${student.positiveReportsCount}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 24,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'Reportes Positivos',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${student.negativeReportsCount}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 24,
                          color: PdfColors.red800,
                        ),
                      ),
                      pw.Text(
                        'Reportes Negativos',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReportsSummary(
    Student student,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RESUMEN DE REPORTES',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${student.positiveReportsCount}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 32,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Text(
                      'Reportes Positivos',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 12,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${student.negativeReportsCount}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 32,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.Text(
                      'Reportes Negativos',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 12,
                        color: PdfColors.red800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Generado por ${AppConstants.appName} v${AppConstants.appVersion}',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Este documento es oficial y contiene información confidencial',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificado';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Genera el PDF del Informe Final (completo)
  Future<String> generateFinalReportPDF(FinalReport report) async {
    try {
      final pdf = pw.Document();

      // Cargar fuentes
      final fontData = await PdfGoogleFonts.notoSansRegular();
      final boldFontData = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildFinalReportHeader(report, boldFontData),
              pw.SizedBox(height: 20),
              _buildStudentSummarySection(
                report.studentSummary,
                report.schoolYear,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 20),
              _buildConductualSection(
                report.conductualSummary,
                report.conductLetter,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 20),
              _buildBAPSection(report.bapSummary, fontData, boldFontData),
              pw.SizedBox(height: 20),
              _buildMedicalSection(
                report.medicalSummary,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 20),
              _buildAttitudesSection(
                report.attitudesSummary,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 20),
              _buildRecommendationsSection(
                report.recommendations,
                report.opportunities,
                report.strengths,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 20),
              _buildReportFooter(report, fontData),
            ];
          },
        ),
      );

      // Guardar PDF en Supabase Storage
      final pdfData = await pdf.save();
      final fileName =
          'informe_final_${report.studentId}_${report.schoolYear}.pdf';

      return await _uploadPDFToStorage(pdfData, fileName, 'final-reports');
    } catch (e) {
      throw Exception('Error generando PDF de Informe Final: $e');
    }
  }

  /// Genera el PDF de la Ficha Pedagógica (versión resumida)
  Future<String> generateFichaPedagogicaPDF(FinalReport report) async {
    try {
      final pdf = pw.Document();

      // Cargar fuentes
      final fontData = await PdfGoogleFonts.notoSansRegular();
      final boldFontData = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildFichaPedagogicaHeader(report, boldFontData),
              pw.SizedBox(height: 20),
              _buildFichaStudentInfo(
                report.studentSummary,
                report.schoolYear,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 20),
              _buildFichaConductSummary(
                report.conductualSummary,
                report.conductLetter,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 15),
              _buildFichaBAPSummary(report.bapSummary, fontData, boldFontData),
              pw.SizedBox(height: 15),
              _buildFichaMedicalSummary(
                report.medicalSummary,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 15),
              _buildFichaAttitudesSummary(
                report.attitudesSummary,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 15),
              _buildFichaRecommendations(
                report.recommendations,
                report.strengths,
                fontData,
                boldFontData,
              ),
              pw.SizedBox(height: 20),
              _buildReportFooter(report, fontData),
            ];
          },
        ),
      );

      // Guardar PDF en Supabase Storage
      final pdfData = await pdf.save();
      final fileName =
          'ficha_pedagogica_${report.studentId}_${report.schoolYear}.pdf';

      return await _uploadPDFToStorage(pdfData, fileName, 'final-reports');
    } catch (e) {
      throw Exception('Error generando PDF de Ficha Pedagógica: $e');
    }
  }

  // ========== MÉTODOS PRIVADOS PARA INFORME FINAL ==========

  pw.Widget _buildFinalReportHeader(FinalReport report, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue700,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORME FINAL',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            report.studentSummary.fullName,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'Ciclo Escolar: ${report.schoolYear}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
          ),
          pw.Text(
            'Generado: ${_formatDate(report.generationDate)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStudentSummarySection(
    StudentSummary student,
    String schoolYear,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('INFORMACIÓN DEL ESTUDIANTE', boldFont),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('CURP:', student.curp, font, boldFont),
              _buildInfoRow(
                'Folio Institucional:',
                student.institutionalId,
                font,
                boldFont,
              ),
              _buildInfoRow('Matrícula:', student.enrollment, font, boldFont),
              _buildInfoRow(
                'Grado y Grupo:',
                '${student.grade} ${student.group}',
                font,
                boldFont,
              ),
              _buildInfoRow('Ciclo Escolar:', schoolYear, font, boldFont),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildConductualSection(
    ConductualSummary summary,
    ConductLetter letter,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('RESUMEN CONDUCTUAL', boldFont),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildStatCard(
                      'Reportes Positivos',
                      summary.totalPositiveReports.toString(),
                      PdfColors.green100,
                      PdfColors.green800,
                      boldFont,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _buildStatCard(
                      'Reportes Negativos',
                      summary.totalNegativeReports.toString(),
                      PdfColors.red100,
                      PdfColors.red800,
                      boldFont,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              _buildInfoRow(
                'Clasificación de Conducta:',
                _getConductClassificationText(letter.classification),
                font,
                boldFont,
              ),
              if (summary.severityBreakdown.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Desglose por Severidad:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                ...summary.severityBreakdown.entries.map(
                  (entry) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, top: 2),
                    child: pw.Text(
                      '• ${_formatSeverity(entry.key)}: ${entry.value}',
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ),
                ),
              ],
              if (summary.highlightedIncidents.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Incidentes Destacados:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                ...summary.highlightedIncidents
                    .take(3)
                    .map(
                      (incident) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              incident.title,
                              style: pw.TextStyle(font: boldFont, fontSize: 9),
                            ),
                            pw.Text(
                              _formatDate(incident.date),
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              if (letter.summary.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Resumen:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.Text(
                  letter.summary,
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBAPSection(
    BAPSummary summary,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('BARRERAS DE APRENDIZAJE Y PARTICIPACIÓN', boldFont),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'BAP Activas:',
                summary.totalActiveBAP.toString(),
                font,
                boldFont,
              ),
              if (summary.bapTypeBreakdown.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Desglose por Tipo:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                ...summary.bapTypeBreakdown.entries.map(
                  (entry) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, top: 2),
                    child: pw.Text(
                      '• ${entry.key}: ${entry.value}',
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ),
                ),
              ],
              if (summary.evolutionSummary.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Evolución de BAP:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                ...summary.evolutionSummary.map(
                  (evolution) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            evolution.title,
                            style: pw.TextStyle(font: font, fontSize: 8),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Seguimientos: ${evolution.followUpCount}',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMedicalSection(
    MedicalSummary summary,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('INFORMACIÓN MÉDICA', boldFont),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (summary.bloodType != null)
                _buildInfoRow(
                  'Tipo de Sangre:',
                  summary.bloodType!,
                  font,
                  boldFont,
                ),
              if (summary.activeConditions.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Condiciones Activas:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                ...summary.activeConditions.map(
                  (condition) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, top: 2),
                    child: pw.Text(
                      '• $condition',
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ),
                ),
              ],
              if (summary.currentMedications.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Medicación Actual:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                ...summary.currentMedications.map(
                  (medication) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, top: 2),
                    child: pw.Text(
                      '• $medication',
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ),
                ),
              ],
              if (summary.activeAllergies.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Alergias:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                ...summary.activeAllergies.map(
                  (allergy) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, top: 2),
                    child: pw.Text(
                      '• $allergy',
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ),
                ),
              ],
              if (summary.bloodType == null &&
                  summary.activeConditions.isEmpty &&
                  summary.currentMedications.isEmpty &&
                  summary.activeAllergies.isEmpty)
                pw.Text(
                  'No se registró información médica relevante.',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAttitudesSection(
    AttitudesSummary summary,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACTITUDES PREDOMINANTES', boldFont),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (summary.positiveAttitudes.isNotEmpty) ...[
                pw.Text(
                  'Actitudes Positivas:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                ...summary.positiveAttitudes
                    .take(5)
                    .map(
                      (attitude) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                attitude.title,
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                            ),
                            pw.Text(
                              '${attitude.frequency}x',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9,
                                color: PdfColors.green800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              if (summary.negativeAttitudes.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Actitudes a Mejorar:',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                ...summary.negativeAttitudes
                    .take(5)
                    .map(
                      (attitude) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.orange50,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                attitude.title,
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                            ),
                            pw.Text(
                              '${attitude.frequency}x',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9,
                                color: PdfColors.orange800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildRecommendationsSection(
    String recommendations,
    String opportunities,
    String strengths,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (strengths.isNotEmpty) ...[
          _buildSectionTitle('FORTALEZAS IDENTIFICADAS', boldFont),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green200),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              strengths,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.justify,
            ),
          ),
          pw.SizedBox(height: 12),
        ],
        if (opportunities.isNotEmpty) ...[
          _buildSectionTitle('ÁREAS DE OPORTUNIDAD', boldFont),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange200),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              opportunities,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.justify,
            ),
          ),
          pw.SizedBox(height: 12),
        ],
        if (recommendations.isNotEmpty) ...[
          _buildSectionTitle('RECOMENDACIONES', boldFont),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue200),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              recommendations,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ],
    );
  }

  // ========== MÉTODOS PRIVADOS PARA FICHA PEDAGÓGICA ==========

  pw.Widget _buildFichaPedagogicaHeader(FinalReport report, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal700,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FICHA PEDAGÓGICA',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 22,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            report.studentSummary.fullName,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            '${report.studentSummary.grade} ${report.studentSummary.group} • ${report.schoolYear}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFichaStudentInfo(
    StudentSummary student,
    String schoolYear,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  student.fullName,
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                ),
                pw.Text(
                  'CURP: ${student.curp}',
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),
                pw.Text(
                  'Matrícula: ${student.enrollment}',
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '${student.grade} ${student.group}',
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
              pw.Text(schoolYear, style: pw.TextStyle(font: font, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFichaConductSummary(
    ConductualSummary summary,
    ConductLetter letter,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONDUCTA',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        summary.totalPositiveReports.toString(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'Positivos',
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        summary.totalNegativeReports.toString(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.red800,
                        ),
                      ),
                      pw.Text(
                        'Negativos',
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Clasificación: ${_getConductClassificationText(letter.classification)}',
            style: pw.TextStyle(font: boldFont, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFichaBAPSummary(
    BAPSummary summary,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BARRERAS DE APRENDIZAJE',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: PdfColors.teal700,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: summary.totalActiveBAP > 0
                      ? PdfColors.orange100
                      : PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '${summary.totalActiveBAP} activas',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 9,
                    color: summary.totalActiveBAP > 0
                        ? PdfColors.orange800
                        : PdfColors.green800,
                  ),
                ),
              ),
            ],
          ),
          if (summary.bapTypeBreakdown.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 4,
              runSpacing: 4,
              children: summary.bapTypeBreakdown.entries
                  .map(
                    (entry) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        '${entry.key}: ${entry.value}',
                        style: pw.TextStyle(font: font, fontSize: 7),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildFichaMedicalSummary(
    MedicalSummary summary,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final hasInfo =
        summary.bloodType != null ||
        summary.activeConditions.isNotEmpty ||
        summary.currentMedications.isNotEmpty ||
        summary.activeAllergies.isNotEmpty;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN MÉDICA',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 6),
          if (hasInfo)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (summary.bloodType != null)
                  pw.Text(
                    'Tipo de sangre: ${summary.bloodType}',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                if (summary.activeConditions.isNotEmpty)
                  pw.Text(
                    'Condiciones: ${summary.activeConditions.join(", ")}',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                if (summary.activeAllergies.isNotEmpty)
                  pw.Text(
                    'Alergias: ${summary.activeAllergies.join(", ")}',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
              ],
            )
          else
            pw.Text(
              'Sin información médica registrada',
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildFichaAttitudesSummary(
    AttitudesSummary summary,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ACTITUDES PREDOMINANTES',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 6),
          if (summary.positiveAttitudes.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Positivas: ${summary.positiveAttitudes.take(3).map((a) => a.title).join(", ")}',
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),
              ],
            ),
          if (summary.negativeAttitudes.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 4),
                pw.Text(
                  'A mejorar: ${summary.negativeAttitudes.take(3).map((a) => a.title).join(", ")}',
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildFichaRecommendations(
    String recommendations,
    String strengths,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OBSERVACIONES Y RECOMENDACIONES',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 6),
          if (strengths.isNotEmpty) ...[
            pw.Text(
              'Fortalezas:',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
            pw.Text(strengths, style: pw.TextStyle(font: font, fontSize: 8)),
            pw.SizedBox(height: 4),
          ],
          if (recommendations.isNotEmpty) ...[
            pw.Text(
              'Recomendaciones:',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
            pw.Text(
              recommendations,
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ],
        ],
      ),
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  pw.Widget _buildSectionTitle(String title, pw.Font boldFont) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: boldFont,
        fontSize: 12,
        color: PdfColors.blue700,
      ),
    );
  }

  pw.Widget _buildStatCard(
    String label,
    String value,
    PdfColor bgColor,
    PdfColor textColor,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 18, color: textColor),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 9, color: textColor),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportFooter(FinalReport report, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Generado por ${AppConstants.appName}',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Fecha de generación: ${_formatDate(report.generationDate)}',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Este documento es oficial y contiene información confidencial',
            style: pw.TextStyle(
              font: font,
              fontSize: 7,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  String _getConductClassificationText(String classification) {
    switch (classification) {
      case 'excellent':
        return 'Excelente';
      case 'good':
        return 'Buena';
      case 'regular':
        return 'Regular';
      case 'needs_attention':
        return 'Requiere Atención';
      default:
        return 'Sin Clasificar';
    }
  }

  String _formatSeverity(String severity) {
    switch (severity) {
      case 'mild':
        return 'Leve';
      case 'moderate':
        return 'Moderada';
      case 'severe':
        return 'Severa';
      case 'verySevere':
        return 'Muy Severa';
      default:
        return severity;
    }
  }

  /// Genera un PDF de reporte de conducta con espacios para firmas
  Future<Uint8List> generateConductReportPDF(
    ConductReport report,
    Student student,
    String reporterName,
  ) async {
    final pdf = pw.Document();

    // Cargar fuentes
    final fontData = await PdfGoogleFonts.notoSansRegular();
    final boldFontData = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado del documento
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: report.isPositive
                    ? PdfColor.fromHex('#E8F5E9')
                    : PdfColor.fromHex('#FFEBEE'),
                border: pw.Border.all(
                  color: report.isPositive
                      ? PdfColor.fromHex('#4CAF50')
                      : PdfColor.fromHex('#F44336'),
                  width: 2,
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REPORTE DE CONDUCTA ${report.isPositive ? 'POSITIVO' : 'NEGATIVO'}',
                    style: pw.TextStyle(
                      font: boldFontData,
                      fontSize: 18,
                      color: report.isPositive
                          ? PdfColor.fromHex('#2E7D32')
                          : PdfColor.fromHex('#C62828'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Fecha de emisión: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)}',
                    style: pw.TextStyle(font: fontData, fontSize: 10),
                  ),
                  pw.Text(
                    'Folio: ${report.id}',
                    style: pw.TextStyle(font: fontData, fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Información del estudiante
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORMACIÓN DEL ESTUDIANTE',
                    style: pw.TextStyle(
                      font: boldFontData,
                      fontSize: 14,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildConductInfoRow(
                    'Nombre completo:',
                    student.fullName,
                    fontData,
                    boldFontData,
                  ),
                  _buildConductInfoRow(
                    'CURP:',
                    student.curp,
                    fontData,
                    boldFontData,
                  ),
                  _buildConductInfoRow(
                    'Matrícula:',
                    student.enrollment,
                    fontData,
                    boldFontData,
                  ),
                  _buildConductInfoRow(
                    'Grado:',
                    '${student.grade.displayName} Grupo: ${student.group}',
                    fontData,
                    boldFontData,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Detalles del incidente
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DETALLES DEL REPORTE',
                    style: pw.TextStyle(
                      font: boldFontData,
                      fontSize: 14,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildConductInfoRow(
                    'Título:',
                    report.title,
                    fontData,
                    boldFontData,
                  ),
                  if (!report.isPositive && report.severity != null)
                    _buildConductInfoRow(
                      'Severidad:',
                      report.severityDisplayName,
                      fontData,
                      boldFontData,
                    ),
                  _buildConductInfoRow(
                    'Fecha del incidente:',
                    DateFormat('dd/MM/yyyy HH:mm').format(report.incidentDate),
                    fontData,
                    boldFontData,
                  ),
                  _buildConductInfoRow(
                    'Reportado por:',
                    reporterName,
                    fontData,
                    boldFontData,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Descripción:',
                    style: pw.TextStyle(font: boldFontData, fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    report.description,
                    style: pw.TextStyle(font: fontData, fontSize: 10),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Contexto adicional
            if (report.context != null && report.context!.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColor.fromHex('#F5F5F5'),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Contexto adicional:',
                      style: pw.TextStyle(font: boldFontData, fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      report.context!,
                      style: pw.TextStyle(font: fontData, fontSize: 10),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ],
                ),
              ),

            if (report.context != null && report.context!.isNotEmpty)
              pw.SizedBox(height: 16),

            // Testigos
            if (report.witnesses != null && report.witnesses!.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Testigos:',
                      style: pw.TextStyle(font: boldFontData, fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      report.witnesses!,
                      style: pw.TextStyle(font: fontData, fontSize: 10),
                    ),
                  ],
                ),
              ),

            if (report.witnesses != null && report.witnesses!.isNotEmpty)
              pw.SizedBox(height: 16),

            // Acciones inmediatas
            if (report.immediateActions != null &&
                report.immediateActions!.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColor.fromHex('#FFF8E1'),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Acciones inmediatas tomadas:',
                      style: pw.TextStyle(font: boldFontData, fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      report.immediateActions!,
                      style: pw.TextStyle(font: fontData, fontSize: 10),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ],
                ),
              ),

            if (report.immediateActions != null &&
                report.immediateActions!.isNotEmpty)
              pw.SizedBox(height: 30),

            // Espacios para firmas
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColor.fromHex('#FAFAFA'),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FIRMAS Y ACUERDOS',
                    style: pw.TextStyle(
                      font: boldFontData,
                      fontSize: 14,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Firma del reportero
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              height: 80,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey600),
                                borderRadius: pw.BorderRadius.circular(4),
                                color: PdfColors.white,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'Espacio para firma',
                                  style: pw.TextStyle(
                                    font: fontData,
                                    fontSize: 9,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              height: 1,
                              width: 200,
                              color: PdfColors.grey800,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              reporterName,
                              style: pw.TextStyle(
                                font: boldFontData,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              'Reportero',
                              style: pw.TextStyle(
                                font: fontData,
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // Firma del padre/tutor
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              height: 80,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey600),
                                borderRadius: pw.BorderRadius.circular(4),
                                color: PdfColors.white,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'Espacio para firma',
                                  style: pw.TextStyle(
                                    font: fontData,
                                    fontSize: 9,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              height: 1,
                              width: 200,
                              color: PdfColors.grey800,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              student.tutor ?? 'Padre/Tutor',
                              style: pw.TextStyle(
                                font: boldFontData,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              'Padre/Tutor',
                              style: pw.TextStyle(
                                font: fontData,
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Acuerdo del padre (si existe)
                  if (report.parentAgreement != null &&
                      report.parentAgreement!.isNotEmpty)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 16),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue300),
                        borderRadius: pw.BorderRadius.circular(4),
                        color: PdfColor.fromHex('#E3F2FD'),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Acuerdo con el padre/tutor:',
                            style: pw.TextStyle(
                              font: boldFontData,
                              fontSize: 11,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            report.parentAgreement!,
                            style: pw.TextStyle(font: fontData, fontSize: 10),
                            textAlign: pw.TextAlign.justify,
                          ),
                          if (report.agreementDate != null) ...[
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Fecha del acuerdo: ${DateFormat('dd/MM/yyyy').format(report.agreementDate!)}',
                              style: pw.TextStyle(
                                font: fontData,
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                          if (report.followUpDate != null) ...[
                            pw.Text(
                              'Fecha de seguimiento: ${DateFormat('dd/MM/yyyy').format(report.followUpDate!)}',
                              style: pw.TextStyle(
                                font: fontData,
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Pie de página
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Este documento es un registro oficial del reporte de conducta.',
                    style: pw.TextStyle(
                      font: fontData,
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: fontData,
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Helper para crear filas de información en reportes de conducta
  pw.Widget _buildConductInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Sube el PDF a Supabase Storage y retorna la URL pública
  Future<String> _uploadPDFToStorage(
    Uint8List pdfData,
    String fileName,
    String bucket,
  ) async {
    try {
      // Subir archivo a Supabase Storage
      await _databaseService.client.storage
          .from(bucket)
          .uploadBinary(
            fileName,
            pdfData,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      // Obtener URL pública
      final publicUrl = _databaseService.client.storage
          .from(bucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir PDF a Storage: $e');
    }
  }
}

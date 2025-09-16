import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service class for generating PDF reports for tournament results
class PdfService {
  static const double _marginAll = 40;

  /// Generates a PDF report for a tournament with all team results and pigeon details
  static Future<Uint8List> generateTournamentResultsPdf({
    required String tournamentId,
    required Map<String, dynamic> tournamentData,
    required List<PdfTeamResult> teamResults,
    required Map<String, List<PigeonResult>> teamPigeons,
  }) async {
    final pdf = pw.Document();

    // Check if it's a multi-day tournament
    final isMultiDay =
        tournamentData['numberOfDays'] != null &&
        tournamentData['numberOfDays'] > 1;

    if (isMultiDay) {
      return await _generateMultiDayTournamentPdf(
        tournamentId: tournamentId,
        tournamentData: tournamentData,
        teamResults: teamResults,
        teamPigeons: teamPigeons,
      );
    } else {
      // Add tournament results page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(_marginAll),
          build: (context) => [
            _buildHeader(tournamentData),
            pw.SizedBox(height: 20),
            _buildTournamentInfo(tournamentData),
            pw.SizedBox(height: 30),
            _buildResultsTable(teamResults),
            pw.SizedBox(height: 30),
            ..._buildDetailedPdfTeamResults(teamResults, teamPigeons),
          ],
        ),
      );

      return pdf.save();
    }
  }

  /// Generates a PDF report for multi-day tournaments
  static Future<Uint8List> _generateMultiDayTournamentPdf({
    required String tournamentId,
    required Map<String, dynamic> tournamentData,
    required List<PdfTeamResult> teamResults,
    required Map<String, List<PigeonResult>> teamPigeons,
  }) async {
    final pdf = pw.Document();
    final days = tournamentData['days'] as List<dynamic>? ?? [];

    // Add cover page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_marginAll),
        build: (context) => [
          _buildHeader(tournamentData),
          pw.SizedBox(height: 20),
          _buildTournamentInfo(tournamentData),
          pw.SizedBox(height: 30),
          pw.Text(
            'Multi-Day Tournament Results',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'This tournament spans ${tournamentData['numberOfDays']} days:',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          ...days.map<pw.Widget>((dayData) {
            final dayNumber = dayData['dayNumber'] as int;
            final dayDate = dayData['date'] as Timestamp;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'Day $dayNumber: ${dayDate.toDate().day}/${dayDate.toDate().month}/${dayDate.toDate().year}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ],
      ),
    );

    // Add results for each day
    for (final dayData in days) {
      final dayNumber = dayData['dayNumber'] as int;
      final dayDate = dayData['date'] as Timestamp;

      // Filter team results for this day
      final dayTeamResults = teamResults
          .where((result) => result.day == dayNumber)
          .toList();
      final dayTeamPigeons = <String, List<PigeonResult>>{};

      // Filter pigeon results for this day
      teamPigeons.forEach((teamId, pigeons) {
        // This would need to be filtered based on day - you might need to modify the data structure
        dayTeamPigeons[teamId] = pigeons;
      });

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(_marginAll),
          build: (context) => [
            pw.Text(
              'Day $dayNumber Results',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Date: ${dayDate.toDate().day}/${dayDate.toDate().month}/${dayDate.toDate().year}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            if (dayTeamResults.isNotEmpty) ...[
              _buildResultsTable(dayTeamResults),
              pw.SizedBox(height: 30),
              ..._buildDetailedPdfTeamResults(dayTeamResults, dayTeamPigeons),
            ] else ...[
              pw.Text(
                'No teams participated on this day',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return pdf.save();
  }

  /// Downloads the PDF to device storage (mobile) or triggers browser download (web)
  static Future<void> downloadTournamentPdf({
    required String tournamentId,
    required Map<String, dynamic> tournamentData,
    required List<PdfTeamResult> teamResults,
    required Map<String, List<PigeonResult>> teamPigeons,
  }) async {
    try {
      final pdfBytes = await generateTournamentResultsPdf(
        tournamentId: tournamentId,
        tournamentData: tournamentData,
        teamResults: teamResults,
        teamPigeons: teamPigeons,
      );

      final tournamentName = tournamentData['name'] ?? 'Tournament';
      final fileName = '${tournamentName.replaceAll(' ', '_')}_Results.pdf';

      if (kIsWeb) {
        // For web platform - trigger browser download
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: fileName,
        );
      } else {
        // For mobile platforms - save to device storage
        await _savePdfToDevice(pdfBytes, fileName);
      }
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Builds the PDF header with tournament title
  static pw.Widget _buildHeader(Map<String, dynamic> tournamentData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TOURNAMENT RESULTS',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Container(
          width: double.infinity,
          height: 3,
          color: PdfColors.blue900,
          margin: const pw.EdgeInsets.symmetric(vertical: 10),
        ),
        pw.Text(
          tournamentData['name'] ?? 'Unnamed Tournament',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Builds tournament information section
  static pw.Widget _buildTournamentInfo(Map<String, dynamic> tournamentData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tournament Information',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Location: ${tournamentData['location'] ?? 'Not specified'}',
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Date: ${_formatDate(tournamentData['date'])}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Generated: ${_formatDateTime(DateTime.now())}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Pigeon Track System'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the main results table with team rankings
  static pw.Widget _buildResultsTable(List<PdfTeamResult> teamResults) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Final Rankings',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Rank', isHeader: true),
                _buildTableCell('Team Name', isHeader: true),
                _buildTableCell('Captain', isHeader: true),
                _buildTableCell('Progress', isHeader: true),
                _buildTableCell('Total Flight Time', isHeader: true),
              ],
            ),
            // Data rows
            ...teamResults.asMap().entries.map((entry) {
              final index = entry.key;
              final team = entry.value;
              final isWinner = index == 0 && team.totalTime != Duration.zero;

              return pw.TableRow(
                decoration: isWinner
                    ? const pw.BoxDecoration(color: PdfColors.amber50)
                    : null,
                children: [
                  _buildTableCell(
                    isWinner ? '🏆 ${index + 1}' : '${index + 1}',
                    isBold: isWinner,
                  ),
                  _buildTableCell(team.teamName, isBold: isWinner),
                  _buildTableCell(team.captain),
                  _buildTableCell(
                    '${team.completedFlights}/${team.totalPigeons}',
                  ),
                  _buildTableCell(
                    team.totalTime != Duration.zero
                        ? _formatDuration(team.totalTime)
                        : '--',
                    isBold: isWinner,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /// Builds detailed results for each team including pigeon data
  static List<pw.Widget> _buildDetailedPdfTeamResults(
    List<PdfTeamResult> teamResults,
    Map<String, List<PigeonResult>> teamPigeons,
  ) {
    return [
      pw.Text(
        'Detailed Team Results',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 15),
      ...teamResults.asMap().entries.map((entry) {
        final index = entry.key;
        final team = entry.value;
        final pigeons = teamPigeons[team.teamId] ?? [];
        final isWinner = index == 0 && team.totalTime != Duration.zero;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: isWinner ? PdfColors.amber100 : PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      isWinner ? '🏆 ' : '',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      '${index + 1}. ${team.teamName}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      'Captain: ${team.captain}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              if (pigeons.isNotEmpty) ...[
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(40),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        _buildTableCell('#', isHeader: true, fontSize: 10),
                        _buildTableCell(
                          'Pigeon Name',
                          isHeader: true,
                          fontSize: 10,
                        ),
                        _buildTableCell(
                          'Start Time',
                          isHeader: true,
                          fontSize: 10,
                        ),
                        _buildTableCell(
                          'End Time',
                          isHeader: true,
                          fontSize: 10,
                        ),
                        _buildTableCell(
                          'Flight Time',
                          isHeader: true,
                          fontSize: 10,
                        ),
                      ],
                    ),
                    ...pigeons.asMap().entries.map((pigeonEntry) {
                      final pigeonIndex = pigeonEntry.key;
                      final pigeon = pigeonEntry.value;

                      return pw.TableRow(
                        children: [
                          _buildTableCell('${pigeonIndex + 1}', fontSize: 9),
                          _buildTableCell(pigeon.name, fontSize: 9),
                          _buildTableCell(
                            _formatTime(pigeon.startTime),
                            fontSize: 9,
                          ),
                          _buildTableCell(
                            _formatTime(pigeon.endTime),
                            fontSize: 9,
                          ),
                          _buildTableCell(pigeon.flightTime, fontSize: 9),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ] else ...[
                pw.Text(
                  'No pigeons recorded for this team',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ];
  }

  /// Helper method to build table cells
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    double fontSize = 11,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Saves PDF to device storage for mobile platforms
  static Future<void> _savePdfToDevice(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // For mobile, you might want to show a success message or open the file
      // This would typically be handled by the calling widget
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Formats date for display
  static String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  /// Formats date and time for display
  static String _formatDateTime(DateTime dateTime) {
    final hour12 = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${hour12.toString()}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Formats time for display
  static String _formatTime(dynamic time) {
    if (time == null) return '--';
    if (time is Timestamp) {
      final dateTime = time.toDate();
      final hour12 = dateTime.hour == 0
          ? 12
          : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
      final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
      return '${hour12.toString()}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
    }
    return '--';
  }

  /// Formats duration for display
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Data model for team results used in PDF generation
class PdfTeamResult {
  final String teamId;
  final String teamName;
  final String captain;
  final Duration totalTime;
  final int totalPigeons;
  final int completedFlights;
  final int day;

  PdfTeamResult({
    required this.teamId,
    required this.teamName,
    required this.captain,
    required this.totalTime,
    required this.totalPigeons,
    required this.completedFlights,
    required this.day,
  });
}

/// Data model for pigeon results used in PDF generation
class PigeonResult {
  final String name;
  final dynamic startTime;
  final dynamic endTime;
  final String flightTime;

  PigeonResult({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.flightTime,
  });
}

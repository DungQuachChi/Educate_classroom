import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../../providers/semester_provider.dart';
import '../../models/semester_model.dart';

class SemesterImportScreen extends StatefulWidget {
  const SemesterImportScreen({super.key});

  @override
  State<SemesterImportScreen> createState() => _SemesterImportScreenState();
}

class _SemesterImportScreenState extends State<SemesterImportScreen> {
  List<SemesterModel>? _parsedSemesters;
  List<String>? _existingCodes;
  bool _isProcessing = false;
  Map<String, dynamic>? _importResult;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final bytes = result.files.first.bytes!;
        final csvString = utf8.decode(bytes);
        
        _parseCSV(csvString);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _parseCSV(String csvString) {
    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
      );

      if (rows.isEmpty) {
        throw 'CSV file is empty';
      }

      // Skip header row if it exists
      int startRow = 0;
      if (rows[0].length >= 2 && 
          rows[0][0].toString().toLowerCase().contains('code')) {
        startRow = 1;
      }

      List<SemesterModel> semesters = [];
      List<String> existingCodes = Provider.of<SemesterProvider>(context, listen: false)
          .semesters
          .map((s) => s.code)
          .toList();

      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 2) {
          try {
            semesters.add(SemesterModel.fromCsv(row));
          } catch (e) {
            print('Error parsing row $i: $e');
          }
        }
      }

      setState(() {
        _parsedSemesters = semesters;
        _existingCodes = existingCodes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _import() async {
    if (_parsedSemesters == null || _parsedSemesters!.isEmpty) return;

    setState(() => _isProcessing = true);

    final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);

    try {
      final result = await semesterProvider.importSemesters(_parsedSemesters!);
      
      setState(() {
        _importResult = result;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import complete: ${result['added']} added, ${result['skipped']} skipped',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Semesters from CSV'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Instructions
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'CSV Format',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your CSV file should have the following columns:\n'
                    '1. Semester Code (e.g., 2024-1)\n'
                    '2. Semester Name (e.g., Fall Semester 2024)\n\n'
                    'Example:\n'
                    'Code,Name\n'
                    '2024-1,Fall Semester 2024\n'
                    '2024-2,Spring Semester 2024',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pick File Button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _pickFile,
            icon: const Icon(Icons.file_upload),
            label: const Text('Select CSV File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Preview
          if (_parsedSemesters != null) ...[
            Text(
              'Preview (${_parsedSemesters!.length} semesters)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _parsedSemesters!.map((semester) {
                  final exists = _existingCodes!.contains(semester.code);
                  return ListTile(
                    leading: Icon(
                      exists ? Icons.check_circle : Icons.add_circle,
                      color: exists ? Colors.orange : Colors.green,
                    ),
                    title: Text(semester.code),
                    subtitle: Text(semester.name),
                    trailing: Text(
                      exists ? 'Already exists' : 'Will be added',
                      style: TextStyle(
                        fontSize: 12,
                        color: exists ? Colors.orange : Colors.green,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Import Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _import,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'IMPORT SEMESTERS',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],

          // Import Results
          if (_importResult != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Results',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('✓ Added: ${_importResult!['added']}'),
                    Text('⊘ Skipped: ${_importResult!['skipped']}'),
                    if (_importResult!['errors'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Errors:',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...(_importResult!['errors'] as List<String>).map(
                        (error) => Text(
                          '• $error',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
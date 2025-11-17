import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../../providers/material_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../models/material_model.dart';
import '../../models/course_model.dart';
import 'material_form_screen.dart';

class MaterialManagementScreen extends StatefulWidget {
  const MaterialManagementScreen({super.key});

  @override
  State<MaterialManagementScreen> createState() => _MaterialManagementScreenState();
}

class _MaterialManagementScreenState extends State<MaterialManagementScreen> {
  CourseModel? _selectedCourse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      if (semesterProvider.currentSemester != null) {
        courseProvider.loadCoursesBySemester(semesterProvider.currentSemester!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Materials'),
      ),
      body: Consumer3<SemesterProvider, CourseProvider, MaterialProvider>(
        builder: (context, semesterProvider, courseProvider, materialProvider, child) {
          if (semesterProvider.currentSemester == null) {
            return const Center(child: Text('Please create a semester first'));
          }

          if (courseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = courseProvider.courses;

          if (courses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No courses available'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Course Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.teal.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Course', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CourseModel>(
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Choose a course'),
                      items: courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text('${course.code} - ${course.name}'),
                        );
                      }).toList(),
                      onChanged: (course) {
                        setState(() => _selectedCourse = course);
                        if (course != null) {
                          materialProvider.loadMaterialsByCourse(course.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Materials List
              Expanded(
                child: _selectedCourse == null
                    ? const Center(child: Text('Please select a course'))
                    : materialProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildMaterialsList(materialProvider.materials),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedCourse != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaterialFormScreen(courseId: _selectedCourse!.id),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Upload Material'),
            )
          : null,
    );
  }

  Widget _buildMaterialsList(List<MaterialModel> materials) {
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No materials yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        return _MaterialCard(
          material: materials[index],
          courseId: _selectedCourse!.id,
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final String courseId;

  const _MaterialCard({required this.material, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final materialProvider = Provider.of<MaterialProvider>(context, listen: false);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              material.fileIcon,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: Text(
          material.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              material.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.insert_drive_file, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  material.fileName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.storage, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  material.fileSizeFormatted,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(material.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'download':
                html.window.open(material.fileUrl, '_blank');
                break;
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaterialFormScreen(
                      courseId: courseId,
                      material: material,
                    ),
                  ),
                );
                break;
              case 'delete':
                _showDeleteDialog(context, materialProvider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MaterialProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Delete "${material.title}"?\n\nThe file will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteMaterial(material.id, material.fileUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Material deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
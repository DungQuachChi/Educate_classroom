import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educate_classroom/models/assignment_model.dart';
import 'package:educate_classroom/models/submission_model.dart';
import '../models/semester_model.dart';
import '../models/course_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SEMESTER OPERATIONS ====================

  // Create semester
  Future<String> createSemester(SemesterModel semester) async {
    try {
      // If this is set as current, unset all others
      if (semester.isCurrent) {
        await _unsetCurrentSemesters();
      }

      DocumentReference doc = await _firestore
          .collection(AppConstants.semestersCollection)
          .add(semester.toMap());

      return doc.id;
    } catch (e) {
      print('Create semester error: $e');
      rethrow;
    }
  }

  // Get all semesters
  Stream<List<SemesterModel>> getSemesters() {
    return _firestore
        .collection(AppConstants.semestersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SemesterModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get current semester
  Future<SemesterModel?> getCurrentSemester() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.semestersCollection)
          .where('isCurrent', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SemesterModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }

      // If no current semester, get the most recent one
      QuerySnapshot latestSnapshot = await _firestore
          .collection(AppConstants.semestersCollection)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (latestSnapshot.docs.isNotEmpty) {
        return SemesterModel.fromMap(
          latestSnapshot.docs.first.data() as Map<String, dynamic>,
          latestSnapshot.docs.first.id,
        );
      }

      return null;
    } catch (e) {
      print('Get current semester error: $e');
      return null;
    }
  }

  // Update semester
  Future<void> updateSemester(SemesterModel semester) async {
    try {
      // If setting as current, unset all others
      if (semester.isCurrent) {
        await _unsetCurrentSemesters();
      }

      await _firestore
          .collection(AppConstants.semestersCollection)
          .doc(semester.id)
          .update(semester.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      print('Update semester error: $e');
      rethrow;
    }
  }

  // Delete semester
  Future<void> deleteSemester(String semesterId) async {
    try {
      // Delete all courses in this semester
      QuerySnapshot courses = await _firestore
          .collection(AppConstants.coursesCollection)
          .where('semesterId', isEqualTo: semesterId)
          .get();

      for (var course in courses.docs) {
        await deleteCourse(course.id);
      }

      // Delete semester
      await _firestore
          .collection(AppConstants.semestersCollection)
          .doc(semesterId)
          .delete();
    } catch (e) {
      print('Delete semester error: $e');
      rethrow;
    }
  }

  // Helper: Unset all current semesters
  Future<void> _unsetCurrentSemesters() async {
    QuerySnapshot currentSemesters = await _firestore
        .collection(AppConstants.semestersCollection)
        .where('isCurrent', isEqualTo: true)
        .get();

    for (var doc in currentSemesters.docs) {
      await doc.reference.update({'isCurrent': false});
    }
  }

  // Bulk import semesters from CSV
  Future<Map<String, dynamic>> importSemesters(
      List<SemesterModel> semesters) async {
    int added = 0;
    int skipped = 0;
    List<String> errors = [];

    for (var semester in semesters) {
      try {
        // Check if semester with same code already exists
        QuerySnapshot existing = await _firestore
            .collection(AppConstants.semestersCollection)
            .where('code', isEqualTo: semester.code)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await createSemester(semester);
          added++;
        } else {
          skipped++;
        }
      } catch (e) {
        errors.add('${semester.code}: $e');
      }
    }

    return {
      'added': added,
      'skipped': skipped,
      'errors': errors,
    };
  }

  // ==================== COURSE OPERATIONS ====================

  // Create course
  Future<String> createCourse(CourseModel course) async {
    try {
      DocumentReference doc = await _firestore
          .collection(AppConstants.coursesCollection)
          .add(course.toMap());

      return doc.id;
    } catch (e) {
      print('Create course error: $e');
      rethrow;
    }
  }

  // Get courses by semester
  Stream<List<CourseModel>> getCoursesBySemester(String semesterId) {
    return _firestore
        .collection(AppConstants.coursesCollection)
        .where('semesterId', isEqualTo: semesterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get single course
  Future<CourseModel?> getCourse(String courseId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.coursesCollection)
          .doc(courseId)
          .get();

      if (doc.exists) {
        return CourseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Get course error: $e');
      return null;
    }
  }

  // Update course
  Future<void> updateCourse(CourseModel course) async {
    try {
      await _firestore
          .collection(AppConstants.coursesCollection)
          .doc(course.id)
          .update(course.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      print('Update course error: $e');
      rethrow;
    }
  }

  // Delete course
  Future<void> deleteCourse(String courseId) async {
    try {
      // Delete all groups in this course
      QuerySnapshot groups = await _firestore
          .collection(AppConstants.groupsCollection)
          .where('courseId', isEqualTo: courseId)
          .get();

      for (var group in groups.docs) {
        await group.reference.delete();
      }

      // Delete course
      await _firestore
          .collection(AppConstants.coursesCollection)
          .doc(courseId)
          .delete();
    } catch (e) {
      print('Delete course error: $e');
      rethrow;
    }
  }

  // ==================== GROUP OPERATIONS ====================

  // Create group
  Future<String> createGroup(GroupModel group) async {
    try {
      DocumentReference doc = await _firestore
          .collection(AppConstants.groupsCollection)
          .add(group.toMap());

      return doc.id;
    } catch (e) {
      print('Create group error: $e');
      rethrow;
    }
  }

  // Get groups by course
  Stream<List<GroupModel>> getGroupsByCourse(String courseId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .where('courseId', isEqualTo: courseId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _firestore
          .collection(AppConstants.groupsCollection)
          .doc(group.id)
          .update(group.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      print('Update group error: $e');
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .delete();
    } catch (e) {
      print('Delete group error: $e');
      rethrow;
    }
  }

  // Add student to group
  Future<void> addStudentToGroup(String groupId, String studentId) async {
    try {
      await _firestore
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'studentIds': FieldValue.arrayUnion([studentId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Add student to group error: $e');
      rethrow;
    }
  }

  // Remove student from group
  Future<void> removeStudentFromGroup(String groupId, String studentId) async {
    try {
      await _firestore
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'studentIds': FieldValue.arrayRemove([studentId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Remove student from group error: $e');
      rethrow;
    }
  }

  // ==================== STUDENT OPERATIONS ====================

  // Get all students
Stream<List<UserModel>> getStudents() {
  return _firestore
      .collection(AppConstants.usersCollection)
      .where('role', isEqualTo: AppConstants.roleStudent)
      .where('isActive', isEqualTo: true) // ← Only active students
      .snapshots()
      .map((snapshot) {
        var students = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();
        
        students.sort((a, b) => a.displayName.compareTo(b.displayName));
        
        return students;
      });
}

  // Get students by IDs
  Future<List<UserModel>> getStudentsByIds(List<String> studentIds) async {
    if (studentIds.isEmpty) return [];

    try {
      List<UserModel> students = [];
      
      // Firestore 'in' query supports up to 10 items
      for (int i = 0; i < studentIds.length; i += 10) {
        int end = (i + 10 < studentIds.length) ? i + 10 : studentIds.length;
        List<String> batch = studentIds.sublist(i, end);

        QuerySnapshot snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        students.addAll(snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
      }

      return students;
    } catch (e) {
      print('Get students by IDs error: $e');
      return [];
    }
  }

   // Update student
  Future<void> updateStudent(UserModel student) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(student.uid)
          .update({
        'displayName': student.displayName,
        'studentId': student.studentId,
        'avatarUrl': student.avatarUrl,
      });
    } catch (e) {
      print('Update student error: $e');
      rethrow;
    }
  }

// Delete student
  Future<void> deleteStudent(String userId) async {
    try {
      // Remove student from all groups
      QuerySnapshot groups = await _firestore
          .collection(AppConstants.groupsCollection)
          .where('studentIds', arrayContains: userId)
          .get();

      for (var group in groups.docs) {
        await group.reference.update({
          'studentIds': FieldValue.arrayRemove([userId]),
        });
      }

      // Mark as inactive instead of deleting
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Note: Firebase Auth user still exists but can't login 
      // because we check isActive in auth flow
    } catch (e) {
      print('Delete student error: $e');
      rethrow;
    }
  }  
  // ==================== ASSIGNMENT OPERATIONS ====================

  // Create assignment
  Future<String> createAssignment(AssignmentModel assignment) async {
    try {
      DocumentReference doc = await _firestore
          .collection(AppConstants.assignmentsCollection)
          .add(assignment.toMap());
      return doc.id;
    } catch (e) {
      print('Create assignment error: $e');
      rethrow;
    }
  }

  // Get assignments by course
  Stream<List<AssignmentModel>> getAssignmentsByCourse(String courseId) {
    return _firestore
        .collection(AppConstants.assignmentsCollection)
        .where('courseId', isEqualTo: courseId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update assignment
  Future<void> updateAssignment(AssignmentModel assignment) async {
    try {
      await _firestore
          .collection(AppConstants.assignmentsCollection)
          .doc(assignment.id)
          .update(assignment.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      print('Update assignment error: $e');
      rethrow;
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      // Delete all submissions
      QuerySnapshot submissions = await _firestore
          .collection(AppConstants.submissionsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      for (var doc in submissions.docs) {
        await doc.reference.delete();
      }

      // Delete assignment
      await _firestore
          .collection(AppConstants.assignmentsCollection)
          .doc(assignmentId)
          .delete();
    } catch (e) {
      print('Delete assignment error: $e');
      rethrow;
    }
  }

  // ==================== SUBMISSION OPERATIONS ====================

  // Submit assignment with attempt tracking
  Future<String> submitAssignment({
    required String assignmentId,
    required String studentId,
    required AssignmentModel assignment,
    String? content,
    List<String>? attachmentUrls,
  }) async {
    try {
      // Get previous submissions
      final history = await getStudentSubmissionHistory(assignmentId, studentId);
      final attemptNumber = history.length + 1;

      // Check max attempts
      if (assignment.maxAttempts > 0 && attemptNumber > assignment.maxAttempts) {
        throw 'Maximum attempts (${assignment.maxAttempts}) exceeded';
      }

      // Check timing
      final now = DateTime.now();
      if (now.isBefore(assignment.startDate)) {
        throw 'Assignment has not started yet';
      }

      final isLate = now.isAfter(assignment.dueDate);

      if (isLate && !assignment.allowLateSubmission) {
        throw 'Late submissions not allowed';
      }

      if (isLate && assignment.lateDeadline != null && now.isAfter(assignment.lateDeadline!)) {
        throw 'Late deadline has passed';
      }

      // Create submission
      final submission = SubmissionModel(
        id: '',
        assignmentId: assignmentId,
        studentId: studentId,
        content: content,
        attachmentUrls: attachmentUrls ?? [],
        submittedAt: now,
        attemptNumber: attemptNumber,
        isLate: isLate,
      );

      DocumentReference doc = await _firestore
          .collection(AppConstants.submissionsCollection)
          .add(submission.toMap());

      return doc.id;
    } catch (e) {
      print('Submit assignment error: $e');
      rethrow;
    }
  }

  // Get student submission history (all attempts)
  Future<List<SubmissionModel>> getStudentSubmissionHistory(
    String assignmentId,
    String studentId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.submissionsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .orderBy('attemptNumber')
          .get();

      return snapshot.docs
          .map((doc) => SubmissionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Get submission history error: $e');
      return [];
    }
  }

  // Get all submissions for assignment
  Future<List<SubmissionModel>> getAllSubmissionsForAssignment(String assignmentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.submissionsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SubmissionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Get all submissions error: $e');
      return [];
    }
  }

  // Grade submission
  Future<void> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
    required String gradedBy,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.submissionsCollection)
          .doc(submissionId)
          .update({
        'score': score,
        'feedback': feedback,
        'gradedAt': FieldValue.serverTimestamp(),
        'gradedBy': gradedBy,
      });
    } catch (e) {
      print('Grade submission error: $e');
      rethrow;
    }
  }

  // Get students for assignment (based on groups)
  Future<List<UserModel>> getStudentsForAssignment(AssignmentModel assignment) async {
    try {
      if (assignment.groupIds.isEmpty) {
        // All students in course - get via all groups in course
        QuerySnapshot groupSnapshot = await _firestore
            .collection(AppConstants.groupsCollection)
            .where('courseId', isEqualTo: assignment.courseId)
            .get();

        Set<String> studentIds = {};
        for (var doc in groupSnapshot.docs) {
          final group = GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          studentIds.addAll(group.studentIds);
        }

        return await getStudentsByIds(studentIds.toList());
      } else {
        // Specific groups
        QuerySnapshot groupSnapshot = await _firestore
            .collection(AppConstants.groupsCollection)
            .where(FieldPath.documentId, whereIn: assignment.groupIds)
            .get();

        Set<String> studentIds = {};
        for (var doc in groupSnapshot.docs) {
          final group = GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          studentIds.addAll(group.studentIds);
        }

        return await getStudentsByIds(studentIds.toList());
      }
    } catch (e) {
      print('Get students for assignment error: $e');
      return [];
    }
  }

  // Export submissions to CSV
  Future<String> exportSubmissionsToCSV(
    String assignmentId,
    AssignmentModel assignment,
  ) async {
    try {
      final submissions = await getAllSubmissionsForAssignment(assignmentId);
      final students = await getStudentsForAssignment(assignment);

      // Group submissions by student
      Map<String, List<SubmissionModel>> submissionsByStudent = {};
      for (var sub in submissions) {
        if (!submissionsByStudent.containsKey(sub.studentId)) {
          submissionsByStudent[sub.studentId] = [];
        }
        submissionsByStudent[sub.studentId]!.add(sub);
      }

      // Build CSV
      StringBuffer csv = StringBuffer();
      csv.writeln('Student ID,Name,Email,Status,Attempts,Latest Score,Highest Score,Submitted At,Is Late,Feedback');

      for (var student in students) {
        final subs = submissionsByStudent[student.uid] ?? [];
        final latest = subs.isNotEmpty ? subs.reduce((a, b) => 
          a.submittedAt.isAfter(b.submittedAt) ? a : b) : null;
        
        final graded = subs.where((s) => s.score != null).toList();
        final highestScore = graded.isEmpty ? null : 
          graded.map((s) => s.score!).reduce((a, b) => a > b ? a : b);

        csv.write('"${student.studentId ?? ""}"');
        csv.write(',"${student.displayName}"');
        csv.write(',"${student.email}"');
        csv.write(',${latest == null ? "Not Submitted" : (latest.isGraded ? "Graded" : "Submitted")}');
        csv.write(',${subs.length}');
        csv.write(',${latest?.score ?? ""}');
        csv.write(',${highestScore ?? ""}');
        csv.write(',${latest?.submittedAt.toIso8601String() ?? ""}');
        csv.write(',${latest?.isLate ?? false}');
        csv.writeln(',"${latest?.feedback?.replaceAll('"', '""') ?? ""}"');
      }

      return csv.toString();
    } catch (e) {
      print('Export CSV error: $e');
      rethrow;
    }
  }

    // ==================== STUDENT-SPECIFIC OPERATIONS ====================

  // Get courses that student is enrolled in (via groups)
  Future<List<CourseModel>> getStudentCourses(String studentId) async {
    try {
      // Get all groups that student is in
      QuerySnapshot groupSnapshot = await _firestore
          .collection(AppConstants.groupsCollection)
          .where('studentIds', arrayContains: studentId)
          .get();

      if (groupSnapshot.docs.isEmpty) {
        return [];
      }

      // Get unique course IDs
      Set<String> courseIds = {};
      for (var doc in groupSnapshot.docs) {
        final group = GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        courseIds.add(group.courseId);
      }

      // Get courses
      List<CourseModel> courses = [];
      for (String courseId in courseIds) {
        DocumentSnapshot courseDoc = await _firestore
            .collection(AppConstants.coursesCollection)
            .doc(courseId)
            .get();

        if (courseDoc.exists) {
          courses.add(CourseModel.fromMap(
            courseDoc.data() as Map<String, dynamic>,
            courseDoc.id,
          ));
        }
      }

      return courses;
    } catch (e) {
      print('Get student courses error: $e');
      return [];
    }
  }

  // Get student assignments
  Future<List<AssignmentModel>> getStudentAssignments(
    String studentId,
    String courseId,
  ) async {
    try {
      // Get student's groups in course
      QuerySnapshot groupSnapshot = await _firestore
          .collection(AppConstants.groupsCollection)
          .where('courseId', isEqualTo: courseId)
          .where('studentIds', arrayContains: studentId)
          .get();

      List<String> groupIds = groupSnapshot.docs.map((doc) => doc.id).toList();

      // Get assignments
      QuerySnapshot assignmentSnapshot = await _firestore
          .collection(AppConstants.assignmentsCollection)
          .where('courseId', isEqualTo: courseId)
          .get();

      List<AssignmentModel> assignments = [];
      for (var doc in assignmentSnapshot.docs) {
        final assignment = AssignmentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Include if no groups specified or student is in one of the groups
        if (assignment.groupIds.isEmpty || 
            assignment.groupIds.any((gid) => groupIds.contains(gid))) {
          assignments.add(assignment);
        }
      }

      assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return assignments;
    } catch (e) {
      print('Get student assignments error: $e');
      return [];
    }
  }

  // Get student's submissions
  Stream<List<SubmissionModel>> getStudentSubmissions(String studentId) {
    return _firestore
        .collection(AppConstants.submissionsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
    // ==================== GROUP HELPER METHODS ====================

  // Get group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();

      if (doc.exists) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Get group by ID error: $e');
      return null;
    }
  }

  // Get groups by course
  Future<List<GroupModel>> getGroupsByCourseAsync(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.groupsCollection)
          .where('courseId', isEqualTo: courseId)
          .get();

      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Get groups by course error: $e');
      return [];
    }
  }

  // Get student's group names in assignment
  Future<String> getStudentGroupNames(String studentId, AssignmentModel assignment) async {
    try {
      List<GroupModel> groups = [];

      if (assignment.groupIds.isNotEmpty) {
        // Get specific groups
        for (String groupId in assignment.groupIds) {
          final group = await getGroupById(groupId);
          if (group != null && group.studentIds.contains(studentId)) {
            groups.add(group);
          }
        }
      } else {
        // Get all groups for course
        final allGroups = await getGroupsByCourseAsync(assignment.courseId);
        groups = allGroups.where((g) => g.studentIds.contains(studentId)).toList();
      }

      if (groups.isEmpty) return 'No Group';
      return groups.map((g) => g.name).join(', ');
    } catch (e) {
      print('Get student group names error: $e');
      return 'Unknown';
    }
  }
    // ==================== FILE UPLOAD ====================

  // Upload file to Firebase Storage
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload file error: $e');
      rethrow;
    }
  }

  // Upload file bytes (for web)
  Future<String> uploadFileBytes(
    Uint8List bytes,
    String fileName,
    String path,
  ) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: _getContentType(fileName)),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload file bytes error: $e');
      rethrow;
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educate_classroom/models/assignment_model.dart';
import 'package:educate_classroom/models/submission_model.dart';
import '../models/semester_model.dart';
import '../models/course_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get single assignment
  Future<AssignmentModel?> getAssignment(String assignmentId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.assignmentsCollection)
          .doc(assignmentId)
          .get();

      if (doc.exists) {
        return AssignmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Get assignment error: $e');
      return null;
    }
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
      // Delete all submissions for this assignment
      QuerySnapshot submissions = await _firestore
          .collection(AppConstants.submissionsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      for (var submission in submissions.docs) {
        await submission.reference.delete();
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

  // Submit assignment
  Future<String> createSubmission(SubmissionModel submission) async {
    try {
      // Check if student already submitted
      QuerySnapshot existing = await _firestore
          .collection(AppConstants.submissionsCollection)
          .where('assignmentId', isEqualTo: submission.assignmentId)
          .where('studentId', isEqualTo: submission.studentId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Update existing submission
        await existing.docs.first.reference.update(submission.toMap());
        return existing.docs.first.id;
      } else {
        // Create new submission
        DocumentReference doc = await _firestore
            .collection(AppConstants.submissionsCollection)
            .add(submission.toMap());
        return doc.id;
      }
    } catch (e) {
      print('Create submission error: $e');
      rethrow;
    }
  }

  // Get submissions for an assignment
Stream<List<SubmissionModel>> getSubmissionsByAssignment(String assignmentId) {
    return _firestore
        .collection(AppConstants.submissionsCollection)
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get student's submission for an assignment
  Future<SubmissionModel?> getStudentSubmission(String assignmentId, String studentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.submissionsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SubmissionModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Get student submission error: $e');
      return null;
    }
  }

  // Grade submission
  Future<void> gradeSubmission(String submissionId, int score, String? feedback) async {
    try {
      await _firestore
          .collection(AppConstants.submissionsCollection)
          .doc(submissionId)
          .update({
        'score': score,
        'feedback': feedback,
        'gradedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Grade submission error: $e');
      rethrow;
    }
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final List<String> groupIds; 
  final String fileUrl;
  final String fileName;
  final String fileType; 
  final int fileSizeBytes;
  final String uploadedBy; 
  final DateTime createdAt;
  final DateTime? updatedAt;

  MaterialModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    this.groupIds = const [],
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.uploadedBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId,
      'groupIds': groupIds,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'uploadedBy': uploadedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MaterialModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      courseId: map['courseId'] ?? '',
      groupIds: List<String>.from(map['groupIds'] ?? []),
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? '',
      fileSizeBytes: map['fileSizeBytes'] ?? 0,
      uploadedBy: map['uploadedBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  MaterialModel copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    List<String>? groupIds,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      groupIds: groupIds ?? this.groupIds,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'xls':
      case 'xlsx':
        return '📈';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
        return '🎵';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📎';
    }
  }
}
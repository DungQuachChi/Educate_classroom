import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String courseId;
  final List<String> groupIds;
  final List<String> attachmentUrls;
  final List<String> attachmentNames;
  final String createdBy;
  final DateTime createdAt;
  final DateTime?  updatedAt;
  final List<String> viewedBy;
  final Map<String, List<String>> downloadedBy; // index -> [userIds]

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.courseId,
    this.groupIds = const [],
    this.attachmentUrls = const [],
    this.attachmentNames = const [],
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.viewedBy = const [],
    this.downloadedBy = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'courseId': courseId,
      'groupIds': groupIds,
      'attachmentUrls': attachmentUrls,
      'attachmentNames': attachmentNames,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'viewedBy': viewedBy,
      'downloadedBy': downloadedBy,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Parse downloadedBy with proper type handling
    Map<String, List<String>> parsedDownloadedBy = {};
    
    if (map['downloadedBy'] != null) {
      final downloadedByData = map['downloadedBy'] as Map<String, dynamic>;
      print('🔍 Parsing downloadedBy: $downloadedByData');
      
      downloadedByData.forEach((key, value) {
        // Remove any whitespace from key
        final cleanKey = key.trim();
        
        if (value is List) {
          parsedDownloadedBy[cleanKey] = List<String>.from(value);
          print('Parsed key "$cleanKey": ${parsedDownloadedBy[cleanKey]}');
        } else {
          print('Skipped key "$cleanKey": value is not a List');
        }
      });
    }
    
    print('Final parsedDownloadedBy: $parsedDownloadedBy');

    return AnnouncementModel(
      id: documentId,
      title: map['title'] ??  '',
      content: map['content'] ?? '',
      courseId: map['courseId'] ??  '',
      groupIds: List<String>.from(map['groupIds'] ?? []),
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      attachmentNames: List<String>.from(map['attachmentNames'] ?? []),
      createdBy: map['createdBy'] ??  '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      downloadedBy: parsedDownloadedBy,
    );
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? courseId,
    List<String>? groupIds,
    List<String>? attachmentUrls,
    List<String>? attachmentNames,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>?  viewedBy,
    Map<String, List<String>>? downloadedBy,
  }) {
    return AnnouncementModel(
      id: id ?? this. id,
      title: title ??  this.title,
      content: content ?? this.content,
      courseId: courseId ?? this. courseId,
      groupIds: groupIds ?? this.groupIds,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      attachmentNames: attachmentNames ?? this.attachmentNames,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ??  this.updatedAt,
      viewedBy: viewedBy ??  this.viewedBy,
      downloadedBy: downloadedBy ??  this.downloadedBy,
    );
  }

  int get viewCount => viewedBy.length;

  bool hasViewed(String userId) => viewedBy.contains(userId);

  // Get download count for specific attachment by index
  int getDownloadCount(int index) {
    return downloadedBy[index. toString()]?.length ?? 0;
  }

  // Get download count by URL (find index first)
  int getDownloadCountByUrl(String url) {
    final index = attachmentUrls.indexOf(url);
    if (index == -1) return 0;
    return getDownloadCount(index);
  }
}
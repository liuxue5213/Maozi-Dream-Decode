// 梦境数据模型
class DreamModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> emotions;
  final List<String> scenes;
  final String date;
  final String? interpretation;
  final String? userId;

  DreamModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.emotions,
    required this.scenes,
    required this.date,
    this.interpretation,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'emotions': emotions,
      'scenes': scenes,
      'date': date,
      'interpretation': interpretation,
      'userId': userId,
    };
  }

  factory DreamModel.fromJson(Map<String, dynamic> json) {
    return DreamModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
      emotions: json['emotions'] != null 
          ? List<String>.from(json['emotions']) 
          : <String>[],
      scenes: json['scenes'] != null 
          ? List<String>.from(json['scenes']) 
          : <String>[],
      date: json['date']?.toString() ?? '',
      interpretation: json['interpretation']?.toString(),
      userId: json['userId']?.toString(),
    );
  }
}

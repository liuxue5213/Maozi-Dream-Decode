// 梦境数据模型
class DreamModel {
  String id;
  String content;
  DateTime createdAt;
  List<String> emotions;
  List<String> scenes;
  String date;
  String? interpretation;
  String? userId;
  
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

  Map<String, dynamic> toJson() => {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'emotions': emotions,
      'scenes': scenes,
      'date': date,
      if (interpretation != null) 'interpretation': interpretation,
      if (userId != null) 'userId': userId,
    };
  }

  factory DreamModel.fromJson(Map<String, dynamic> json) {
    return DreamModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now()),
      emotions: List<String>.from(json['emotions'] ?? []),
      scenes: List<String>.from(json['scenes'] ?? []),
      date: json['date'] ?? '',
      interpretation: json['interpretation'],
      userId: json['userId'],
    );
  }
}

// 梦境数据模型 - 兼容后端字段(emotion_tags/dream_date)和本地字段(emotions/date)
class DreamModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> emotions;
  final List<String> scenes;
  final String date;
  final String? interpretation; // 解析内容（本地） 
  final bool hasInterpretation; // 后端列表标记：服务器已有解析
  final int? serverId; // 后端数字ID

  DreamModel({
    required this.id,
    required this.content,
    required this.createdAt,
    this.emotions = const [],
    this.scenes = const [],
    required this.date,
    this.interpretation,
    this.hasInterpretation = false,
    this.serverId,
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
      'hasInterpretation': hasInterpretation,
      'serverId': serverId,
    };
  }

  factory DreamModel.fromJson(Map<String, dynamic> json) {
    // 兼容后端字段和本地存储字段
    final emotions = (json['emotion_tags'] ?? json['emotions']) as List<dynamic>?;
    final scenes = (json['scene_tags'] ?? json['scenes']) as List<dynamic>?;

    // 日期字段：dream_date(后端) / date(本地) / created_at(后端)
    String dateString = json['dream_date']?.toString() ??
        json['date']?.toString() ??
        '';
    if (dateString.isEmpty && json['created_at'] != null) {
      dateString = json['created_at'].toString().split('T').first;
    }

    // 创建时间
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
        json['created_at']?.toString() ??
            json['createdAt']?.toString() ??
            DateTime.now().toIso8601String(),
      );
    } catch (_) {
      createdAt = DateTime.now();
    }

    // ID：支持int(后端)和string(本地local_xxx)
    final rawId = json['id'];
    final idStr = rawId?.toString() ?? '';

    return DreamModel(
      id: idStr.startsWith('local_') ? idStr : 'srv_$idStr',
      serverId: rawId is int ? rawId : int.tryParse(idStr),
      content: json['content']?.toString() ?? '',
      createdAt: createdAt,
      emotions: emotions?.map((e) => e.toString()).toList() ?? <String>[],
      scenes: scenes?.map((e) => e.toString()).toList() ?? <String>[],
      date: dateString,
      interpretation: json['interpretation']?.toString(),
      hasInterpretation:
          json['has_interpretation'] == true || json['hasInterpretation'] == true,
    );
  }
}

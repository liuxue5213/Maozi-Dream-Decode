// 百科数据模型
class EncyclopediaModel {
  final String id;
  final String title;
  final String category;
  final String brief;
  final String? content;

  EncyclopediaModel({
    required this.id,
    required this.title,
    required this.category,
    required this.brief,
    this.content,
  });

  factory EncyclopediaModel.fromJson(Map<String, dynamic> json) {
    final sections = <String>[
      if (json['traditional_meaning'] != null) '传统解读：${json['traditional_meaning']}',
      if (json['psychology_meaning'] != null) '心理学视角：${json['psychology_meaning']}',
      if (json['culture_meaning'] != null) '文化象征：${json['culture_meaning']}',
      if (json['advice'] != null) '自我觉察建议：${json['advice']}',
    ];
    final brief = json['brief'] ?? json['psychology_meaning'] ?? json['traditional_meaning'] ?? '';
    return EncyclopediaModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      brief: brief.toString(),
      content: json['content']?.toString() ?? (sections.isEmpty ? null : sections.join('\n\n')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'brief': brief,
      'content': content,
    };
  }
}

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
    return EncyclopediaModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      brief: json['brief'] ?? '',
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'brief': brief,
      if (content != null) 'content': content,
    };
  }
}

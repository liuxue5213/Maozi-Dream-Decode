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
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      brief: json['brief']?.toString() ?? '',
      content: json['content']?.toString(),
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

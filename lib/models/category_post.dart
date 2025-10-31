import 'post.dart';

class CategoryPost {
  final int id;
  final String name;
  final String type;
  final int? parentId;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Post> posts;

  CategoryPost({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.posts,
  });

  factory CategoryPost.fromJson(Map<String, dynamic> json) {
    return CategoryPost(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      parentId: json['parentId'] as int?,
      userId: json['userId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      posts:
          (json['posts'] as List<dynamic>?)
              ?.map((post) => Post.fromJson(post as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'parentId': parentId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'posts': posts.map((post) => post.toJson()).toList(),
    };
  }
}

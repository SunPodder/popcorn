import 'post.dart';

class SearchResponse {
  final List<Post> posts;

  SearchResponse({required this.posts});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      posts:
          (json['posts'] as List<dynamic>?)
              ?.map((post) => Post.fromJson(post as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'posts': posts.map((post) => post.toJson()).toList()};
  }
}

import 'post.dart';
import 'category_post.dart';

class HomePageResponse {
  final List<CategoryPost> categoryPosts;
  final List<Post> mostVisitedPosts;

  HomePageResponse({
    required this.categoryPosts,
    required this.mostVisitedPosts,
  });

  factory HomePageResponse.fromJson(Map<String, dynamic> json) {
    return HomePageResponse(
      categoryPosts:
          (json['categoryPosts'] as List<dynamic>?)
              ?.map(
                (category) =>
                    CategoryPost.fromJson(category as Map<String, dynamic>),
              )
              .toList() ??
          [],
      mostVisitedPosts:
          (json['mostVisitedPosts'] as List<dynamic>?)
              ?.map((post) => Post.fromJson(post as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryPosts': categoryPosts
          .map((category) => category.toJson())
          .toList(),
      'mostVisitedPosts': mostVisitedPosts
          .map((post) => post.toJson())
          .toList(),
    };
  }
}

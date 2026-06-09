import '../../models/post.dart';
import '../../models/post_detail.dart';

abstract class BaseScraper {
  String get baseUrl;
  
  Future<List<Post>> getHomePosts();
  Future<List<Post>> searchPosts(String query);
  Future<PostDetail> getPostDetail(String id);
}

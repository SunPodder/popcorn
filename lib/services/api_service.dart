import '../models/home_page_response.dart';
import '../models/search_response.dart';
import '../models/post_detail.dart';
import '../core/constants/app_constants.dart';
import 'scrapers/base_scraper.dart';
import 'scrapers/circle_ftp_scraper.dart';
import 'scrapers/media_ftp_scraper.dart';
import 'user_service.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  BaseScraper? _activeScraper;

  void resetScraper() {
    _activeScraper = null;
  }

  Future<void> _ensureScraper() async {
    if (_activeScraper != null) return;

    final userService = UserService();
    final url = userService.activeServerUrl ?? AppConstants.baseUrl;
    final type = userService.activeServerType ?? 'circle';

    if (type == 'media') {
      _activeScraper = MediaFtpScraper(url);
    } else {
      _activeScraper = CircleFtpScraper(url);
    }
  }

  Future<HomePageResponse> getHomePagePosts() async {
    await _ensureScraper();
    try {
      final posts = await _activeScraper!.getHomePosts();
      return HomePageResponse(
        mostVisitedPosts: posts.take(10).toList(),
        categoryPosts: [], // Simplified for now
      );
    } catch (e) {
      throw Exception('Error fetching home page posts: $e');
    }
  }

  Future<SearchResponse> searchPosts(String query) async {
    await _ensureScraper();
    try {
      final posts = await _activeScraper!.searchPosts(query);
      return SearchResponse(posts: posts);
    } catch (e) {
      throw Exception('Error searching posts: $e');
    }
  }

  Future<PostDetail> getPostDetail(String postId) async {
    await _ensureScraper();
    try {
      return await _activeScraper!.getPostDetail(postId);
    } catch (e) {
      throw Exception('Error fetching post detail: $e');
    }
  }
}

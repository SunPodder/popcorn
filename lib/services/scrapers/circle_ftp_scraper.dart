import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_scraper.dart';
import '../../models/post.dart';
import '../../models/post_detail.dart';
import '../../models/home_page_response.dart';
import '../../models/search_response.dart';
import '../../core/constants/app_constants.dart';

class CircleFtpScraper implements BaseScraper {
  @override
  final String baseUrl;

  CircleFtpScraper(this.baseUrl);

  @override
  Future<List<Post>> getHomePosts() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConstants.apiVersion}/home-page/getHomePagePosts'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final homeResponse = HomePageResponse.fromJson(jsonData);
      
      final List<Post> linearFeed = [];
      linearFeed.addAll(homeResponse.mostVisitedPosts);
      
      for (var category in homeResponse.categoryPosts) {
        if (!AppConstants.excludedCategories.contains(category.name)) {
          linearFeed.addAll(category.posts);
        }
      }
      
      return linearFeed.where((post) => post.quality.isNotEmpty && post.quality != "null").toList();
    } else {
      throw Exception('Failed to load home page: ${response.statusCode}');
    }
  }

  @override
  Future<List<Post>> searchPosts(String query) async {
    final uri = Uri.parse('$baseUrl${AppConstants.apiVersion}/posts').replace(
      queryParameters: {'searchTerm': query, 'order': 'desc'}
    );

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return SearchResponse.fromJson(jsonData).posts;
    } else {
      throw Exception('Failed to search: ${response.statusCode}');
    }
  }

  @override
  Future<PostDetail> getPostDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConstants.apiVersion}/posts/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return PostDetail.fromJson(jsonData);
    } else {
      throw Exception('Failed to load post detail: ${response.statusCode}');
    }
  }
}

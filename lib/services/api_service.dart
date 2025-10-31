import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_page_response.dart';
import '../models/search_response.dart';
import '../models/post_detail.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<HomePageResponse> getHomePagePosts() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.homePageEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return HomePageResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load home page posts: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching home page posts: $e');
    }
  }

  Future<SearchResponse> searchPosts(String query) async {
    try {
      final uri = Uri.parse(
        AppConstants.searchEndpoint,
      ).replace(queryParameters: {'searchTerm': query, 'order': 'desc'});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SearchResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to search posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching posts: $e');
    }
  }

  Future<PostDetail> getPostDetail(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.searchEndpoint}/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return PostDetail.fromJson(jsonData);
      } else {
        throw Exception('Failed to load post detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching post detail: $e');
    }
  }
}

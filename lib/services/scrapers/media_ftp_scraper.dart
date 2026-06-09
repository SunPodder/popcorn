import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_scraper.dart';
import '../../models/post.dart';
import '../../models/post_detail.dart';

class MediaFtpScraper implements BaseScraper {
  @override
  final String baseUrl;

  MediaFtpScraper(this.baseUrl);

  Map<String, String> get _headers => {
        'Accept': '*/*',
        'Content-Type': 'application/json;charset=UTF-8',
        'Origin': baseUrl,
        'Referer': '$baseUrl/data/',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36',
      };

  @override
  Future<List<Post>> getHomePosts() async {
    return searchPosts(''); 
  }

  @override
  Future<List<Post>> searchPosts(String query) async {
    final body = {
      'action': 'get',
      'search': {
        'href': '/data/',
        'pattern': query,
        'ignorecase': true,
      },
    };

    final response = await http.post(
      Uri.parse('$baseUrl/data/'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> searchResults = jsonData['search'] ?? [];
      
      return searchResults.where((item) => item['managed'] == true || (item['href'] as String).endsWith('.mkv') || (item['href'] as String).endsWith('.mp4')).map((item) {
        final href = item['href'] as String;
        final decodedHref = Uri.decodeFull(href);
        final name = decodedHref.split('/').where((s) => s.isNotEmpty).last;
        
        return Post(
          id: href, 
          name: name,
          title: name,
          image: '', 
          imageSm: '',
          quality: 'HD',
          watchTime: '',
          year: _extractYear(name),
          type: href.endsWith('/') ? 'folder' : 'movie',
        );
      }).toList();
    } else {
      throw Exception('Failed to search MediaFTP: ${response.statusCode}');
    }
  }

  @override
  Future<PostDetail> getPostDetail(String id) async {
    String videoUrl = '';
    bool isMovie = id.endsWith('.mkv') || id.endsWith('.mp4');

    if (isMovie) {
      videoUrl = '$baseUrl$id';
    } else if (id.endsWith('/')) {
      // It's a folder, search inside for a video file
      try {
        final body = {
          'action': 'get',
          'search': {
            'href': id,
            'pattern': '',
            'ignorecase': true,
          },
        };

        final response = await http.post(
          Uri.parse('$baseUrl/data/'),
          headers: _headers,
          body: json.encode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final List<dynamic> searchResults = jsonData['search'] ?? [];
          
          // Find first video file
          final videoFile = searchResults.firstWhere(
            (item) => (item['href'] as String).endsWith('.mkv') || (item['href'] as String).endsWith('.mp4'),
            orElse: () => null,
          );

          if (videoFile != null) {
            videoUrl = '$baseUrl${videoFile['href']}';
            isMovie = true;
          }
        }
      } catch (e) {
        // Fallback or log error
      }
    }

    final name = Uri.decodeFull(id).split('/').where((s) => s.isNotEmpty).last;

    return PostDetail(
      id: id,
      name: name,
      title: name,
      type: isMovie ? 'movie' : 'folder',
      content: isMovie ? videoUrl : [],
      userId: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _extractYear(String name) {
    final match = RegExp(r'\((\d{4})\)').firstMatch(name);
    return match?.group(1) ?? '';
  }
}

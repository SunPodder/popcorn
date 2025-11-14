class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // API Configuration
  static const String baseUrl = 'http://new.circleftp.net:5000';
  static const String apiVersion = '/api';

  static const String socketUrl = 'http://109.199.99.168:6969';

  // API Endpoints
  static const String homePageEndpoint =
      '$baseUrl$apiVersion/home-page/getHomePagePosts';
  static const String searchEndpoint = '$baseUrl$apiVersion/posts';

  // Image Base URL (if needed for constructing full image URLs)
  static const String imageBaseUrl = '$baseUrl/uploads';

  // Excluded Categories
  static const List<String> excludedCategories = [
    'PC & Console Games',
    'Software',
  ];

  // App Configuration
  static const String appName = 'Popcorn';
  static const String appVersion = '1.0.0';
}

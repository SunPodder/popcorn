import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'dart:async';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/movie_card.dart';
import '../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Post> _allPosts = [];
  List<Post> _homePosts = []; // Store home page posts separately
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadHomePageData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHomePageData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiService.getHomePagePosts();

      // Create linear feed: mostVisitedPosts first, then randomized category posts
      final List<Post> linearFeed = [];

      // Add all most visited posts first
      linearFeed.addAll(response.mostVisitedPosts);

      // Collect all posts from categories, excluding games and software
      final List<Post> categoryPosts = [];
      for (var category in response.categoryPosts) {
        // Skip excluded categories
        if (!AppConstants.excludedCategories.contains(category.name)) {
          categoryPosts.addAll(category.posts);
        }
      }

      // Shuffle category posts for variety
      categoryPosts.shuffle(Random());

      // Add shuffled category posts
      linearFeed.addAll(categoryPosts);

      linearFeed.retainWhere((post) => (post.quality != "null") && post.quality.isNotEmpty);

      setState(() {
        _homePosts = linearFeed;
        _allPosts = linearFeed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      // If search is empty, show home page posts
      setState(() {
        _allPosts = _homePosts;
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });

      final response = await _apiService.searchPosts(query);

      setState(() {
        // If search returns empty results, show home posts instead
        _allPosts = response.posts.isEmpty ? _homePosts : response.posts;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        // On error, fallback to home posts
        _allPosts = _homePosts;
        _errorMessage = null; // Don't show error, just show home feed
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer (debounce for 500ms)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value);
    });
  }

  double _getChildAspectRatio(double width) {
    // Images are 300x450, so maintain 2:3 aspect ratio (0.666)
    return 0.67;
  }

  double _getMaxCardWidth(double width) {
    // Limit card width to maintain good image quality
    // Since images are 300x450, keep cards around 300px max width
    return 300.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Logo and Search
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                child: Row(
                  children: [
                    // Logo
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 50,
                      height: 50,
                    ),
                    // App Name
                    Text(
                      'Popcorn',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(width: 24),

                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search movies, series...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                            _onSearchChanged(value);
                          },
                          onSubmitted: (value) {
                            _debounceTimer?.cancel();
                            _performSearch(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading || _isSearching)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    if (_isSearching) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Searching...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load content',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadHomePageData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_allPosts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No content available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final aspectRatio = _getChildAspectRatio(
                    constraints.crossAxisExtent,
                  );
                  final maxCardWidth = _getMaxCardWidth(
                    constraints.crossAxisExtent,
                  );

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxCardWidth,
                      childAspectRatio: aspectRatio,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 32,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return MovieCard(post: _allPosts[index]);
                    }, childCount: _allPosts.length),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

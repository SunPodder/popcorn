class Post {
  final int id;
  final String name;
  final String? title;
  final String image;
  final String imageSm;
  final String quality;
  final String watchTime;
  final String year;
  final String type;
  final int? view;

  Post({
    required this.id,
    required this.name,
    this.title,
    required this.image,
    required this.imageSm,
    required this.quality,
    required this.watchTime,
    required this.year,
    required this.type,
    this.view,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      title: json['title'] as String?,
      image: json['image'] as String? ?? '',
      imageSm: json['imageSm'] as String? ?? '',
      quality: json['quality'] as String? ?? '',
      watchTime: json['watchTime'] as String? ?? '',
      year: json['year'] as String? ?? '',
      type: json['type'] as String? ?? '',
      view: json['view'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'image': image,
      'imageSm': imageSm,
      'quality': quality,
      'watchTime': watchTime,
      'year': year,
      'type': type,
      'view': view,
    };
  }
}

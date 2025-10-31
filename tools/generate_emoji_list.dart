import 'dart:io';

String unicodeToEmoji(String hex) {
  final codePoints = hex
      .split('-')
      .map((e) => int.parse(e, radix: 16))
      .toList();
  return String.fromCharCodes(codePoints);
}

void main() {
  final dir = Directory('assets/emojis');
  final emojis =
      dir.listSync().where((f) => f is File && f.path.endsWith('.svg')).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer()
    ..writeln('// AUTO-GENERATED FILE — DO NOT EDIT MANUALLY')
    ..writeln(
      '// Run `dart run tools/generate_emoji_list.dart` to regenerate.\n',
    )
    ..writeln('class Reaction {')
    ..writeln('  final String emoji;')
    ..writeln('  final String assetPath;')
    ..writeln(
      '  const Reaction({required this.emoji, required this.assetPath});',
    )
    ..writeln('}\n')
    ..writeln('final List<Reaction> emojiReactions = [');

  for (final file in emojis) {
    final fileName = file.uri.pathSegments.last;
    final unicodeName = fileName.replaceAll('.svg', '');
    final emoji = unicodeToEmoji(unicodeName);
    final assetPath = file.path.replaceAll('\\', '/');
    buffer.writeln("  Reaction(emoji: '$emoji', assetPath: '$assetPath'),");
  }

  buffer.writeln('];');

  File('lib/generated/emoji_reactions.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());

  print('✅ Generated ${emojis.length} emoji reactions.');
}

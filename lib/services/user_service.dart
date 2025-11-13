import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _nicknameKey = 'user_nickname';
  static const String _userIdKey = 'user_id';

  String? _nickname;
  String? _userId;

  String? get nickname => _nickname;
  String? get userId => _userId;
  String get uniqueUsername => _nickname != null && _userId != null
      ? '$_nickname#${_userId!.substring(0, 4)}'
      : '';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _nickname = prefs.getString(_nicknameKey);
    _userId = prefs.getString(_userIdKey);
  }

  Future<void> setNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    _nickname = nickname;

    // Generate userId if not exists
    if (_userId == null) {
      _userId = const Uuid().v4();
      await prefs.setString(_userIdKey, _userId!);
    }

    await prefs.setString(_nicknameKey, nickname);
  }

  bool get hasNickname => _nickname != null && _nickname!.isNotEmpty;

  String getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return _nickname != null ? '$greeting, $_nickname' : greeting;
  }
}

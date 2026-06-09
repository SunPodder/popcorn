import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _nicknameKey = 'user_nickname';
  static const String _userIdKey = 'user_id';
  static const String _hasScannedKey = 'has_scanned';
  static const String _workingServersKey = 'working_servers';
  static const String _activeServerKey = 'active_server_url';
  static const String _activeServerTypeKey = 'active_server_type';

  String? _nickname;
  String? _userId;
  bool _hasScanned = false;
  List<String> _workingServers = [];
  String? _activeServerUrl;
  String? _activeServerType;

  String? get nickname => _nickname;
  String? get userId => _userId;
  bool get hasScanned => _hasScanned;
  List<String> get workingServers => _workingServers;
  String? get activeServerUrl => _activeServerUrl;
  String? get activeServerType => _activeServerType;

  String get uniqueUsername => _nickname != null && _userId != null
      ? '$_nickname#${_userId!.substring(0, 4)}'
      : '';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _nickname = prefs.getString(_nicknameKey);
    _userId = prefs.getString(_userIdKey);
    _hasScanned = prefs.getBool(_hasScannedKey) ?? false;
    _workingServers = prefs.getStringList(_workingServersKey) ?? [];
    _activeServerUrl = prefs.getString(_activeServerKey);
    _activeServerType = prefs.getString(_activeServerTypeKey);
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

  Future<void> setHasScanned(bool hasScanned) async {
    final prefs = await SharedPreferences.getInstance();
    _hasScanned = hasScanned;
    await prefs.setBool(_hasScannedKey, hasScanned);
  }

  Future<void> setWorkingServers(List<String> servers) async {
    final prefs = await SharedPreferences.getInstance();
    _workingServers = servers;
    await prefs.setStringList(_workingServersKey, servers);
  }

  Future<void> setActiveServer(String url, String type) async {
    final prefs = await SharedPreferences.getInstance();
    _activeServerUrl = url;
    _activeServerType = type;
    await prefs.setString(_activeServerKey, url);
    await prefs.setString(_activeServerTypeKey, type);
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

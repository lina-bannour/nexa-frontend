import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://172.20.24.88:3000';
  static Map<String, dynamic>? _cachedProfile;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _dio.options.headers.remove('Authorization');
    _cachedProfile = null;
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  // AUTH
  static Future<String> login(String email, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    final token = res.data['access_token'];
    await setToken(token);
    return token;
  }

  static Future<String> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    String? filiere,
    String? ecole,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'nom': nom,
      'prenom': prenom,
      if (filiere != null) 'filiere': filiere,
      if (ecole != null) 'ecole': ecole,
    });
    final token = res.data['access_token'];
    await setToken(token);
    return token;
  }

  // PASSWORD RESET
  static Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  static Future<void> resetPassword(
      String email, String code, String newPassword) async {
    await _dio.post('/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword});
  }

  // EMAIL VERIFICATION
  static Future<void> verifyEmail(String email, String code) async {
    await _dio.post('/auth/verify-email', data: {'email': email, 'code': code});
  }

  static Future<void> resendVerification(String email) async {
    await _dio.post('/auth/resend-verification', data: {'email': email});
  }

  // PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/users/me');
    _cachedProfile = res.data;
    return res.data;
  }

  static Map<String, dynamic>? get cachedProfile => _cachedProfile;

  // EXERCISES
  static Future<List<dynamic>> getExercises(
      {String? matiere, String? difficulte}) async {
    final res = await _dio.get('/exercises', queryParameters: {
      if (matiere != null) 'matiere': matiere,
      if (difficulte != null) 'difficulte': difficulte,
    });
    return res.data;
  }

  static Future<Map<String, dynamic>> getExercise(String id) async {
    final res = await _dio.get('/exercises/$id');
    return res.data;
  }

  static Future<Map<String, dynamic>> submitAnswer(
      String exerciseId, String choiceId, int hintsUsed) async {
    final res = await _dio.post('/exercises/$exerciseId/submit',
        data: {'choiceId': choiceId, 'hintsUsed': hintsUsed});
    return res.data;
  }

  // LEADERBOARD
  static Future<List<dynamic>> getLeaderboard({String? filiere}) async {
    final res = await _dio.get('/users/leaderboard', queryParameters: {
      if (filiere != null) 'filiere': filiere,
    });
    return res.data;
  }
  // CONTESTS
static Future<List<dynamic>> getContests({String? filiere}) async {
  final res = await _dio.get('/contests', queryParameters: {
    if (filiere != null) 'filiere': filiere,
  });
  return res.data;
}

static Future<Map<String, dynamic>> getContest(String id) async {
  final res = await _dio.get('/contests/$id');
  return res.data;
}

static Future<Map<String, dynamic>> startContestSession(String contestId) async {
  final res = await _dio.post('/contests/$contestId/session');
  return res.data;
}

static Future<Map<String, dynamic>> submitContestAnswer(
  String sessionId, String questionId, String choiceId, int hintsUsed) async {
  final res = await _dio.post(
    '/contests/sessions/$sessionId/questions/$questionId/submit',
    data: {'choiceId': choiceId, 'hintsUsed': hintsUsed},
  );
  return res.data;
}
}

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
  static Future<List<dynamic>> getLeaderboard({String? filiere, String? period}) async {
    final res = await _dio.get('/users/leaderboard', queryParameters: {
      if (filiere != null) 'filiere': filiere,
      if (period != null) 'period': period,
    });
    return res.data;
  }

  static Future<Map<String, dynamic>> getMyRank({String? filiere, String? period}) async {
    final res = await _dio.get('/users/me/rank', queryParameters: {
      if (filiere != null) 'filiere': filiere,
      if (period != null) 'period': period,
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

  // FORUM
  static Future<List<dynamic>> getForumPosts({String? matiere}) async {
    final res = await _dio.get('/forum', queryParameters: {
      if (matiere != null) 'matiere': matiere,
    });
    return res.data;
  }

  static Future<Map<String, dynamic>> getForumPost(String id) async {
    final res = await _dio.get('/forum/$id');
    return res.data;
  }

  static Future<Map<String, dynamic>> createForumPost({
    required String titre,
    required String contenu,
    required String matiere,
  }) async {
    final res = await _dio.post('/forum', data: {
      'titre': titre,
      'contenu': contenu,
      'matiere': matiere,
    });
    return res.data;
  }

  static Future<Map<String, dynamic>> createForumReply(String postId, String contenu) async {
    final res = await _dio.post('/forum/$postId/replies', data: {'contenu': contenu});
    return res.data;
  }

  // Toggles like/unlike in one call — the backend returns the new state.
  static Future<bool> toggleForumLike(String postId) async {
    final res = await _dio.post('/forum/$postId/like');
    return res.data['liked'] as bool;
  }

  static Future<void> reportForumPost(String postId) async {
    await _dio.patch('/forum/$postId/report');
  }

  // ─── ADMIN ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final res = await _dio.get('/admin/dashboard');
    return res.data;
  }

  // Returns { data: [...], pagination: { page, pageSize, total, totalPages } }.
  // Kept as a Map (not just the list) so callers can drive infinite scroll.
  static Future<Map<String, dynamic>> getAdminUsersPage({
    String? search,
    String? status,
    String? ecole,
    String? filiere,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get('/admin/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
      if (ecole != null && ecole.isNotEmpty) 'ecole': ecole,
      if (filiere != null) 'filiere': filiere,
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data;
    }
    // Fallback in case an older/unpaginated backend is still deployed.
    final list = data as List<dynamic>;
    return {
      'data': list,
      'pagination': {'page': 1, 'pageSize': list.length, 'total': list.length, 'totalPages': 1},
    };
  }

  // Convenience wrapper for callers that just want the flat list (page 1,
  // no infinite scroll) — kept for any screen that doesn't need paging.
  static Future<List<dynamic>> getAdminUsers({String? search, String? status, String? ecole}) async {
    final page = await getAdminUsersPage(search: search, status: status, ecole: ecole);
    return page['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getAdminUserDetail(String id) async {
    final res = await _dio.get('/admin/users/$id');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateAdminUser(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/users/$id', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> updateUserStatus(String id, String status) async {
    final res = await _dio.patch('/admin/users/$id/status', data: {'status': status});
    return res.data;
  }

  static Future<Map<String, dynamic>> updateUserRole(String id, String role) async {
    final res = await _dio.patch('/admin/users/$id/role', data: {'role': role});
    return res.data;
  }

  static Future<List<dynamic>> getAdminExercises() async {
    final res = await _dio.get('/admin/content/exercises');
    return res.data;
  }

  static Future<Map<String, dynamic>> createExercise(Map<String, dynamic> data) async {
    final res = await _dio.post('/exercises', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> updateAdminExercise(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/content/exercises/$id', data: data);
    return res.data;
  }

  static Future<void> deleteAdminExercise(String id) async {
    await _dio.delete('/admin/content/exercises/$id');
  }

  static Future<List<dynamic>> getAdminContests() async {
    final res = await _dio.get('/admin/content/contests');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateAdminContest(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/content/contests/$id', data: data);
    return res.data;
  }

  static Future<void> deleteAdminContest(String id) async {
    await _dio.delete('/admin/content/contests/$id');
  }

  static Future<Map<String, dynamic>> createContest(Map<String, dynamic> data) async {
    final res = await _dio.post('/contests', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getModerationStats() async {
    final res = await _dio.get('/admin/moderation/stats');
    return res.data;
  }

  static Future<List<dynamic>> getReportedPosts() async {
    final res = await _dio.get('/admin/moderation/reported');
    return res.data;
  }

  static Future<List<dynamic>> getAllModeratedPosts() async {
    final res = await _dio.get('/admin/moderation/posts');
    return res.data;
  }

  static Future<Map<String, dynamic>> updatePostStatus(String id, String status) async {
    final res = await _dio.patch('/admin/moderation/posts/$id/status', data: {'status': status});
    return res.data;
  }

  static Future<Map<String, dynamic>> getAdminSettings() async {
    final res = await _dio.get('/admin/settings');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateAdminSettings(Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/settings', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> updateMaintenanceMode(bool enabled) async {
    final res = await _dio.patch('/admin/settings/maintenance', data: {'maintenanceMode': enabled});
    return res.data;
  }
}
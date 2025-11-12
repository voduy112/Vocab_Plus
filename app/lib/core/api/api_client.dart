import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  final Dio dio;
  ApiClient(String base)
      : dio = Dio(
          BaseOptions(
            baseUrl: base,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        ) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (opt, h) async {
      final t = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (t != null) opt.headers['Authorization'] = 'Bearer $t';
      h.next(opt);
    }));
  }
}

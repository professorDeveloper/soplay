import 'package:dio/dio.dart';

import '../models/home_data_model.dart';
import '../models/movie_model.dart';

class HomeDataSource {
  final Dio dio;

  const HomeDataSource({required this.dio});

  Future<HomeDataModel> loadHome() async {
    final results = await dio.get('/contents/home');
    return HomeDataModel.fromJson((results).data as Map<String, dynamic>);
  }
}

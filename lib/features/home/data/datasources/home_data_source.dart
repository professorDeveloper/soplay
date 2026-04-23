import 'package:dio/dio.dart';
import 'package:soplay/features/home/data/models/movie_model.dart';
import 'package:soplay/features/home/domain/entities/home_data_entity.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';

import '../models/home_data_model.dart';

class HomeDataSource {
  final Dio dio;

  const HomeDataSource({required this.dio});

  Future<HomeDataEntity> loadHome() async {
    var data = await dio.post("/contents/home");
    return HomeDataModel.fromJson(data.data);
  }
}

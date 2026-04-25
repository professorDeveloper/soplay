import 'package:dio/dio.dart';

import '../models/home_data_model.dart';

class HomeDataSource {
  final Dio dio;

  const HomeDataSource({required this.dio});

  Future<HomeDataModel> loadHome() async {
    var data = await dio.get("/contents/home");
    return HomeDataModel.fromJson(data.data);
  }
}

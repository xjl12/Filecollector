// 实现下载功能，仅在桌面平台运行
import 'package:dio/dio.dart';

Future<bool> downloadCollectorFileImp(
    int sharekey, String passwd, String? loc, Dio dio) async {
  Map<String, dynamic> query = {'sharekey': sharekey, 'password': passwd};
  try {
    var r = await dio.download('downloadCollectorFiles', loc,
        queryParameters: query);
    if (r.statusCode == 200) {
      return true;
    }
  } finally {}
  return false;
}

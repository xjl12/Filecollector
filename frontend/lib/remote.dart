// 处理前后端数据交互

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'download.dart' if (dart.library.html) 'download_web.dart';

final serverURL = Uri.base.origin;
final _dio = Dio(
    BaseOptions(baseUrl: kIsWeb && !kDebugMode ? '/api/' : '${serverURL}api/'));

const String postRequestNewCollector = 'requestNewCollector';
const String getQueryCollectorKey = 'queryCollectorKey';
const String getGetCollectorState = 'getCollectorState';
const String postUploadColFile = 'uploadColFile';
const String getDownloadCollector = 'downloadCollectorFiles';
const String getDeleteCollector = 'deleteCollector';
const String suc = 'success';

Future<List> queryCollectorKey(int sharekey) async {
  try {
    var r = await _dio
        .get(getQueryCollectorKey, queryParameters: {'sharekey': sharekey});
    if (r.statusCode == 200) {
      if (r.data[suc] == true) {
        return [true, r.data['name'], r.data['prompt']];
      }
    }
  } catch (e) {
    if (kDebugMode) print(e);
  }
  return [false];
}

Future<bool> uploadFile(XFile file, String name, int sharekey) async {
  name = '$name.${file.name.split('.').last}';
  final bytes = await file.readAsBytes();
  var data = FormData.fromMap({
    'sharekey': sharekey,
    'name': name,
    'file': MultipartFile.fromBytes(bytes, filename: name)
  });
  try {
    var r = await _dio.post(postUploadColFile, data: data);
    if (r.statusCode == 200 && r.data[suc] == true) {
      return true;
    }
  } catch (e) {
    if (kDebugMode) print(e);
  }
  return false;
}

Future<List> queryCollectorStatus(int sharekey, String passwd) async {
  try {
    var r = await _dio.get(getGetCollectorState,
        queryParameters: {'sharekey': sharekey, 'password': passwd});
    if (r.statusCode == 200 && r.data[suc]) {
      return [true, r.data['received'], r.data['num'], r.data['name']];
    }
  } catch (e) {
    if (kDebugMode) print(e);
  }
  return [false];
}

Future<bool> deleteCollector(int sharekey, String passwd) async {
  try {
    var r = await _dio.get(getDeleteCollector,
        queryParameters: {'sharekey': sharekey, 'password': passwd});
    if (r.statusCode == 200 && r.data[suc]) return true;
  } catch (e) {
    if (kDebugMode) print(e);
  }
  return false;
}

Future<List> registerNewCollector(
    String name, String prompt, int num, int days) async {
  try {
    var r = await _dio.post(postRequestNewCollector,
        data: {'days': days, 'name': name, 'filename': prompt, 'num': num});
    if (r.statusCode == 200 && r.data[suc]) {
      return [true, r.data['sharekey'], r.data['password']];
    }
  } catch (e) {
    if (kDebugMode) print(e);
  }
  return [false];
}

Future<bool> downloadCollectorFile(
    int sharekey, String passwd, String? loc) async {
  return downloadCollectorFileImp(sharekey, passwd, loc, _dio);
}

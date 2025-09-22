import 'package:cloud_functions/cloud_functions.dart';

class DataService {
  Future<Map<String, dynamic>> analyzeImage(String base64String) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('analyzeImage');

    final res = await callable.call(<String, dynamic>{
      'imageBase64': base64String,
    });

    final data = res.data;
    if (data is! Map) {
      throw Exception('Cloud Functions のレスポンス形式が不正です');
    }
    return Map<String, dynamic>.from(data);
  }
}

import 'package:cloud_functions/cloud_functions.dart';

class DataService {
  Future<String> fetchVisionApiKey() async {
    final callable = FirebaseFunctions.instance.httpsCallable('callExternalApi');
    final res = await callable({});
    final data = res.data;
    if (data is! Map) {
      throw Exception('Cloud Functions のレスポンス形式が不正です');
    }
    final apiKey = data['apiKey'] as String?;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception(
        'VISION_API_KEY が未設定、または取得できませんでした。Cloud Functions のシークレット設定を確認してください。',
      );
    }
    return apiKey;
  }
}

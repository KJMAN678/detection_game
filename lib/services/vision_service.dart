import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path/path.dart' as p;

import '../models/vision_models.dart';

class VisionService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    _initialized = true;
  }

  static Future<String> uploadImage(File file, {String folder = 'images'}) async {
    final storage = FirebaseStorage.instance;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final name = '$ts$ext';
    final ref = storage.ref().child('$folder/$name');
    await ref.putFile(file);
    final bucket = storage.bucket;
    final path = ref.fullPath;
    return 'gs://$bucket/$path';
  }

  static Future<VisionResult> analyzeGsImage(String gsUri, {bool detectObjects = true, bool detectLabels = true}) async {
    final callable = FirebaseFunctions.instance.httpsCallable('analyzeImage');
    final resp = await callable.call<Map<String, dynamic>>({
      'path': gsUri,
      'modes': {'object': detectObjects, 'label': detectLabels},
    });
    return VisionResult.fromJson(resp.data);
  }
}

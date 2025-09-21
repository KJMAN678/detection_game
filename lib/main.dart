import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vision/vision_service.dart';
import 'services/consent_manager.dart';
import 'screens/privacy_consent_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/detail/detail_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/gameplay_screen.dart';
import 'core/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.playIntegrity,
  );

  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: AppInitializer(camera: firstCamera),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.privacyConsent:
              final args = settings.arguments as Map<String, Object?>?;
              final camera = args?['camera'] as CameraDescription?;
              if (camera == null) {
                throw ArgumentError('camera is required for /privacyConsent');
              }
              return MaterialPageRoute(
                builder: (_) => PrivacyConsentScreen(camera: camera),
              );
            case AppRoutes.settings:
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case AppRoutes.gameStart:
              final args = settings.arguments as Map<String, Object?>?;
              final camera = args?['camera'] as CameraDescription?;
              if (camera == null) {
                throw ArgumentError('camera is required for /gameStart');
              }
              return MaterialPageRoute(
                builder: (_) => HomeScreen(camera: camera),
              );
            case AppRoutes.gamePlay:
              final args = settings.arguments as Map<String, Object?>?;
              final camera = args?['camera'] as CameraDescription?;
              final vision = args?['vision'] as VisionService?;
              if (camera == null || vision == null) {
                throw ArgumentError(
                  'camera and vision are required for /gamePlay',
                );
              }
              return MaterialPageRoute(
                builder: (_) => GamePlayScreen(camera: camera, vision: vision),
              );
            case AppRoutes.displayPicture:
              final args = settings.arguments as Map<String, Object?>?;
              final imagePath = args?['imagePath'] as String?;
              final vision = args?['vision'] as VisionService?;
              final usedLabels = args?['usedLabels'] as Set<String>?;
              if (imagePath == null || vision == null) {
                throw ArgumentError(
                  'imagePath and vision are required for /displayPicture',
                );
              }
              return MaterialPageRoute<dynamic>(
                builder: (_) => DisplayPictureScreen(
                  imagePath: imagePath,
                  vision: vision,
                  usedLabels: usedLabels,
                ),
              );
          }
          return null;
        },
      ),
    ),
  );
}

class AppInitializer extends StatefulWidget {
  final CameraDescription camera;

  const AppInitializer({super.key, required this.camera});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkConsentAndNavigate();
  }

  Future<void> _checkConsentAndNavigate() async {
    final hasConsent = await ConsentManager.hasGivenConsent();

    if (!mounted) return;

    if (hasConsent) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.gameStart,
        arguments: {'camera': widget.camera},
      );
    } else {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.privacyConsent,
        arguments: {'camera': widget.camera},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}








// FIXME: 削除
// class _BootstrapScreen extends StatelessWidget {
//   final CameraDescription camera;

//   const _BootstrapScreen({required this.camera});

//   Future<VisionService> _loadVision() async {
//     final callable = FirebaseFunctions.instance.httpsCallable(
//       'callExternalApi',
//     );
//     final res = await callable({});
//     final apiKey = res.data['apiKey'];
//     if (apiKey == null || (apiKey is String && apiKey.trim().isEmpty)) {
//       throw Exception(
//         'VISION_API_KEY が未設定、または取得できませんでした。Cloud Functions のシークレット設定を確認してください。',
//       );
//     }
//     return ClientDirectVisionAdapter(apiKey: apiKey);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<VisionService>(
//       future: _loadVision(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//         if (snapshot.hasError) {
//           return Scaffold(
//             body: Center(child: Text('初期化エラー: ${snapshot.error}')),
//           );
//         }
//         final vision = snapshot.data!;
//         return TakePictureScreen(camera: camera, vision: vision);
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:camera/camera.dart';
import '../services/consent_manager.dart';
import '../main.dart';

class PrivacyConsentScreen extends StatefulWidget {
  final CameraDescription camera;
  
  const PrivacyConsentScreen({
    super.key,
    required this.camera,
  });

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _isLoading = false;

  Future<void> _giveConsent() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ConsentManager.giveConsent();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/gameStart',
          arguments: {'camera': widget.camera},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://inky-tea-139.notion.site/26829a2fd70e809993c9d51c7abad7a2?pvs=73';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection Gameへようこそ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'このアプリを使用するには、プライバシーポリシーへの同意が必要です。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '1. 使用する機能と利用目的',
                      '物体検出ゲームでスコアを取得するために、ユーザーのインカメラまたはアウトカメラを使用します。',
                    ),
                    _buildSection(
                      '2. 権限要求とユーザー同意',
                      'Android の仕様に従い、アプリ起動時またはカメラ機能利用時に、ユーザーの明示的な同意をもってカメラ権限を取得します。',
                    ),
                    _buildSection(
                      '3. 収集・送信されるデータ',
                      'アプリで撮影された画像は、自動的に Google Cloud Vision API に送信されます。これはユーザーの画像から物体を識別し、スコアを算出するための処理です。',
                    ),
                    _buildSection(
                      '4. データの共有および第三者提供',
                      '撮影された画像は、ゲームの処理目的のためにGoogle Cloud Vision API（第三者サービス）に送信されます。',
                    ),
                    _buildSection(
                      '5. セキュリティ対策',
                      '撮影画像は、端末での撮影直後に暗号化された通信（HTTPS）を通じて Vision API に送信され、安全に処理されます。',
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _openPrivacyPolicy,
                      child: const Text('完全なプライバシーポリシーを読む'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('同意しない'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _giveConsent,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('同意する'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '同意することで、上記の条件に従ってアプリを使用することに同意したものとみなされます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/consent_manager.dart';
import '../services/permission_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasConsent = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  DateTime? _consentTimestamp;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasConsent = await ConsentManager.hasGivenConsent();
      final cameraStatus = await PermissionManager.getCameraPermissionStatus();
      final timestamp = await ConsentManager.getConsentTimestamp();

      setState(() {
        _hasConsent = hasConsent;
        _cameraPermissionStatus = cameraStatus;
        _consentTimestamp = timestamp;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('設定の読み込みに失敗しました: $e')));
      }
    }
  }

  Future<void> _withdrawConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同意の撤回'),
        content: const Text('プライバシーポリシーへの同意を撤回しますか？撤回すると、アプリの機能が制限されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('撤回する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ConsentManager.withdrawConsent();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('同意を撤回しました')));
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('撤回に失敗しました: $e')));
        }
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url =
        'https://inky-tea-139.notion.site/26829a2fd70e809993c9d51c7abad7a2?pvs=73';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  Future<void> _sendEmail() async {
    const email = 'kj.fireman5@gmail.com';
    const subject = 'Detection Game - お問い合わせ';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '許可済み';
      case PermissionStatus.denied:
        return '拒否';
      case PermissionStatus.permanentlyDenied:
        return '永続的に拒否';
      case PermissionStatus.restricted:
        return '制限あり';
      case PermissionStatus.limited:
        return '制限付き許可';
      case PermissionStatus.provisional:
        return '仮許可';
    }
  }

  Color _getPermissionStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('設定')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'プライバシー設定',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'プライバシーポリシー同意',
                    _hasConsent ? '同意済み' : '未同意',
                    _hasConsent ? Colors.green : Colors.red,
                  ),
                  if (_consentTimestamp != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '同意日時: ${_consentTimestamp!.toLocal().toString().split('.')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'カメラ権限',
                    _getPermissionStatusText(_cameraPermissionStatus),
                    _getPermissionStatusColor(_cameraPermissionStatus),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.policy),
                  title: const Text('プライバシーポリシーを表示'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openPrivacyPolicy,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('アプリ設定を開く'),
                  subtitle: const Text('権限設定を変更できます'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openAppSettings,
                ),
                if (_hasConsent) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text('同意を撤回する'),
                    subtitle: const Text('プライバシーポリシーへの同意を取り消します'),
                    onTap: _withdrawConsent,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('お問い合わせ'),
                  subtitle: const Text('kj.fireman5@gmail.com'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _sendEmail,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'アプリについて',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Detection Game', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'プライバシーポリシー準拠版',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(
            status,
            style: TextStyle(color: statusColor, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

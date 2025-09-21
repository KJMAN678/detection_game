import 'package:flutter/material.dart';

class RecordingPermissionDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  
  const RecordingPermissionDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('録画許可の確認'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ゲーム中の音声録画機能を使用するため、マイクへのアクセス許可が必要です。'),
          SizedBox(height: 8),
          Text('使用目的:'),
          Text('• ゲーム中の音声録画（オプション機能）'),
          SizedBox(height: 8),
          Text('録画された音声は端末内にのみ保存され、外部に送信されません。'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('許可する'),
        ),
      ],
    );
  }
}

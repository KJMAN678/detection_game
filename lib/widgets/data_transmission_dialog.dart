import 'package:flutter/material.dart';

class DataTransmissionDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  
  const DataTransmissionDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('データ送信の確認'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('撮影した画像をGoogle Cloud Vision APIに送信します。'),
          SizedBox(height: 8),
          Text('送信される情報:'),
          Text('• 撮影した画像データ'),
          SizedBox(height: 8),
          Text('送信されない情報:'),
          Text('• 個人情報（名前、位置情報など）'),
          SizedBox(height: 8),
          Text('画像は物体検出処理後、保存されません。'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('送信する'),
        ),
      ],
    );
  }
}

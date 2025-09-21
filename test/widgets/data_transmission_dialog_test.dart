import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detection_game/widgets/data_transmission_dialog.dart';

void main() {
  testWidgets('DataTransmissionDialog displays title and buttons, and callbacks work', (tester) async {
    var confirmCalled = false;
    var cancelCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: DataTransmissionDialog(
                onConfirm: () {
                  confirmCalled = true;
                },
                onCancel: () {
                  cancelCalled = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    // ウィジェットの基本要素が表示されていること
    expect(find.text('データ送信の確認'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
    expect(find.text('送信する'), findsOneWidget);

    // 送信するボタンで onConfirm が呼ばれること
    await tester.tap(find.text('送信する'));
    await tester.pump();
    expect(confirmCalled, isTrue);

    // キャンセルボタンで onCancel が呼ばれること
    await tester.tap(find.text('キャンセル'));
    await tester.pump();
    expect(cancelCalled, isTrue);
  });
}

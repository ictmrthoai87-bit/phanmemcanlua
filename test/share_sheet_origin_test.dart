import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/core/share_sheet_origin.dart';

void main() {
  testWidgets('iPad share sheet origin must have nonzero size', (tester) async {
    Rect? anchor;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Builder(builder: (context) => Center(
        child: TextButton(
          onPressed: () { anchor = shareSheetOrigin(context); },
          child: const Text('Chia sẻ'),
        ),
      )),
    )));
    await tester.tap(find.text('Chia sẻ'));
    expect(anchor, isNotNull);
    expect(anchor!.width, greaterThan(0));
    expect(anchor!.height, greaterThan(0));
  });
}

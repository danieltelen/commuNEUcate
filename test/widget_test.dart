import 'package:communeucate/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chat bubble renders a message without a sender profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: {'sender_id': null, 'content': 'Found your keys'},
            isMe: true,
          ),
        ),
      ),
    );

    expect(find.text('Found your keys'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/widgets/post_tile.dart';
import 'post_test.dart';

void main() {
  testWidgets('Widget tree mounts properly dengan fake repository', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(items: [
              const Post(userId: 1, id: 1, title: 'Judul Testing', body: 'Isi'),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Aplikasi Siap')),
          ),
        ),
      ),
    );
    expect(find.text('Aplikasi Siap'), findsOneWidget);
  });

  testWidgets('PostTile menampilkan informasi post dengan benar', (WidgetTester tester) async {
    const post = Post(
      userId: 1,
      id: 99,
      title: 'Judul Testing',
      body: 'Deskripsi panjang testing post tile.',
    );

    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostTile(
            post: post,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('99'), findsOneWidget);
    expect(find.text('Judul Testing'), findsOneWidget);
    expect(find.text('Deskripsi panjang testing post tile.'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });
}

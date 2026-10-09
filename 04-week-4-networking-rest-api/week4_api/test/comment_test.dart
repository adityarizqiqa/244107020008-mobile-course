import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/comment_providers.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/repositories/comment_repository.dart';

/// FakeCommentRepository untuk mensimulasikan pemanggilan data tanpa request HTTP sungguhan
class FakeCommentRepository extends CommentRepository {
  FakeCommentRepository({this.items, this.throwError = false, this.errorType})
      : super(Dio());

  final List<Comment>? items;
  final bool throwError;
  final DioExceptionType? errorType;

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: errorType ?? DioExceptionType.connectionError,
        response: errorType == DioExceptionType.badResponse
            ? Response(
                requestOptions: RequestOptions(path: '/comments'),
                statusCode: 500,
              )
            : null,
      );
    }
    return items ?? const [];
  }
}

void main() {
  group('Comment Model Tests', () {
    test('fromJson aman terhadap field yang hilang (default value fallback)', () {
      // Meniru response API di mana beberapa field hilang / null
      final json = {
        'id': 1,
        // postId, name, email, body tidak ada dalam payload
      };

      final comment = Comment.fromJson(json);

      // Memastikan nilai fallback default terisi dengan aman tanpa runtime error
      expect(comment.id, 1);
      expect(comment.postId, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('Edge Case: fromJson menangani numeric casting dan null pada seluruh field', () {
      // Menguji kondisi ekstrem: semua key ada namun bernilai null,
      // serta angka berupa tipe num bertipe desimal (misal 10.0)
      final edgeCaseJson = <String, dynamic>{
        'postId': 10.0,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(edgeCaseJson);

      expect(comment.postId, 10);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('toJson mengembalikan Map yang sesuai', () {
      const comment = Comment(
        postId: 1,
        id: 101,
        name: 'Aditya',
        email: 'aditya@example.com',
        body: 'Tes komentar',
      );

      final json = comment.toJson();

      expect(json['postId'], 1);
      expect(json['id'], 101);
      expect(json['name'], 'Aditya');
      expect(json['email'], 'aditya@example.com');
      expect(json['body'], 'Tes komentar');
    });
  });

  group('Friendly Error Message Mapping Tests', () {
    test('Memetakan timeout error', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(friendlyCommentErrorMessage(err), contains('timeout'));
    });

    test('Memetakan connection error', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyCommentErrorMessage(err), contains('Tidak dapat terhubung'));
    });

    test('Memetakan status code 404', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 404,
        ),
      );
      expect(friendlyCommentErrorMessage(err), contains('404'));
    });

    test('Memetakan status code 500', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 500,
        ),
      );
      expect(friendlyCommentErrorMessage(err), contains('500'));
    });
  });

  group('Comment Provider Tests', () {
    test('Provider sukses memuat list komentar dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          commentRepositoryProvider.overrideWithValue(
            FakeCommentRepository(items: [
              const Comment(
                postId: 1,
                id: 1,
                name: 'Commenter',
                email: 'user@test.com',
                body: 'Great post!',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final comments = await container.read(commentListProvider(1).future);

      expect(comments.length, 1);
      expect(comments.first.name, 'Commenter');
      expect(comments.first.body, 'Great post!');
    });

    test('Provider menghasilkan AsyncError saat terjadi kegagalan jaringan', () async {
      final container = ProviderContainer(
        overrides: [
          commentRepositoryProvider.overrideWithValue(
            FakeCommentRepository(
              throwError: true,
              errorType: DioExceptionType.connectionError,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(commentListProvider(1).future);
        fail('Seharusnya melempar exception');
      } catch (err) {
        expect(err, isA<DioException>());
        expect(friendlyCommentErrorMessage(err), contains('Tidak dapat terhubung'));
      }
    });
  });
}

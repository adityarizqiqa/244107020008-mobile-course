import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/post.dart';
import '../pages/post_detail_page.dart';

/// Widget reusable untuk baris item Post dalam ListView
class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    this.onTap,
  });

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(post.id.toString()),
      ),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ??
          () {
            try {
              context.push('/post/${post.id}');
            } catch (_) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(postId: post.id),
                ),
              );
            }
          },
    );
  }
}

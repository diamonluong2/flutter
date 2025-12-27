import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../utils/constants.dart';
import '../utils/blacklist.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _commentController.addListener(() {
      // Clear error when user types
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.fetchComments(widget.post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    // Kiểm tra blacklist trước khi tạo comment
    final bannedWords = Blacklist.checkContent(content);
    if (bannedWords != null) {
      setState(() {
        _errorMessage = Blacklist.getErrorMessage(bannedWords);
      });
      return;
    }

    // Clear error nếu không có vi phạm
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final postProvider = context.read<PostProvider>();
      await postProvider.addComment(widget.post.id, content);

      if (mounted) {
        // Kiểm tra nếu có lỗi từ provider
        if (postProvider.error != null) {
          setState(() {
            _errorMessage = postProvider.error;
          });
        } else {
          // Chỉ clear và fetch comments nếu không có lỗi
          _fetchComments();
          _commentController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Detail'), centerTitle: true),
      body: Column(
        children: [
          // Post Card
          Consumer<PostProvider>(
            builder: (context, postProvider, child) {
              final post = postProvider.posts.firstWhere(
                (p) => p.id == widget.post.id,
                orElse: () => widget.post,
              );
              return PostCard(post: post);
            },
          ),

          // Comments Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  // Comments List
                  Expanded(
                    child: Consumer<PostProvider>(
                      builder: (context, postProvider, child) {
                        print('widget.post.id: ${widget.post.id}');
                        final comments = postProvider.getComments(
                          widget.post.id,
                        );
                        print('comments: $comments');
                        if (comments.isEmpty) {
                          return const Center(child: Text('No comments yet'));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(AppSizes.paddingM),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppSizes.paddingM,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppSizes.paddingM,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          child: Text(
                                            comment.author.username[0]
                                                .toUpperCase(),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppSizes.paddingS,
                                        ),
                                        Text(
                                          comment.author.username,
                                          style: AppTextStyles.body2.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          comment.createdAt.toString(),
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSizes.paddingS),
                                    Text(comment.content),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Comment Input
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _errorMessage != null
                                          ? Colors.red
                                          : AppColors.border,
                                      width: _errorMessage != null ? 2 : 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _errorMessage != null
                                          ? Colors.red
                                          : AppColors.border,
                                      width: _errorMessage != null ? 2 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _errorMessage != null
                                          ? Colors.red
                                          : AppColors.primary,
                                      width: _errorMessage != null ? 2 : 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingM),
                            IconButton(
                              onPressed: _isLoading ? null : _addComment,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSizes.paddingS),
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: AppSizes.paddingS),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

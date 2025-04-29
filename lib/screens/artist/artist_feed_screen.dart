import 'package:flutter/material.dart';
import '../../services/social_media_service.dart';
import '../../services/payment_service.dart';

class ArtistFeedScreen extends StatefulWidget {
  final String artistId;

  const ArtistFeedScreen({Key? key, required this.artistId}) : super(key: key);

  @override
  _ArtistFeedScreenState createState() => _ArtistFeedScreenState();
}

class _ArtistFeedScreenState extends State<ArtistFeedScreen> {
  final SocialMediaService _socialMediaService = SocialMediaService();
  final PaymentService _paymentService = PaymentService();
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final posts = await _socialMediaService.fetchPosts();
    setState(() {
      _posts = posts;
    });
  }

  Future<void> _addComment(String postId, String content) async {
    await _socialMediaService.addComment(postId: postId, userId: 'user123', content: content);
    _fetchPosts();
  }

  Future<void> _likePost(String postId) async {
    await _socialMediaService.likePost(postId: postId, userId: 'user123');
    _fetchPosts();
  }

  Future<void> _donateToArtist(String artistId) async {
    try {
      await _paymentService.processPayment(amount: '10.00', currency: 'USD');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your donation!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Feed'),
      ),
      body: _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post['image_url'] != null)
                          Image.network(post['image_url']),
                        const SizedBox(height: 8.0),
                        Text(
                          post['content'],
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Posted on: ${post['created_at']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up),
                              onPressed: () => _likePost(post['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.comment),
                              onPressed: () async {
                                final comment = await _showCommentDialog();
                                if (comment != null) {
                                  _addComment(post['id'], comment);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.monetization_on),
                              onPressed: () => _donateToArtist(widget.artistId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<String?> _showCommentDialog() async {
    String? comment;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a Comment'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Enter your comment'),
            onChanged: (value) {
              comment = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
    return comment;
  }
}
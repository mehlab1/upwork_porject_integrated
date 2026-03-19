import 'package:flutter/material.dart';

class JmEditPostScreen extends StatefulWidget {
  final String postId;
  final String initialContent;

  const JmEditPostScreen({
    super.key,
    required this.postId,
    required this.initialContent,
  });

  @override
  State<JmEditPostScreen> createState() => _JmEditPostScreenState();
}

class _JmEditPostScreenState extends State<JmEditPostScreen> {
  late TextEditingController _postController;

  @override
  void initState() {
    super.initState();
    _postController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _postController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Edit your post...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Handle post update
                Navigator.pop(context);
              },
              child: const Text('Update Post'),
            ),
          ],
        ),
      ),
    );
  }
}
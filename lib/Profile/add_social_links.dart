import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSocialLinksScreen extends StatefulWidget {
  const AddSocialLinksScreen({Key? key}) : super(key: key);

  @override
  _AddSocialLinksScreenState createState() => _AddSocialLinksScreenState();
}

class _AddSocialLinksScreenState extends State<AddSocialLinksScreen> {
  final _formKey = GlobalKey<FormState>();
  final CollectionReference users = FirebaseFirestore.instance.collection('Users');
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addSocialLink() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final platform = _platformController.text.trim();
      final url = _urlController.text.trim();

      await users.doc(currentUser.uid).update({
        'SocialLinks.$platform': url,
        'LastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Social link added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add link: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _platformController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Social Link'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Platform',
                  prefixIcon: Icon(Icons.public),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Facebook',
                    child: Text('Facebook'),
                  ),
                  DropdownMenuItem(
                    value: 'Twitter',
                    child: Text('Twitter'),
                  ),
                  DropdownMenuItem(
                    value: 'Instagram',
                    child: Text('Instagram'),
                  ),
                  DropdownMenuItem(
                    value: 'LinkedIn',
                    child: Text('LinkedIn'),
                  ),
                  DropdownMenuItem(
                    value: 'YouTube',
                    child: Text('YouTube'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  _platformController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a platform';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Profile URL',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter profile URL';
                  }
                  if (!Uri.parse(value).isAbsolute) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addSocialLink,
                child: const Text('Add Link'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
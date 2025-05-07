import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final CollectionReference users =
  FirebaseFirestore.instance.collection('Users');
  bool _privateAccount = false;
  bool _activityStatus = true;
  bool _dataSharing = false;
  bool _twoFactorAuth = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await users.doc(currentUser.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final privacy = data['PrivacySettings'] as Map<String, dynamic>? ?? {};
        setState(() {
          _privateAccount = privacy['privateAccount'] ?? false;
          _activityStatus = privacy['activityStatus'] ?? true;
          _dataSharing = privacy['dataSharing'] ?? false;
          _twoFactorAuth = privacy['twoFactorAuth'] ?? false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrivacySettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await users.doc(currentUser.uid).update({
        'PrivacySettings': {
          'privateAccount': _privateAccount,
          'activityStatus': _activityStatus,
          'dataSharing': _dataSharing,
          'twoFactorAuth': _twoFactorAuth,
        },
        'LastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) return;

    final email = currentUser.email!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PasswordChangeDialog(email: email),
    );

    if (result != null && result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  Future<void> _enableTwoFactorAuth() async {
    // This is a placeholder for actual 2FA implementation
    // In a real app, you would integrate with Firebase Auth's 2FA or a service like Twilio
    setState(() {
      _twoFactorAuth = !_twoFactorAuth;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_twoFactorAuth
            ? 'Two-factor authentication will be enabled after verification'
            : 'Two-factor authentication disabled'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePrivacySettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control who can see your information',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Private Account'),
              subtitle: const Text(
                  'Only approved followers can see your content'),
              value: _privateAccount,
              onChanged: (value) {
                setState(() {
                  _privateAccount = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Activity Status'),
              subtitle: const Text(
                  'Show when you were last active to your connections'),
              value: _activityStatus,
              onChanged: (value) {
                setState(() {
                  _activityStatus = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Data Sharing'),
              subtitle: const Text(
                  'Help improve our service by sharing anonymous usage data'),
              value: _dataSharing,
              onChanged: (value) {
                setState(() {
                  _dataSharing = value;
                });
              },
            ),
            const Divider(height: 32),
            const Text(
              'Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Protect your account',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              leading: const Icon(Icons.lock),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text(
                  'Add an extra layer of security to your account'),
              value: _twoFactorAuth,
              onChanged: (value) => _enableTwoFactorAuth(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Deactivate Account',
                style: TextStyle(color: Colors.red),
              ),
              leading: Icon(Icons.delete, color: Colors.red[400]),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Deactivate Account'),
                    content: const Text(
                        'Are you sure you want to deactivate your account? You can reactivate it by logging in again.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Placeholder for account deactivation
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Account deactivation feature will be implemented soon')),
                          );
                        },
                        child: const Text(
                          'Deactivate',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordChangeDialog extends StatefulWidget {
  final String email;

  const PasswordChangeDialog({Key? key, required this.email}) : super(key: key);

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<String> _changePassword() async {
    if (!_formKey.currentState!.validate()) return '';

    if (_newPasswordController.text != _confirmPasswordController.text) {
      return 'New passwords do not match';
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: widget.email,
        password: _currentPasswordController.text,
      );

      final user = FirebaseAuth.instance.currentUser;
      await user?.reauthenticateWithCredential(credential);
      await user?.updatePassword(_newPasswordController.text);

      return 'Password changed successfully!';
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureCurrent ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm new password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Password must be at least 8 characters long',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
            final result = await _changePassword();
            if (result.isNotEmpty) {
              Navigator.pop(context, result);
            }
          },
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Change Password'),
        ),
      ],
    );
  }
}
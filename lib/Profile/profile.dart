import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_year_project_18/Profile/privacySecurity.dart';
import 'package:final_year_project_18/Profile/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'add_social_links.dart';
import 'editProfileScreen.dart';
import 'notification.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  final CollectionReference users = FirebaseFirestore.instance.collection('Users');
  final ImagePicker _picker = ImagePicker();
  bool isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Future<void> _updateProfileImage() async {
    setState(() {
      _isLoadingImage = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await users.doc(currentUser.uid).update({
            'Image': base64Image,
            'LastUpdated': FieldValue.serverTimestamp(),
          });
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update image: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildErrorScreen("User not logged in");
    }

    final ThemeData themeData = isDarkMode
        ? ThemeData.dark().copyWith(
      primaryColor: Colors.blueGrey[800],
      colorScheme: const ColorScheme.dark().copyWith(
        primary: Colors.blueGrey[700]!,
        secondary: Colors.tealAccent,
      ),
      cardTheme: CardTheme(
        color: Colors.blueGrey[900],
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    )
        : ThemeData.light().copyWith(
      primaryColor: Colors.blue,
      colorScheme: const ColorScheme.light().copyWith(
        primary: Colors.blue,
        secondary: Colors.indigoAccent,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.blueGrey[900] : Colors.grey[100],
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: _buildProfileBody(currentUser),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        "My Profile",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: _toggleTheme,
          tooltip: 'Toggle Theme',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          tooltip: 'Settings',
        ),
      ],
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                color: Colors.red[300],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Go to Login"),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBody(User currentUser) {
    return FutureBuilder(
      future: users.doc(currentUser.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorScreen("Error loading profile data");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorScreen("No user data found");
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return _buildProfileContent(userData, currentUser);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Loading Profile...",
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> userData, User currentUser) {
    Uint8List? imageBytes;
    if (userData['Image'] != null && userData['Image'].isNotEmpty) {
      try {
        imageBytes = base64Decode(userData['Image']);
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
      }
    }

    int completionPercentage = _calculateProfileCompletion(userData);

    return FadeTransition(
      opacity: _animation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildProfileHeader(imageBytes, userData, completionPercentage),
              const SizedBox(height: 24),
              _buildInfoSection(userData),
              const SizedBox(height: 16),
              _buildActionsSection(),
              // const SizedBox(height: 16),
              // _buildStatsSection(),
              const SizedBox(height: 16),
              // _buildSocialSection(userData),
              // const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Uint8List? imageBytes, Map<String, dynamic> userData, int completionPercentage) {
    return Card(
      elevation: 8,
      shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              Colors.blueGrey[800]!,
              Colors.blueGrey[900]!,
            ]
                : [
              Colors.grey[400]!,
              Colors.grey[700]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _isLoadingImage
                    ? const CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: CircularProgressIndicator(),
                )
                    : CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Hero(
                    tag: "profileImage",
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue[100],
                      backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                      child: imageBytes == null
                          ? Icon(
                        Icons.person,
                        size: 65,
                        color: isDarkMode ? Colors.blueGrey[300] : Colors.blue[300],
                      )
                          : null,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isDarkMode ? Colors.teal[700] : Colors.blue[300],
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: _updateProfileImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "${userData['Firstname']} ${userData['Lastname']}",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userData['Premium'] == true ? "Premium Member" : "Free Member",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileCompletionIndicator(completionPercentage),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionIndicator(int percentage) {
    Color indicatorColor;
    if (percentage < 50) {
      indicatorColor = Colors.red[400]!;
    } else if (percentage < 80) {
      indicatorColor = Colors.amber[400]!;
    } else {
      indicatorColor = Colors.green[400]!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Profile Completion",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              "$percentage%",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> userData) {
    return Card(
      elevation: 6,
      shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Personal Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, "Email", userData['Email']),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone_outlined, "Phone", userData['PhoneNumber'] ?? 'Not provided'),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              "Joined",
              userData['Registration Date'] ?? 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.blueGrey[700] : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.tealAccent : Colors.blue,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 6,
      shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(Icons.edit, "Edit Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            }),
            const SizedBox(height: 12),
            _buildActionButton(Icons.notifications_outlined, "Notification Settings", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            }),
            const SizedBox(height: 12),
            _buildActionButton(Icons.security, "Privacy & Security", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
              );
            }),
            const SizedBox(height: 12),
            _buildActionButton(Icons.logout, "Log Out", () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("CANCEL"),
                      ),
                      TextButton(
                        onPressed: _logout,
                        child: const Text("LOG OUT"),
                      ),
                    ],
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blueGrey[700] : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDarkMode ? Colors.tealAccent : Colors.blue,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildStatsSection() {
  //   return Card(
  //     elevation: 6,
  //     shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             "Activity Statistics",
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: isDarkMode ? Colors.white : Colors.black87,
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               _buildStatItem("45", "Posts"),
  //               _buildStatItem("1.2K", "Followers"),
  //               _buildStatItem("364", "Following"),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.tealAccent : Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(Map<String, dynamic> userData) {
    final socialLinks = userData['SocialLinks'] as Map<String, dynamic>? ?? {};
    final hasLinks = socialLinks.isNotEmpty;

    return Card(
      elevation: 6,
      shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Social Links",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: isDarkMode ? Colors.tealAccent : Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddSocialLinksScreen()),
                    ).then((_) => setState(() {}));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasLinks)
              _buildSocialRow(Icons.link, "Add Social Links", "Connect your social media profiles", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSocialLinksScreen()),
                ).then((_) => setState(() {}));
              }),
            if (hasLinks)
              Column(
                children: socialLinks.entries.map((entry) {
                  return Column(
                    children: [
                      _buildSocialLinkItem(entry.key, entry.value),
                      if (entry.key != socialLinks.keys.last) const Divider(height: 16),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinkItem(String platform, String url) {
    IconData icon;
    Color color;

    switch (platform.toLowerCase()) {
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'twitter':
        icon = Icons.ac_unit;
        color = const Color(0xFF1DA1F2);
        break;
      case 'instagram':
        icon = Icons.camera_alt_outlined;
        color = const Color(0xFFE1306C);
        break;
      case 'linkedin':
        icon = Icons.link;
        color = const Color(0xFF0077B5);
        break;
      default:
        icon = Icons.link;
        color = isDarkMode ? Colors.tealAccent : Colors.blue;
    }

    return InkWell(
      onTap: () {
        // TODO: Launch URL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $platform: $url')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400]),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove Link'),
                    content: Text('Are you sure you want to remove this $platform link?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    await users.doc(currentUser.uid).update({
                      'SocialLinks.$platform': FieldValue.delete(),
                    });
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$platform link removed')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialRow(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blueGrey[700] : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDarkMode ? Colors.tealAccent : Colors.blue,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              color: isDarkMode ? Colors.tealAccent : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateProfileCompletion(Map<String, dynamic> userData) {
    int totalFields = 7;
    int completedFields = 0;

    if (userData['Firstname'] != null && userData['Firstname'].isNotEmpty) completedFields++;
    if (userData['Lastname'] != null && userData['Lastname'].isNotEmpty) completedFields++;
    if (userData['Email'] != null && userData['Email'].isNotEmpty) completedFields++;
    if (userData['PhoneNumber'] != null && userData['PhoneNumber'].isNotEmpty) completedFields++;
    if (userData['Image'] != null && userData['Image'].isNotEmpty) completedFields++;
    if (userData['Registration Date'] != null && userData['Registration Date'].isNotEmpty) completedFields++;
    if (userData['SocialLinks'] != null && (userData['SocialLinks'] as Map).isNotEmpty) completedFields++;

    return (completedFields / totalFields * 100).round();
  }
}
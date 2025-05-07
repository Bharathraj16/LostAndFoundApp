import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


import '../LostItems/FetchlostItems.dart';
import '../Drawer/Custom_drawer.dart';
import '../Profile/profile.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String? _selectedCategory;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final CollectionReference Found_Items =
  FirebaseFirestore.instance.collection('Found_Items');
  final CollectionReference Users =
  FirebaseFirestore.instance.collection('Users');
  final currentUser = FirebaseAuth.instance;

  final List<String> categories = [
    'Electronics',
    'Documents',
    'Jewelry',
    'Clothing',
    'Bags',
    'Keys',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    // Implement pagination logic here
  }

  Future<void> _refreshItems() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _matchesDateFilter(DocumentSnapshot document) {
    try {
      if (_selectedDate == null) return true;
      if (document['Found Date'] == null) return false;

      final storedDateStr = document['Found Date'].toString().trim();
      final parts = storedDateStr.split(' - ');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final storedDate = DateTime(year, month, day);

      return storedDate.year == _selectedDate!.year &&
          storedDate.month == _selectedDate!.month &&
          storedDate.day == _selectedDate!.day;
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return false;
    }
  }

  bool _matchesCategoryFilter(DocumentSnapshot document) {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) return true;
    return document['Category'] == _selectedCategory;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Modern Search Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                hintText: 'Search by item, location...',
                prefixIcon: Icon(Iconsax.search_normal, color: Theme.of(context).hintColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Iconsax.close_circle, color: Theme.of(context).hintColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // Modern Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Filter Chip
                FilterChip(
                  label: Text(
                    _selectedDate == null
                        ? 'Any date'
                        : DateFormat('MMM d').format(_selectedDate!),
                  ),
                  selected: _selectedDate != null,
                  onSelected: (selected) => _selectDate(context),
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  backgroundColor: Theme.of(context).cardColor,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _selectedDate != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  avatar: Icon(Iconsax.calendar,
                      size: 18,
                      color: _selectedDate != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).hintColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide.none,
                ),
                const SizedBox(width: 8),

                // Category Filter Chip
                FilterChip(
                  label: Text(_selectedCategory ?? 'All categories'),
                  selected: _selectedCategory != null,
                  onSelected: (selected) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return _buildCategoryBottomSheet();
                      },
                    );
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  backgroundColor: Theme.of(context).cardColor,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _selectedCategory != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  avatar: Icon(Iconsax.category,
                      size: 18,
                      color: _selectedCategory != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).hintColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBottomSheet() {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (_, controller) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(category),
                    trailing: _selectedCategory == category
                        ? Icon(Iconsax.tick_circle,
                        color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = _selectedCategory == category ? null : category;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Iconsax.cpu;
      case 'Documents':
        return Iconsax.document;
      case 'Jewelry':
        return Iconsax.gemini;
      case 'Clothing':
        return Iconsax.chart;
      case 'Bags':
        return Iconsax.bag;
      case 'Keys':
        return Iconsax.key;
      default:
        return Iconsax.box;
    }
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/no_results.svg',
              height: 180,
              width: 180,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _searchQuery.isNotEmpty || _selectedDate != null || _selectedCategory != null
                    ? 'Try adjusting your search or filters'
                    : 'Check back later for new found items',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty || _selectedDate != null || _selectedCategory != null)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedDate = null;
                    _selectedCategory = null;
                    _searchController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Clear all filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(DocumentSnapshot document, int index) {
    String base64Image = document['IMAGE'];
    Uint8List bytes;

    try {
      bytes = base64Decode(base64Image);
    } catch (e) {
      debugPrint("Error decoding image: $e");
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "Invalid image data",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showItemDetails(context, document),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with category tag
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.memory(
                          bytes,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(Iconsax.gallery_remove,
                                    size: 48, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            document['Category'] ?? 'Unknown',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Item details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document['Item Name'] ?? 'Unnamed Item',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          document['Item Description'] ?? 'No description',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // Location and date row
                        Row(
                          children: [
                            Icon(Iconsax.location,
                                size: 16, color: Theme.of(context).hintColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                document['Location'] ?? 'Unknown location',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Icon(Iconsax.calendar,
                                size: 16, color: Theme.of(context).hintColor),
                            const SizedBox(width: 6),
                            Text(
                              document['Found Date'] ?? 'Unknown date',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, DocumentSnapshot document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Item Details'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Iconsax.share),
                onPressed: () => _shareItem(document),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Hero image
                Hero(
                  tag: 'item-${document.id}',
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(document['IMAGE'])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Details section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['Item Name'] ?? 'Unnamed Item',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category chip
                      Chip(
                        label: Text(document['Category'] ?? 'Unknown'),
                        backgroundColor: Colors.grey.shade900,
                        labelStyle: TextStyle(
                          color: Colors.white,
                        ),
                        avatar: Icon(
                          _getCategoryIcon(document['Category'] ?? 'Other'),
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        document['Item Description'] ?? 'No description provided',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Details grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 3,
                        children: [
                          _buildDetailTile(
                            Iconsax.location,
                            'Found at',
                            document['Location'] ?? 'Unknown',
                          ),
                          _buildDetailTile(
                            Iconsax.calendar_1,
                            'Found on',
                            document['Found Date'] ?? 'Unknown',
                          ),
                          _buildDetailTile(
                            Iconsax.profile_circle,
                            'Found by',
                            document['Username'] ?? 'Anonymous',
                          ),
                          _buildDetailTile(
                            Iconsax.call,
                            'Contact',
                            document['Phonenumber'] ?? 'Not provided',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contact button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Iconsax.message,color: Colors.white,),
                          label: const Text('Contact Finder'),
                          onPressed: () => _contactFinder(document),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade900),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _shareItem(DocumentSnapshot document) async {
    // Implement share functionality
    // Example: Share.share('Check out this found item: ${document['Item Name']}');
  }

  Future<void> _contactFinder(DocumentSnapshot document) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Contact Finder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.profile_circle,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text('Name'),
                subtitle: Text(
                  document['Username'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.call,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text('Phone'),
                subtitle: Text(
                  document['Phonenumber'] ?? 'Not provided',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  // Implement call functionality
                  // Example: launch('tel:${document['Phonenumber']}');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.sms,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text('Email'),
                subtitle: Text(
                  document['Email'] ?? 'Not provided',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  // Implement email functionality
                  // Example: launch('mailto:${document['Email']}');
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide.none,
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.all(16),
        color: Theme.of(context).cardColor,
        child: SizedBox(
          height: 180,
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).cardColor.withOpacity(0.6),
            highlightColor: Theme.of(context).cardColor.withOpacity(0.9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.white,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Found Items',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Profile()),
              );
            },
            icon: const Icon(Iconsax.user, size: 24),
          ),
        ],
      ),
      drawer: CustomDrawer(context: context),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshItems,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              color: Theme.of(context).colorScheme.primary,
              child: StreamBuilder<QuerySnapshot>(
                stream: Found_Items.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.warning_2,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            "Something went wrong",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please try again later",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshItems,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingShimmer();
                  }

                  final filteredDocs = snapshot.data!.docs.where((document) {
                    final location = document['Location']?.toString() ?? '';
                    final itemName = document['Item Name']?.toString() ?? '';
                    final matchesSearch = _searchQuery.isEmpty ||
                        location.toLowerCase().contains(_searchQuery) ||
                        itemName.toLowerCase().contains(_searchQuery);
                    return matchesSearch &&
                        _matchesDateFilter(document) &&
                        _matchesCategoryFilter(document);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(filteredDocs[index], index);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Navigate to report found item screen
      //   },
      //   backgroundColor: Theme.of(context).colorScheme.primary,
      //   foregroundColor: Colors.white,
      //   elevation: 2,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //   ),
      //   child: const Icon(Iconsax.add),
      // ),
    );
  }
}
import 'dart:convert'; // For base64 decoding
import 'dart:typed_data'; // For Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:flutter/material.dart';
import '../Authentication/reusableWidgets1.dart';

class lostAdmin extends StatefulWidget {
  const lostAdmin({Key? key}) : super(key: key);

  @override
  State<lostAdmin> createState() => _lostAdminState();
}

class _lostAdminState extends State<lostAdmin> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add this
  final categorycontroller = TextEditingController();
  final namecontroller = TextEditingController();
  final datecontroller = TextEditingController();
  final locationcontroller = TextEditingController();
  final descrptioncontroller = TextEditingController();
  late CollectionReference Lost_items;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid ?? '';
    Lost_items = FirebaseFirestore.instance.collection('Lost_items');
  }

  Future<void> Update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      categorycontroller.text = documentSnapshot['Category'];
      namecontroller.text = documentSnapshot['Item Name'];
      datecontroller.text = documentSnapshot['Mising Date'].toString();
      locationcontroller.text = documentSnapshot['Location'];
      descrptioncontroller.text = documentSnapshot['Item Description'];
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            right: 20,
            left: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                keyboardType: TextInputType.text,
                controller: categorycontroller,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.text,
                controller: datecontroller,
                decoration: const InputDecoration(
                  labelText: "Mising Date",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.text,
                controller: locationcontroller,
                decoration: const InputDecoration(
                  labelText: "Lost Within",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.text,
                controller: descrptioncontroller,
                decoration: const InputDecoration(
                  labelText: "Item Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.text,
                controller: namecontroller,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final String name = namecontroller.text;
                    final String category = categorycontroller.text;
                    final String date = datecontroller.text.toString();
                    final String description = descrptioncontroller.text;
                    final String location = locationcontroller.text;

                    if (category.isNotEmpty ||
                        name.isNotEmpty ||
                        date.isNotEmpty ||
                        description.isNotEmpty ||
                        location.isNotEmpty) {
                      await Lost_items.doc(documentSnapshot!.id).update({
                        "Category": category,
                        "Item Name": name,
                        "Mising Date": date,
                        "Location": location,
                        "Item Description": description,
                      });

                      categorycontroller.text = '';
                      namecontroller.text = '';
                      datecontroller.text = '';
                      locationcontroller.text = '';
                      descrptioncontroller.text = '';

                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Item updated successfully",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text("Update"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> delete(String Lost_itemsId) async {
    await Lost_items.doc(Lost_itemsId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        content: Text(
          "Successfully deleted the item",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Lost Items",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade700,
        elevation: 10,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 20, left: 10, right: 10),
        child: StreamBuilder<QuerySnapshot>(
          // Filter by current user's UID
          stream: Lost_items.where('userId', isEqualTo: currentUserId).snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "There was an error loading your items",
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              );
            }

            // Check if there are no items
            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "You haven't reported any lost items yet",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              );
            }

            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                // Fetch the base64 string from Firestore
                String base64Image = document['Image'];
                debugPrint("Base64 String: $base64Image"); // Debug log

                // Decode the base64 string
                Uint8List bytes;
                try {
                  bytes = base64Decode(base64Image);
                  debugPrint("Image decoded successfully!");
                } catch (e) {
                  debugPrint("Error decoding base64 string: $e");
                  return const Center(
                    child: Text(
                      "Invalid image data",
                      style: TextStyle(fontSize: 20, color: Colors.red),
                    ),
                  );
                }

                return Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade700.withOpacity(1.0),
                          Colors.grey.shade300.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            height: 200,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(
                                bytes, // Display the decoded image
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint("Error loading image: $error");
                                  return const Center(
                                    child: Text(
                                      "Failed to load image",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow("Category:", document['Category']),
                        const SizedBox(height: 10),
                        _buildDetailRow("Description:", document['Item Description']),
                        const SizedBox(height: 10),
                        _buildDetailRow("Item Name:", document['Item Name']),
                        const SizedBox(height: 10),
                        _buildDetailRow("Lost Within:", document['Location']),
                        const SizedBox(height: 10),
                        _buildDetailRow("Mising Date:", document['Mising Date']),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () {
                                Update(document);
                              },
                              icon: const Icon(
                                Icons.edit,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                delete(document.id);
                              },
                              icon: const Icon(
                                Icons.delete,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  // Helper method to build a detail row
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.normal),
          ),
        ),
      ],
    );
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Fetchfound extends StatefulWidget {
  const Fetchfound({Key? key}) : super(key: key);

  @override
  State<Fetchfound> createState() => _FetchfoundState();
}

class _FetchfoundState extends State<Fetchfound> {
  final CollectionReference Found_Items =
  FirebaseFirestore.instance.collection('Found_Items');

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
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 20, left: 10, right: 10),
        child: StreamBuilder<QuerySnapshot>(
          stream: Found_Items.snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      "Something went wrong",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please try again later",
                      style: TextStyle(
                          color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 48, color: Theme.of(context).hintColor),
                    const SizedBox(height: 16),
                    Text(
                      "No found items yet",
                      style: TextStyle(
                          color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                String base64Image = document['IMAGE'];
                Uint8List bytes;

                try {
                  // Handle both raw base64 and data URI formats
                  if (base64Image.startsWith('data:image')) {
                    base64Image = base64Image.split(',').last;
                  }
                  bytes = base64Decode(base64Image);
                } catch (e) {
                  debugPrint("Error decoding image: $e");
                  return Card(
                    margin: const EdgeInsets.all(16),
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

                return Card(
                  margin: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () => _showItemDetails(context, document),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          child: Image.memory(
                            bytes,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(Icons.broken_image,
                                      size: 48, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document['Item Name'] ?? 'Unnamed Item',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                document['Item Description'] ?? 'No description',
                                style: TextStyle(
                                    color: Theme.of(context).hintColor),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 4),
                                  Text(document['Location'] ?? 'Unknown location'),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 4),
                                  Text(document['Found Date'] ?? 'Unknown date'),
                                ],
                              ),
                            ],
                          ),
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

  void _showItemDetails(BuildContext context, DocumentSnapshot document) {
    final phoneNumber = document['Phonenumber']?.toString() ?? '';
    final email = document['Email']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Found by'),
                subtitle: Text(
                  document['Username'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(
                  phoneNumber.isNotEmpty ? phoneNumber : 'Not available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: phoneNumber.isNotEmpty ? Colors.blue : null,
                  ),
                ),
                onTap: phoneNumber.isNotEmpty
                    ? () => _makePhoneCall(phoneNumber)
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(
                  email.isNotEmpty ? email : 'Not available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: email.isNotEmpty ? Colors.blue : null,
                  ),
                ),
                onTap: email.isNotEmpty ? () => _sendEmail(email) : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone app';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch email app';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
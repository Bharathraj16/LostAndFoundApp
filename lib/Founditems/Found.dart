import 'package:final_year_project_18/Founditems/Fetchfoundadmin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:image_picker/image_picker.dart';

import '../Authentication/reusableWidgets1.dart';

class Found extends StatefulWidget {
  const Found({Key? key}) : super(key: key);

  @override
  State<Found> createState() => _FoundState();
}

class _FoundState extends State<Found> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add this
  final categorycontroller = TextEditingController();
  final namecontroller = TextEditingController();
  final datecontroller = TextEditingController();
  final locationcontroller = TextEditingController();
  final descrptioncontroller = TextEditingController();
  final phonenumbercontoller = TextEditingController();
  final ownercontroller = TextEditingController();
  final emailcontroller = TextEditingController();
  File? _photo;
  final ImagePicker _picker = ImagePicker();

  //* Refactored code for image picker
  Future<void> getImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _photo = File(image.path);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FOUND ITEMS",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade700, // Modern color
        elevation: 10, // Adds shadow
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(top: 30, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Bigtext(
                    text: "Have you Found Something?",
                  ),
                ),
                Space(),
                Center(
                  child: Smalltext(
                    text: "Fill in the details about the Item in the fields below",
                  ),
                ),
                Space(),
                _buildTextField(ownercontroller, "Finder Name", TextInputType.text),
                const SizedBox(height: 10),
                _buildTextField(emailcontroller, "Owner Email Address", TextInputType.emailAddress),
                const SizedBox(height: 10),
                _buildTextField(phonenumbercontoller, "Finder Phone number", TextInputType.number),
                const SizedBox(height: 10),
                Center(child: Bigtext(text: "Upload Find Item")),
                _buildImagePicker(),
                const SizedBox(height: 30),
                _buildTextField(categorycontroller, "Item Category", TextInputType.text),
                const SizedBox(height: 10),
                _buildTextField(namecontroller, "Item Name", TextInputType.text),
                const SizedBox(height: 10),
                _buildDatePicker(),
                const SizedBox(height: 10),
                _buildTextField(locationcontroller, "Location", TextInputType.text),
                const SizedBox(height: 10),
                _buildTextField(descrptioncontroller, "Description of the Lost item", TextInputType.text, maxLines: 6),
                const SizedBox(height: 20),
                _buildSubmitButton(context),
                Space(),
                _buildAccessButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType keyboardType, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: const BorderSide(width: 2, color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 2, color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 30, right: 30),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: () {
                _showPicker(context);
              },
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade700.withOpacity(0.1),
                child: _photo != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.file(
                    _photo!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  width: 100,
                  height: 100,
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextField(
      controller: datecontroller,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        labelText: "Select Find date",
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 2, color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      readOnly: true,
      onTap: () async {
        DateTime? pickeddate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2200),
        );
        if (pickeddate != null) {
          String dateformat = DateFormat("dd - MM - yyyy").format(pickeddate);
          setState(() {
            datecontroller.text = dateformat.toString();
          });
        } else {
          debugPrint("No date selected");
        }
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        onPressed: () async {
          // Get current user
          final currentUser = _auth.currentUser;
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 2),
                content: Text(
                  "You must be logged in to submit",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
            return;
          }

          // Validate all fields
          if (categorycontroller.text.isEmpty ||
              namecontroller.text.isEmpty ||
              datecontroller.text.isEmpty ||
              phonenumbercontoller.text.isEmpty ||
              locationcontroller.text.isEmpty ||
              emailcontroller.text.isEmpty ||
              ownercontroller.text.isEmpty ||
              descrptioncontroller.text.isEmpty ||
              _photo == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 2),
                content: Text(
                  "Please fill all fields and select an image",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            );
            return; // Exit if any field is empty or no image is selected
          }

          try {
            // Convert the image to base64
            List<int> imageBytes = _photo!.readAsBytesSync();
            String base64Image = base64Encode(imageBytes);

            // Store data in Firestore with user UID
            await firestore.collection('Found_Items').doc().set({
              "IMAGE": base64Image, // Store base64 string
              'Category': categorycontroller.text,
              'Item Name': namecontroller.text,
              'Found Date': datecontroller.text.toString(),
              'Location': locationcontroller.text,
              "Item Description": descrptioncontroller.text,
              "Phonenumber": phonenumbercontoller.text.toString(),
              "Username": ownercontroller.text,
              "Email": emailcontroller.text,
              "userId": currentUser.uid, // Add the user's UID
              "timestamp": FieldValue.serverTimestamp(), // Add timestamp for sorting
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 2),
                content: Text(
                  "Details submitted successfully",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            );

            // Clear all input fields and reset the image
            setState(() {
              categorycontroller.clear();
              namecontroller.clear();
              datecontroller.clear();
              phonenumbercontoller.clear();
              locationcontroller.clear();
              emailcontroller.clear();
              ownercontroller.clear();
              descrptioncontroller.clear();
              _photo = null; // Reset the image
            });
          } catch (e) {
            // Handle any errors
            debugPrint("Error: $e"); // Debug log
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 2),
                content: Text(
                  "An error occurred. Please try again.",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade900,
          shadowColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          "Submit Details",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAccessButton(BuildContext context) {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const FetchAdmin()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade900,
          shadowColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          "Access Found Items",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  await getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  await getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
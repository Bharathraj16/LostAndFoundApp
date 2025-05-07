import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'Auth.dart';
import 'Login_screen.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  File? _photo;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final TextEditingController Fnamecontroller = TextEditingController();
  final TextEditingController Lnamecontroller = TextEditingController();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final TextEditingController phonenumber = TextEditingController();
  final TextEditingController datecontroller = TextEditingController();

  @override
  void initState() {
    super.initState();
    datecontroller.text = '';
  }

  Future<void> getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _photo = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Convert image to base64 string
  String? _imageToBase64(File? image) {
    if (image == null) return null;
    List<int> imageBytes = image.readAsBytesSync();
    return base64Encode(imageBytes);
  }

  Future<void> registerUser() async {
    if (Fnamecontroller.text.isEmpty ||
        Lnamecontroller.text.isEmpty ||
        emailcontroller.text.isEmpty ||
        datecontroller.text.isEmpty ||
        phonenumber.text.isEmpty ||
        passwordcontroller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill in all the fields",
            style: TextStyle(color: Colors.red),
          ),
          backgroundColor: Colors.greenAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Convert image to base64 string
      String? base64Image = _imageToBase64(_photo);

      // Register user in Firebase Auth
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passwordcontroller.text.trim(),
      );

      // Store user data in Firestore
      await firestore.collection('Users').doc(userCredential.user!.uid).set({
        'Image': base64Image ?? '', // Store base64 string
        'Firstname': Fnamecontroller.text.trim(),
        'Lastname': Lnamecontroller.text.trim(),
        'Email': emailcontroller.text.trim(),
        'Registration Date': datecontroller.text.trim(),
        'PhoneNumber': phonenumber.text.trim(),
        'uid': userCredential.user!.uid, // Add uid field
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account created successfully!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login screen
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Login()));

    } catch (e) {
      debugPrint("Error signing up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent.withOpacity(0.8),
              Colors.lightBlueAccent.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Create your account",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  // Profile Image
                  GestureDetector(
                    onTap: () {
                      _showPicker(context);
                    },
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.cyanAccent,
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
                          : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Text Fields
                  buildTextField("First Name", Fnamecontroller, Icons.person),
                  const SizedBox(height: 20),
                  buildTextField("Last Name", Lnamecontroller, Icons.person),
                  const SizedBox(height: 20),
                  buildTextField("Email", emailcontroller, Icons.email),
                  const SizedBox(height: 20),
                  buildTextField("Phone Number", phonenumber, Icons.phone, inputType: TextInputType.phone),
                  const SizedBox(height: 20),
                  buildDatePicker(),
                  const SizedBox(height: 20),
                  buildTextField("Password", passwordcontroller, Icons.lock, isPassword: true),
                  const SizedBox(height: 30),
                  // Register Button
                  ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      "Register",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sign In Link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
                    },
                    child: Text(
                      "Already have an account? Sign In",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
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

  Widget buildTextField(String hint, TextEditingController controller, IconData icon, {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget buildDatePicker() {
    return TextField(
      controller: datecontroller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Select date",
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
        if (pickedDate != null) {
          datecontroller.text = DateFormat("dd-MM-yyyy").format(pickedDate);
        }
      },
    );
  }
}
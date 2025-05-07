import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget Textfield(
    {required String text,
    required TextEditingController controller,
    required TextInputType? keyboardtype,
    required bool autocorrect,
    required IconData icon,
    IconData? iconData,
    required bool obsecureText}) {
  return TextFormField(
    keyboardType: keyboardtype,
    obscureText: obsecureText,
    autocorrect: autocorrect,
    controller: controller,
    decoration: InputDecoration(
        hoverColor: Colors.blue,
        fillColor: Colors.white,
        filled: false,
        hintText: text,
        prefixIcon: Icon(icon),
        suffixIcon: Icon(iconData),
        label: Text(text),
        border: OutlineInputBorder(
          borderSide: const BorderSide(width: 1, color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        )),
  );
}

Widget fieldtext(String text) {
  return Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      color: Colors.black54,
      fontStyle: FontStyle.normal,
    ),
  );
}

Widget Space() {
  return const SizedBox(
    height: 15,
  );
}

Widget Smalltext({required String text}) {
  return Text(
    text,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget Bigtext({required String text}) {
  return Text(
    text,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    ),
  );
}

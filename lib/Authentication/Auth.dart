
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Home/Homepage.dart';
 class Authentication{
   Future<User?> registeruser({
     required String Firstname,
     required String Lastname,
     required String Email,
     required String password,
     required BuildContext context,
   })async{
     User? user;
     try {
       user = (await FirebaseAuth.instance.
         createUserWithEmailAndPassword(email: Email, password: password)).user;
       if(user != null){
         await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>Homepage()));
         return user;
       }
       else{
         print("User not created");
       }
     }catch(e){
       print(e);
     }
   }

   Future<User?> Loginuser({
     required String Email,
     required String password,
     required BuildContext context,
   })async{
     User? user;
     try {
       user = (await FirebaseAuth.instance.
       signInWithEmailAndPassword(email: Email, password: password)).user;
       if(user != null){
         await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>Homepage()));
         return user;
       }
       else{
       print("No user is created");
       }
     }catch(e){
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           backgroundColor: Colors.greenAccent,
           content: Text(
             "Invalid credentials",
             style: TextStyle(color: Colors.red),
           ),
           duration: Duration(seconds: 2),
         ),
       );
     }
   }
   Future<User?> signoutuser()async{
     User? user;
     try{
       await FirebaseAuth.instance.signOut();

     }catch(e){
       print(
         'flutter error is $e'
       );
     }

   }
 }
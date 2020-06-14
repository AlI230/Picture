import 'package:Picture/root_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:Picture/services/authentication.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return new MaterialApp(
        title: 'TAGgallery',
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(
          primarySwatch: Colors.purple,
          backgroundColor: Colors.white,
          brightness: Brightness.light,
        ),
        home: new RootPage(auth: new Auth()));
  }
}
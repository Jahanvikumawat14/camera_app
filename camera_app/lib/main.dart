import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _getImageFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_image != null) {
      final fileName = DateTime.now().toString() + '.jpg';
    final firebaseStorageRef = FirebaseStorage.instance.ref().child('selfie/$fileName');
    final uploadTask = firebaseStorageRef.putFile(_image!);
    final snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state == TaskState.success) {
      // Image uploaded successfully, get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Now, add the download URL to the "selfie" collection in Firestore
      final firestore = FirebaseFirestore.instance;
      final selfieCollection = firestore.collection('selfie');
      final documentReference = await selfieCollection.add({
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

        // You can also print the document ID of the newly added photo in the "selfie" collection
        print('Image uploaded to Firestore. Document ID: ${documentReference.id}');
      } else {
        // Handle the case where image upload fails
        print('Image upload failed.');
      }
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image to Firebase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? const Text('No image selected.')
                : Image.file(_image!),
            ElevatedButton(
              onPressed: _getImageFromCamera,
              child: const Text('Take a Photo'),
            ),
            ElevatedButton(
              onPressed: _uploadImageToFirebase,
              child: const Text('Upload Image to Firebase'),
            ),
          ],
        ),
      ),
    );
  }
}

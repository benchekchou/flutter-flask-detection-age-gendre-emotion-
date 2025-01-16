import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final picker = ImagePicker();
  Map<String, dynamic>? _result;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null; // Reset the result when a new image is picked
      });
    }
  }

  Future<void> _sendImage() async {
    if (_image == null) return;

    final uri = Uri.parse('http://192.168.1.107:47986/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResponse = json.decode(respStr);
        setState(() {
          _result = jsonResponse; // Store the full response
        });
      } else {
        setState(() {
          _result = {'error': 'Erreur : ${response.statusCode}'};
        });
      }
    } catch (e) {
      setState(() {
        _result = {'error': 'Erreur de connexion : $e'};
      });
    }
  }

  Widget _buildResultCard() {
    if (_result == null) return SizedBox();

    if (_result!.containsKey('error')) {
      return Card(
        color: Colors.redAccent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _result!['error'],
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final predictions = _result!['predictions'] as List<dynamic>;

    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prédictions :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            for (var prediction in predictions)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Âge : ${prediction['age']}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Genre : ${prediction['gender']}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Émotion : ${prediction['emotion']}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Divider(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prédiction Âge/Genre/Émotion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                Image.file(_image!)
              else
                Placeholder(
                  fallbackHeight: 200,
                  fallbackWidth: double.infinity,
                ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: Icon(Icons.camera_alt),
                label: Text('Prendre une photo'),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library),
                label: Text('Choisir une image'),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _sendImage,
                icon: Icon(Icons.upload),
                label: Text('Envoyer l\'image'),
              ),
              SizedBox(height: 16),
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }
}

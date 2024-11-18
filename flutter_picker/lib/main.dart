import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Upload Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final bool _disabled = false;
  bool _selectedFiles = false;
  String? filePath;
  XFile? selectedFile;

  Future<void> _processFiles(List<XFile> files) async {
    for (final XFile file in files) {
      debugPrint('File: ${file.name} (MIME type: ${file.mimeType})');

      // Get bytes from the file
      final Uint8List bytes = await file.readAsBytes();

      // Create a multipart request
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.1.190.238:6589/grade'));
      request.files.add(http.MultipartFile.fromBytes('cppfile', bytes,
          filename: file.name,
          contentType: MediaType('application', 'octet-stream')));

      // Send the request
      var response = await request.send();

      // Read the response
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('File uploaded successfully');
        debugPrint(responseString);

        // Decode the JSON response
        final jsonResponse = jsonDecode(responseString);
        final formattedJson =
            const JsonEncoder.withIndent('  ').convert(jsonResponse);
        print('JSON Response: \n$formattedJson');
      } else {
        debugPrint('File upload failed with status: ${response.statusCode}');
        debugPrint(responseString);
      }
    }
  }

  Future<void> _pickFiles() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'C++ Files',
          extensions: ['cpp'],
        ),
      ],
    );
    if (file != null) {
      setState(() {
        _selectedFiles = true;
        filePath = file.name;
        selectedFile = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Upload Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(text: filePath),
              decoration: const InputDecoration(
                labelText: 'Selected File',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _disabled ? null : _pickFiles,
              child: const Text('Select File'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedFiles
                  ? () async => _processFiles([selectedFile!])
                  : null,
              child: const Text('Send File'),
            ),
          ],
        ),
      ),
    );
  }
}
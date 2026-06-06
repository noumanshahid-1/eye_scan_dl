import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'result_page.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'animated_button.dart'; // Import the AnimatedButton widget

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  Uint8List? _imageBytes;
  String? _imagePath;
  String? _imageName;
  String? _inputImageName;
  Interpreter? _interpreter;
  final int inputSize = 299;
  final int outputSize = 5;
  Map<int, String>? _classLabels;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print('Model loaded successfully');
      print('Input tensor shape: ${_interpreter!.getInputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      String labelsJson = await DefaultAssetBundle.of(context)
          .loadString('assets/class_labels.json');
      Map<String, dynamic> parsedJson = json.decode(labelsJson);
      _classLabels = parsedJson
          .map((key, value) => MapEntry(int.parse(key), value.toString()));
      print('Class labels loaded: $_classLabels');
    } catch (e) {
      print('Error loading labels: $e');
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      await _saveImage(pickedFile);
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _saveImage(pickedFile);
    }
  }

  Future<void> _saveImage(PickedFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = File('${appDir.path}/$fileName');
      await savedImage.writeAsBytes(bytes);

      setState(() {
        _imageBytes = bytes;
        _imagePath = savedImage.path;
        _imageName = fileName;
        print('Saved image name: $_imageName');
      });
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  Future<void> _runInference() async {
    if (_imageBytes == null || _interpreter == null) {
      print('Image bytes or interpreter is null');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(20),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text(
                  "Processing...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      var resizedImage = _resizeAndNormalizeImage(_imageBytes!);
      var inputBuffer = Float32List(1 * inputSize * inputSize * 3);
      inputBuffer.setAll(0, resizedImage);
      var outputBuffer = Float32List(outputSize);

      _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

      var classificationResult = _postprocessOutput(outputBuffer);
      double confidence = classificationResult['confidence'];

      // Introduce a short delay to show the loading indicator
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop();

      if (confidence < 0.3) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Invalid Image"),
              content: const Text(
                  "The uploaded image is not a valid retinal fundus image."),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ResultPage(
              imageBytes: _imageBytes!,
              imagePath: _imagePath!,
              actualLabel: _inputImageName ?? _imageName!,
              result: classificationResult['label'],
              confidence: confidence,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              );
              var scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              );

              return FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop();
      print('Error running inference: $e');
    }
  }

  List<double> _resizeAndNormalizeImage(Uint8List image) {
    var decodedImage = img.decodeImage(image);
    var resizedImage =
        img.copyResize(decodedImage!, width: inputSize, height: inputSize);

    var normalizedImage = Float32List(inputSize * inputSize * 3);
    int index = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        var pixel = resizedImage.getPixel(x, y);
        normalizedImage[index++] = img.getRed(pixel) / 255.0;
        normalizedImage[index++] = img.getGreen(pixel) / 255.0;
        normalizedImage[index++] = img.getBlue(pixel) / 255.0;
      }
    }
    return normalizedImage.toList();
  }

  Map<String, dynamic> _postprocessOutput(Float32List outputBuffer) {
    int predictedClassIndex =
        outputBuffer.indexOf(outputBuffer.reduce((a, b) => a > b ? a : b));
    String predictedClassLabel =
        _classLabels![predictedClassIndex] ?? 'Unknown';
    double confidence = outputBuffer[predictedClassIndex];
    return {'label': predictedClassLabel, 'confidence': confidence};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Upload Image',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: Colors.green,
            height: 3.8,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 30),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Use camera or gallery to identify the disease',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Input Image Name',
                      labelStyle: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 20.0,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _inputImageName = value;
                      });
                    },
                  ),
                ),
                const Center(
                  child: Text(
                    "> Use if input_image label interpreted incorrect",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 300,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageBytes != null
                      ? Image.memory(
                          _imageBytes!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Text(
                            'Upload fundus eye image to detect',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    AnimatedButton(
                      label: 'Camera',
                      onPressed: _getImageFromCamera,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 6),
                      fontSize: 16,
                    ),
                    const SizedBox(width: 30),
                    AnimatedButton(
                      label: 'Gallery',
                      onPressed: _getImageFromGallery,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 6),
                      fontSize: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedButton(
                  label: '<  Detect  >',
                  onPressed: _runInference,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
                  fontSize: 16,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

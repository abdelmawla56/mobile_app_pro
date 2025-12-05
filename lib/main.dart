import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_mjpeg/flutter_mjpeg.dart'; // OLD: ESP32 stream
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:http/http.dart' as http;

// =======================
// ENTRY POINT
// =======================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SymbioTechApp());
}

// =======================
// Main App
// =======================
class SymbioTechApp extends StatelessWidget {
  const SymbioTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BluetoothService(),
      child: MaterialApp(
        title: 'SymbioTech',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
    );
  }
}

// =======================
// Home Page
// =======================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('SymbioTech'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AssistiveButton(
                icon: Icons.visibility,
                label: 'Camera Stream',
                color: Colors.blue,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraStreamPage()),
                ),
              ),
              const SizedBox(height: 25),
              AssistiveButton(
                icon: Icons.front_hand_sharp,
                label: 'Sign Language',
                color: Colors.blueAccent,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignLanguagePage()),
                ),
              ),
              const SizedBox(height: 25),
              AssistiveButton(
                icon: Icons.image_search,
                label: 'Image Prediction (Flask)',
                color: Colors.deepPurple,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TflitePredictPage(),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              AssistiveButton(
                icon: Icons.bluetooth_connected,
                label: 'Connect Device',
                color: Colors.lightBlue,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BluetoothPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================
// Assistive Button Widget
// =======================
class AssistiveButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const AssistiveButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 34),
        label: Text(label),
      ),
    );
  }
}

// =======================
// Drawer
// =======================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                'SymbioTech',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Rate Us'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RateUsPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.contact_mail),
            title: const Text('Contact Us'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactUsPage()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// ThaiModelService (TFLite model loader & runner)
// =======================
class ThaiModelService {
  ThaiModelService._();
  static final ThaiModelService instance = ThaiModelService._();

  tfl.Interpreter? _interpreter;
  bool get initialized => _interpreter != null;

  static const int inputWidth = 224;
  static const int inputHeight = 224;
  static const int inputChannels = 3;

  Future<void> init() async {
    if (_interpreter != null) return;

    try {
      _interpreter = await tfl.Interpreter.fromAsset(
        'assets/models/best_int8 (1).tflite',
      );
      debugPrint('ThaiModelService: Interpreter loaded');

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      debugPrint('TFLite input shape: ${inputTensor.shape}');
      debugPrint('TFLite output shape: ${outputTensor.shape}');
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
    }
  }

  String runOnImage(img.Image image) {
    if (_interpreter == null) {
      return 'Model not initialized';
    }

    final resized = img.copyResize(
      image,
      width: inputWidth,
      height: inputHeight,
    );

    final input = [
      List.generate(
        inputHeight,
            (y) => List.generate(
          inputWidth,
              (x) {
            final pixel = resized.getPixel(x, y);
            final r = pixel.getChannel(img.Channel.red).toInt();
            final g = pixel.getChannel(img.Channel.green).toInt();
            final b = pixel.getChannel(img.Channel.blue).toInt();
            return [r, g, b];
          },
        ),
      ),
    ];

    final outTensor = _interpreter!.getOutputTensor(0);
    final outShape = outTensor.shape;
    final int numClasses = outShape.last;

    final output = List.generate(
      1,
          (_) => List.filled(numClasses, 0.0),
    );

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      debugPrint('Model inference error: $e');
      return 'Error running model';
    }

    int bestIndex = 0;
    double bestScore = output[0][0];

    for (int i = 1; i < numClasses; i++) {
      final v = output[0][i];
      if (v > bestScore) {
        bestScore = v;
        bestIndex = i;
      }
    }

    final percent = (bestScore * 100).toStringAsFixed(1);

    return 'Class $bestIndex ($percent%)';
  }
}

// =======================
// OLD ESP32 MJPEG PREPROCESSORS (COMMENTED OUT)
// =======================
// class AiMjpegPreprocessor extends MjpegPreprocessor {
//   AiMjpegPreprocessor(this.onNewText);
//
//   final void Function(String) onNewText;
//   bool _initStarted = false;
//   int _frameCount = 0;
//   static const int processEveryNFrames = 5;
//
//   @override
//   List<int>? process(List<int> frame) {
//     if (!ThaiModelService.instance.initialized && !_initStarted) {
//       _initStarted = true;
//       ThaiModelService.instance.init();
//       return frame;
//     }
//     if (!ThaiModelService.instance.initialized) {
//       return frame;
//     }
//     _frameCount++;
//     if (_frameCount % processEveryNFrames != 0) {
//       return frame;
//     }
//     try {
//       final bytes = Uint8List.fromList(frame);
//       final img.Image? decoded = img.decodeImage(bytes);
//       if (decoded == null) return frame;
//       final text = ThaiModelService.instance.runOnImage(decoded);
//       onNewText(text);
//     } catch (e) {
//       debugPrint('AI preprocess error: $e');
//     }
//     return frame;
//   }
// }
//
// class FrameCapturePreprocessor extends MjpegPreprocessor {
//   FrameCapturePreprocessor(this.onFrame);
//   final void Function(Uint8List) onFrame;
//   @override
//   List<int>? process(List<int> frame) {
//     onFrame(Uint8List.fromList(frame));
//     return frame;
//   }
// }

// =======================
// Camera Stream Page (DEVICE CAMERA + local AI)
// =======================
class CameraStreamPage extends StatefulWidget {
  const CameraStreamPage({super.key});

  @override
  State<CameraStreamPage> createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  CameraController? _controller;
  bool _initializing = true;
  bool _isProcessing = false;
  String _predictionText = 'Waiting for model output...';

  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initCameraAndModel();
  }

  Future<void> _initCameraAndModel() async {
    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        setState(() {
          _initializing = false;
          _predictionText = 'Camera permission not granted';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _predictionText = 'No cameras found on device';
        });
        return;
      }

      // Use back camera if available, otherwise first
      final CameraDescription camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();

      // Load local TFLite model
      await ThaiModelService.instance.init();

      // Start periodic capture (divide "video" into images)
      _captureTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) => _captureAndPredict(),
      );

      setState(() {
        _initializing = false;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      setState(() {
        _initializing = false;
        _predictionText = 'Error initializing camera: $e';
      });
    }
  }

  Future<void> _captureAndPredict() async {
    if (!mounted) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _isProcessing = false;
        return;
      }

      final text = ThaiModelService.instance.runOnImage(decoded);
      if (mounted) {
        setState(() {
          _predictionText = text;
        });
      }
    } catch (e) {
      debugPrint('Error during capture & predict: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Camera + AI')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _initializing
                  ? const CircularProgressIndicator()
                  : (_controller == null || !_controller!.value.isInitialized)
                  ? const Text('Camera not available')
                  : CameraPreview(_controller!),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Text(
              _predictionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// Sign Language Page (still device camera preview)
// =======================
class SignLanguagePage extends StatefulWidget {
  const SignLanguagePage({super.key});

  @override
  State<SignLanguagePage> createState() => _SignLanguagePageState();
}

class _SignLanguagePageState extends State<SignLanguagePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Language Detection')),
      body: Center(
        child: _controller == null || !_controller!.value.isInitialized
            ? const Text('Initializing camera...')
            : CameraPreview(_controller!),
      ),
    );
  }
}

// =======================
// Bluetooth Page
// =======================
class BluetoothPage extends StatelessWidget {
  const BluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Devices')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: bt.isScanning ? null : bt.startScan,
                  child: const Text("Scan")),
              ElevatedButton(
                  onPressed: bt.isScanning ? bt.stopScan : null,
                  child: const Text("Stop")),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bt.devices.length,
              itemBuilder: (_, index) {
                final result = bt.devices[index];
                return ListTile(
                  title: Text(result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : result.device.remoteId.str),
                  trailing: ElevatedButton(
                      onPressed: () => bt.connect(result),
                      child: const Text("Connect")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// Bluetooth Service (flutter_blue_plus)
// =======================
class BluetoothService extends ChangeNotifier {
  bool isScanning = false;
  List<ScanResult> devices = [];

  StreamSubscription<List<ScanResult>>? _scanSub;

  BluetoothService() {
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool updated = false;

      for (final r in results) {
        if (!devices
            .any((d) => d.device.remoteId.str == r.device.remoteId.str)) {
          devices.add(r);
          updated = true;
        }
      }

      if (updated) notifyListeners();
    });
  }

  Future<void> startScan() async {
    final status = await Permission.location.request();
    if (!status.isGranted) return;

    devices.clear();
    isScanning = true;
    notifyListeners();

    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true);

    isScanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<void> connect(ScanResult result) async {
    try {
      await result.device.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Connect error: $e");
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }
}

// =======================
// Settings Page
// =======================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool vibrationEnabled = true;
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle:
                  const Text('Receive important alerts and updates'),
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() => notificationsEnabled = val);
                  },
                  secondary: const Icon(Icons.notifications_active),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Use vibration for alerts'),
                  value: vibrationEnabled,
                  onChanged: (val) {
                    setState(() => vibrationEnabled = val);
                  },
                  secondary: const Icon(Icons.vibration),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Dark Mode (UI only)'),
                  subtitle: const Text('Preview dark style'),
                  value: darkModeEnabled,
                  onChanged: (val) {
                    setState(() => darkModeEnabled = val);
                  },
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Feedback & Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_rate, color: Colors.amber),
                  title: const Text('Rate the App'),
                  subtitle:
                  const Text('Tell us what you think of SymbioTech'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RateUsPage()),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.contact_mail, color: Colors.blue),
                  title: const Text('Contact Us'),
                  subtitle:
                  const Text('Get help or share your suggestions'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ContactUsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// Rate Us Page
// =======================
class RateUsPage extends StatefulWidget {
  const RateUsPage({super.key});

  @override
  State<RateUsPage> createState() => _RateUsPageState();
}

class _RateUsPageState extends State<RateUsPage> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  void _submitRating() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
    _commentController.clear();
    setState(() => _rating = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate SymbioTech')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'How is your experience with SymbioTech?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  iconSize: 40,
                  onPressed: () {
                    setState(() => _rating = starIndex);
                  },
                  icon: Icon(
                    Icons.star,
                    color: _rating >= starIndex ? Colors.amber : Colors.grey,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Additional comments (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================
// Contact Us Page
// =======================
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  Future<void> _launchEmail() async {
    final uri = Uri.parse(
      'mailto:s-youssef.elmawla@zewailcity.edu.eg?subject=${Uri.encodeComponent('SymbioTech Support')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch email client');
    }
  }

  Future<void> _launchWhatsApp() async {
    const phone = '+201234567890';
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch WhatsApp');
    }
  }

  Future<void> _launchPhoneCall() async {
    const phone = '+201234567890';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch phone dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.support_agent, size: 60, color: Colors.blue),
                    SizedBox(height: 12),
                    Text(
                      'We are here to help!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'If you have any questions, issues, or suggestions, feel free to reach out.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.red),
              title: const Text('Email'),
              subtitle:
              const Text('s-youssef.elmawla@zewailcity.edu.eg'),
              onTap: _launchEmail,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text('WhatsApp'),
              subtitle: const Text('Chat with us on WhatsApp'),
              onTap: _launchWhatsApp,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Phone'),
              subtitle: const Text('Call our support'),
              onTap: _launchPhoneCall,
            ),
          ],
        ),
      ),
    );
  }
}

// =======================
// About Page
// =======================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Assistive App for Deaf and Blind using smart devices.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

// =======================
// TflitePredictPage (DEVICE CAMERA → Flask Prediction)
// =======================
class TflitePredictPage extends StatefulWidget {
  const TflitePredictPage({super.key});

  @override
  State<TflitePredictPage> createState() => _TflitePredictPageState();
}

class _TflitePredictPageState extends State<TflitePredictPage> {
  // For emulator -> Flask running on PC
  final String _baseUrl = "http://10.0.2.2:5000";

  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;

  bool _loading = false;
  String? _prediction;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        setState(() {
          _initializing = false;
          _prediction = 'Camera permission not granted';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _prediction = 'No cameras found';
        });
        return;
      }

      final CameraDescription camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();

      setState(() {
        _initializing = false;
      });
    } catch (e) {
      debugPrint('Error initializing camera for Flask page: $e');
      setState(() {
        _initializing = false;
        _prediction = 'Error initializing camera: $e';
      });
    }
  }

  Future<void> _captureAndSendToServer() async {
    if (!mounted) return;
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera not ready")),
      );
      return;
    }
    if (_capturing || _loading) return;

    _capturing = true;
    setState(() {
      _loading = true;
      _prediction = null;
      _confidence = null;
    });

    try {
      // 1) Capture a frame from device camera
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // 2) Send frame to Flask backend
      final uri = Uri.parse("$_baseUrl/predict");
      final request = http.MultipartRequest("POST", uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: "frame.jpg",
        ),
      );

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        setState(() {
          _prediction = data["predicted_class"]?.toString();
          _confidence = (data["confidence"] as num?)?.toDouble();
        });
      } else {
        setState(() {
          _prediction = "Error ${response.statusCode}: $respStr";
        });
      }
    } catch (e) {
      setState(() {
        _prediction = "Exception: $e";
      });
    } finally {
      _capturing = false;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Camera → Flask Prediction"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _initializing
                  ? const CircularProgressIndicator()
                  : (_controller == null || !_controller!.value.isInitialized)
                  ? const Text('Camera not available')
                  : CameraPreview(_controller!),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _captureAndSendToServer,
                child: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("Capture & Predict (Flask)"),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_prediction != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Prediction: $_prediction",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_confidence != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "Confidence: ${(_confidence! * 100).toStringAsFixed(2)}%",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                "No prediction yet. Press the button to capture a frame and send it.",
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

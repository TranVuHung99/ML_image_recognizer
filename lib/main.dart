import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final CameraController cameraController;
  late List<CameraDescription> _cameras;
  String label = "";
  bool isCameraInit = false;

  int count = 0;

  @override
  void initState() {
    _initCamera();
    _initTfLite();
    super.initState();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    cameraController = CameraController(_cameras[0], ResolutionPreset.max);
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        isCameraInit = true;
      });
      cameraController.startImageStream((image) {
        count++;
        if (count % 10 == 0) {
          count = 0;
          _imageRecognizer(image);
        }
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  Future<void> _imageRecognizer(CameraImage image) async {
    final recognizer = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) => e.bytes).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );
    if(recognizer?.first['confidence'] > 0.9) {
      setState(() {
        label = recognizer?.first["label"];
      });
    }else {
      setState(() {
        label = "Unknown";
      });
    }

  }

  Future<void> _initTfLite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: TextButton(onPressed: isCameraInit ? () {
                  cameraController.pausePreview();
                }: null, child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text("Pause", style: TextStyle(color: Colors.white)),
                )),),
               Expanded(child:  TextButton(onPressed: isCameraInit ? () {
                 cameraController.resumePreview();
               }: null, child: Container(
                 alignment: Alignment.center,
                 width: double.infinity,
                 padding: EdgeInsets.symmetric(vertical: 10),
                 decoration: BoxDecoration(
                     color: Colors.blue,
                     borderRadius: BorderRadius.circular(20)
                 ),
                 child: Text("Continue", style: TextStyle(color: Colors.white),),
               )),),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 350,
              height: 400,
              child: !isCameraInit ? Container() : CameraPreview(cameraController),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            )
          ],
        ));
  }
}

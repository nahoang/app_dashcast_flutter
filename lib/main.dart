import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: PlaybackButton(),
        ));
  }
}

class PlaybackButton extends StatefulWidget {
  @override
  State<PlaybackButton> createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButton> {
  bool _isPlaying = false;

  void _stop() {}

  void _play() async {
    FlutterSound flutterSound = FlutterSound();
    String path = await flutterSound.startPlayer('assets/surf_shimmy.mp3');
    print('startPlayer: $path');
    flutterSound.
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          if (_isPlaying) {
            _stop();
          } else {
            _play();
          }
          setState(() {
            _isPlaying = !_isPlaying;
          });
        },
        icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow));
  }
}

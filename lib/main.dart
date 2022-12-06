import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;


final url = 'https://itsallwidgets.com/podcast/feed';

final pathSuffix = 'dashcast/downloads';

Future<String> _getDownloadPath(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final prefix = dir.uri.path;
  final absolutePath = path.joinAll([prefix, filename]);
  print('absolutePath $absolutePath');
  return absolutePath;
}

class Podcast with ChangeNotifier {
  RssFeed _feed;
  RssItem _selectedItem;
  Map<String, bool> downloadStatus;

  RssFeed get feed => _feed;
  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;
  set selectedItem(RssItem value) {
    _selectedItem = value;
    notifyListeners();
  }

  void download(RssItem item) async {
    final client = http.Client();

    final req = http.Request("GET", Uri.parse(item.guid));
    final res = await client.send(req);
    if (res.statusCode != 200) {
      throw Exception('Unexpected HTTP code: ${res.statusCode}');
    }

    res.stream.listen((bytes) {
      print('Received ${bytes.length} bytes');
    });

    final file = File(await _getDownloadPath(path.split(item.guid).last));

    res.stream.pipe(file.openWrite()).whenComplete(() {
      print('Downloading complete');
    });

    List<

    // print('Running download for ${item.guid}');
    // final req =
    //     http.StreamedRequest('GET', Uri.parse(item.guid));
    // final res = await req.send();
    // if (res.statusCode != 200) {
    //   throw Exception('Unexpected HTTP code: ${res.statusCode}');
    // }
    // print('Starting stream');
    // res.stream.listen((bytes) {
    //   print('Received ${bytes.length} bytes');
    // });

    // final file = File(await _getDownloadPath(path.split(item.guid).last));
    // res.stream.pipe(file.openWrite()).whenComplete(() {
    //   print('Downloading complete');
    // });
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Podcast()..parse(url),
      child: MaterialApp(
        title: 'The Boring Show!',
        home: EpisodesPage(),
      ),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<Podcast>(builder: (context, podcast, _) {
        return podcast.feed != null
            ? EpisodeListView(rssFeed: podcast.feed)
            : Center(
                child: CircularProgressIndicator(),
              );
      }),
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items
          .map(
            (i) => ListTile(
              title: Text(i.title),
              subtitle: Text(
                i.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(Icons.arrow_downward),
                onPressed: () {
                  Provider.of<Podcast>(context, listen: false).download(i);
                  Scaffold.of(context)
                      .showSnackBar(SnackBar(content: Text('Downloading! ${i.title} ')));
                },
              ),
              onTap: () {
                Provider.of<Podcast>(context, listen: false).selectedItem = i;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PlayerPage()),
                );
              },
            ),
          )
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Provider.of<Podcast>(context, listen: false).selectedItem.title,
        ),
      ),
      body: SafeArea(child: Player()),
    );
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context, listen: false);
    return Column(
      children: [
        Flexible(
            flex: 8,
            child: SingleChildScrollView(
              child: Column(children: [
                Image.network(podcast.feed.image.url),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    podcast.selectedItem.description.trim(),
                  ),
                ),
              ]),
            )),
        Flexible(
          flex: 2,
          child: Material(
            elevation: 12,
            child: AudioControls(),
          ),
        ),
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlaybackButtons(),
      ],
    );
  }
}

class PlaybackButtons extends StatefulWidget {
  @override
  _PlaybackButtonState createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButtons> {
  bool _isPlaying = false;
  FlutterSound _sound;
  double _playPosition;
  Stream<PlayStatus> _playerSubscription;

  @override
  void initState() {
    super.initState();
    _sound = FlutterSound();
    _playPosition = 0;
  }

  void _stop() async {
    await _sound.stopPlayer();
    setState(() => _isPlaying = false);
  }

  void _play(String url) async {
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged
      ..listen((e) {
        if (e != null) {
          print(e.currentPosition);
          setState(() => _playPosition = (e.currentPosition / e.duration));
        }
      });
    setState(() => _isPlaying = true);
  }

  void _fastForward() {}

  void _rewind() {}

  @override
  Widget build(BuildContext context) {
    final item = Provider.of<Podcast>(context, listen: false).selectedItem;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Slider(
          value: _playPosition,
          onChanged: null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(icon: Icon(Icons.fast_rewind), onPressed: null),
            IconButton(
              icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  _stop();
                } else {
                  _play(item.guid);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: null,
            ),
          ],
        ),
      ],
    );
  }
}

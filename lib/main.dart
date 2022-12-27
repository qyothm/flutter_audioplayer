import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Audio Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

class PositionData {
  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  static int _nextMediaId = 0;
  late AudioPlayer _audioPlayer;

  final _playlist = ConcatenatingAudioSource(
    children: [
      AudioSource.uri(
        Uri.parse("asset:///assets/audio/Satu.mp3"),
        tag: MediaItem(
          id: '${_nextMediaId++}',
          album: "Joe Flizzow",
          title: "Satu Malam Di Temasek",
          artUri: Uri.parse(
              "https://cdn.tatlerasia.com/tatlerasia/i/2021/11/24183046-joe-flizzow-by-khairul-imran-0320-mg-8282_cover_1200x1800.jpg"),
        ),
      ),
      AudioSource.uri(
        Uri.parse(
            "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3"),
        tag: MediaItem(
          id: '${_nextMediaId++}',
          album: "Science Friday",
          title: "A Salute To Head-Scratching Science",
          artUri: Uri.parse(
              "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
        ),
      ),
      AudioSource.uri(
        Uri.parse(
            "https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3"),
        tag: MediaItem(
          id: '${_nextMediaId++}',
          album: "Science Friday",
          title: "From Cat Rheology To Operatic Incompetence",
          artUri: Uri.parse(
              "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
        ),
      ),
    ],
  );

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(_playlist);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF144771), Color(0xFF071A2C)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<SequenceState?>(
              stream: _audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.sequence.isEmpty ?? true) {
                  return const SizedBox();
                }
                final metadata = state!.currentSource!.tag as MediaItem;
                return MediaMetadata(
                  imageUrl: metadata.artUri.toString(),
                  title: metadata.artist ?? '',
                  artist: metadata.title,
                );
              },
            ),
            const SizedBox(height: 20),
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return ProgressBar(
                  barHeight: 8,
                  baseBarColor: Colors.grey[600],
                  bufferedBarColor: Colors.grey,
                  progressBarColor: Colors.red,
                  thumbColor: Colors.red,
                  timeLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  progress: positionData?.position ?? Duration.zero,
                  buffered: positionData?.bufferedPosition ?? Duration.zero,
                  total: positionData?.duration ?? Duration.zero,
                  onSeek: _audioPlayer.seek,
                );
              },
            ),
            const SizedBox(height: 20),
            Controls(audioPlayer: _audioPlayer),
          ],
        ),
      ),
    );
  }
}

class MediaMetadata extends StatelessWidget {
  const MediaMetadata({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.artist,
  }) : super(key: key);

  final String imageUrl;
  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(2, 4),
                blurRadius: 4,
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 300,
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class Controls extends StatelessWidget {
  const Controls({
    Key? key,
    required this.audioPlayer,
  }) : super(key: key);

  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: audioPlayer.seekToPrevious,
          iconSize: 60,
          color: Colors.white,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (!(playing ?? false)) {
              return IconButton(
                onPressed: audioPlayer.play,
                iconSize: 80,
                color: Colors.white,
                icon: const Icon(Icons.play_arrow_rounded),
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                onPressed: audioPlayer.pause,
                iconSize: 80,
                color: Colors.white,
                icon: const Icon(Icons.pause_rounded),
              );
            }
            return const Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Colors.white,
            );
          },
        ),
        IconButton(
          onPressed: audioPlayer.seekToNext,
          iconSize: 60,
          color: Colors.white,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

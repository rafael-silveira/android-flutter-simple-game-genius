import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Cores do Genius
  final List<Color> geniusColors = [
    Colors.green,
    Colors.red,
    Colors.yellow,
    Colors.blue,
  ];
  final List<String> colorNames = ['green', 'red', 'yellow', 'blue'];

  List<int> sequence = [];
  List<int> userInput = [];
  int score = 0;
  bool isShowingSequence = false;
  bool isGameOver = false;
  String statusText = 'Toque em INICIAR para jogar!';
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      sequence = [];
      userInput = [];
      score = 0;
      isGameOver = false;
      statusText = 'Memorize a sequência!';
    });
    addToSequence();
  }

  void addToSequence() async {
    setState(() {
      userInput = [];
      sequence.add(_randomColorIndex());
      isShowingSequence = true;
      statusText = 'Memorize a sequência!';
    });
    await showSequence();
    setState(() {
      isShowingSequence = false;
      statusText = 'Sua vez!';
    });
  }

  int _randomColorIndex() {
    return (geniusColors.length * (UniqueKey().hashCode % 1000) / 1000).floor();
  }

  Future<void> showSequence() async {
    for (var idx in sequence) {
      await highlightButton(idx);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> highlightButton(int idx) async {
    setState(() {
      _highlighted = idx;
    });
    await _playSound(idx);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _highlighted = -1;
    });
  }

  int _highlighted = -1;
  int _pressed = -1;

  Future<void> _playSound(int idx) async {
    // Toca sons diferentes para cada cor
    await _audioPlayer.play(AssetSource('sounds/${colorNames[idx]}.mp3'));
  }

  void onColorPressed(int idx) {
    if (isShowingSequence || isGameOver) return;
    setState(() {
      userInput.add(idx);
    });
    _playSound(idx);
    if (sequence[userInput.length - 1] != idx) {
      setState(() {
        isGameOver = true;
        statusText = 'Errou! Pontuação: $score';
      });
      return;
    }
    if (userInput.length == sequence.length) {
      setState(() {
        score++;
        statusText = 'Acertou! Próxima rodada...';
      });
      Future.delayed(const Duration(seconds: 1), addToSequence);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genius Flutter'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(statusText, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          Text('Pontuação: $score', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: 4,
                itemBuilder: (context, idx) {
                  final bool isActive = _highlighted == idx || (_pressed == idx && !isShowingSequence && !isGameOver);
                  return GestureDetector(
                    onTapDown: (_) {
                      if (!isShowingSequence && !isGameOver) {
                        setState(() {
                          _pressed = idx;
                        });
                      }
                    },
                    onTapUp: (_) {
                      if (!isShowingSequence && !isGameOver) {
                        setState(() {
                          _pressed = -1;
                        });
                        onColorPressed(idx);
                      }
                    },
                    onTapCancel: () {
                      if (!isShowingSequence && !isGameOver) {
                        setState(() {
                          _pressed = -1;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: isActive
                            ? geniusColors[idx].withOpacity(0.9)
                            : geniusColors[idx].withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(width: 4, color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isShowingSequence ? null : startGame,
            child: const Text('INICIAR'),
          ),
        ],
      ),
    );
  }
}

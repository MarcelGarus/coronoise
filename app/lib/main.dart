import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'inputs/co2_input.dart';
import 'inputs/incidence_input.dart';
import 'inputs/input.dart';
import 'inputs/number_of_people.dart';
import 'song.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final song = Song();
  await song.init();

  // The `CoronaApp` modifies the song.
  runApp(CoronaApp(song));
}

class CoronaApp extends StatelessWidget {
  const CoronaApp(this.song, {Key? key}) : super(key: key);

  final Song song;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coronoise',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        sliderTheme: const SliderThemeData(valueIndicatorColor: Colors.purple),
      ),
      home: MainPage(song),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage(this.song, {Key? key}) : super(key: key);

  final Song song;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _numberOfPeopleInput = NumberOfPeopleInput();
  final _co2LevelInput = Co2Input();
  final _incidenceInput = IncidenceInput();
  final _risks = <double>[];

  double get targetRisk {
    // The magic numbers here don't follow any scientific approach. They are
    // just chosen intuitively to get a risk level that makes sense.
    final risk = (0.1 * log(max(1, _incidenceInput.value))) *
        (3 * _numberOfPeopleInput.value) *
        (3 * (max(1, (_co2LevelInput.value - 500) / 100)));
    return risk.clamp(0.0, 100.0);
  }

  @override
  void initState() {
    super.initState();
    Stream.periodic(const Duration(seconds: 1)).listen((event) {
      setState(() {
        _risks.add(targetRisk);
        print('Risk: $targetRisk');

        widget.song.risk = widget.song.risk.goNearerTo(targetRisk);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Coronoise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_snippet_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return LogPage(risks: _risks);
              }));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),
          Container(
            height: 300,
            width: 20,
            color: Colors.white10,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    height: 3 * widget.song.risk,
                    color: Colors.purpleAccent,
                  ),
                ),
                Column(
                  children: [
                    Spacer(flex: max(1, 100 * (100 - targetRisk).round())),
                    Container(
                      height: 5,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    Spacer(flex: max(1, 100 * targetRisk.round())),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.song.risk.toStringAsFixed(2)),
          const Spacer(),
          InputSlider(_incidenceInput),
          InputSlider(_numberOfPeopleInput),
          InputSlider(_co2LevelInput),
          Container(height: 32),
        ],
      ),
    );
  }
}

class LogPage extends StatelessWidget {
  const LogPage({Key? key, required this.risks}) : super(key: key);

  final List<double> risks;
  String get risksText => risks.join('\n');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => Clipboard.setData(ClipboardData(text: risksText)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [SelectableText('${risks.length} items\n$risksText')],
      ),
    );
    ;
  }
}

class InputSlider extends StatefulWidget {
  const InputSlider(this.input, {Key? key}) : super(key: key);

  final Input input;

  @override
  _InputSliderState createState() => _InputSliderState();
}

class _InputSliderState extends State<InputSlider> {
  bool chooseAutomatically = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: chooseAutomatically,
          onChanged: (value) {
            setState(() => chooseAutomatically = !value!);
            if (chooseAutomatically) {
              widget.input.start();
            } else {
              widget.input.stop();
            }
          },
        ),
        SizedBox(width: 100, child: Text(widget.input.name)),
        Expanded(
          child: Slider(
            min: 0.0,
            max: widget.input.max,
            divisions: widget.input.max.round(),
            label: widget.input.value.toStringAsFixed(1),
            value: widget.input.value,
            onChanged: chooseAutomatically
                ? null
                : (value) => setState(() => widget.input.value = value),
          ),
        ),
      ],
    );
  }
}

extension on double {
  double goNearerTo(double target) {
    const stepSize = 1;

    if (target > this + stepSize) {
      return this + stepSize;
    } else if (target < this - stepSize) {
      return this - stepSize;
    } else {
      return target;
    }
  }
}

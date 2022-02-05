import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'inputs/co2_input.dart';
import 'inputs/incidence_input.dart';
import 'inputs/input.dart';
import 'inputs/number_of_people.dart';
import 'sonifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sonifier = Sonifier();
  await sonifier.init();
  runApp(CoronaApp(sonifier: sonifier));
}

class CoronaApp extends StatelessWidget {
  const CoronaApp({Key? key, required this.sonifier}) : super(key: key);

  final Sonifier sonifier;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coronoise',
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.indigo,
        sliderTheme: const SliderThemeData(
          valueIndicatorColor: Colors.purple,
        ),
      ),
      home: MainPage(sonifier),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage(this.sonifier, {Key? key}) : super(key: key);

  final Sonifier sonifier;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final numberOfPeopleInput = NumberOfPeopleInput();
  final co2LevelInput = Co2Input();
  final incidenceInput = IncidenceInput();
  final _risks = <double>[];

  @override
  void initState() {
    super.initState();
    Stream.periodic(const Duration(seconds: 1)).listen((event) {
      setState(() {
        final risk = (incidenceInput.value +
                numberOfPeopleInput.value +
                co2LevelInput.value)
            .clamp(0.0, 100.0);

        widget.sonifier.risk = widget.sonifier.risk.goNearerTo(risk);
        _risks.add(risk);
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
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              height: 3 * widget.sonifier.risk,
              color: Colors.purpleAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.sonifier.risk.toStringAsFixed(2)),
          const Spacer(),
          InputSlider(incidenceInput),
          InputSlider(numberOfPeopleInput),
          InputSlider(co2LevelInput),
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
            onPressed: () {
              Clipboard.setData(ClipboardData(text: risksText));
            },
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
  bool manualOverride = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: !manualOverride,
          onChanged: (value) {
            setState(() => manualOverride = !value!);
            if (manualOverride) {
              widget.input.stop();
            } else {
              widget.input.start();
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
            semanticFormatterCallback: (value) => '$value st',
            value: widget.input.value,
            onChanged: manualOverride
                ? (value) => setState(() => widget.input.value = value)
                : null,
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

import 'package:flutter/material.dart';
import 'package:path_icon/path_icon.dart';

import 'icons.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Path icon demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    Key key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color _color = Colors.black;
  double _size = 24;
  Duration _duration = Duration(seconds: 1);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Picker(
              values: {
                Colors.black: 'black',
                Colors.red: 'red',
                Colors.pink: 'pink',
                Colors.teal: 'teal',
              },
              value: _color,
              onSelected: (v) => setState(() => _color = v),
            ),
            Picker<double>(
              values: {
                12: 'small',
                24: 'medium',
                64: 'big',
              },
              value: _size,
              onSelected: (v) => setState(() => _size = v),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...icons.map(
                    (x) => Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          color: const Color(0xFFEEEEEE),
                          child: PathIcon(
                            x,
                            color: _color,
                            size: _size,
                          ),
                        ),
                        SizedBox(width: 20),
                        Container(
                          margin: const EdgeInsets.all(10),
                          color: const Color(0xFFEEEEEE),
                          child: AnimatedPathIcon(
                            x,
                            duration: _duration,
                            color: _color,
                            size: _size,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Picker<T> extends StatelessWidget {
  const Picker({
    Key key,
    @required this.value,
    @required this.onSelected,
    @required this.values,
  }) : super(key: key);

  final Map<T, String> values;
  final ValueChanged<T> onSelected;
  final T value;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort((x, y) => x.value.compareTo(x.value));
    return Wrap(
      children: [
        ...entries.map(
          (x) => RaisedButton(
            onPressed: () => onSelected(x.key),
            child: Text(x.value),
          ),
        ),
      ],
    );
  }
}

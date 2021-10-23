import 'package:flutter/material.dart';
import 'package:traffic_congestion/screens/home.dart';

void main() {
  runApp(const TrafficCongestion());
}

//* root class
class TrafficCongestion extends StatelessWidget {
  const TrafficCongestion({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traffic Congestion App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Fredoka'
      ),
      home: const Home(),
    );
  }
}

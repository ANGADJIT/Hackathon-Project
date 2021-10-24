import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:stream_variable/stream_variable.dart';
import 'package:traffic_congestion/utils/api_key.dart';
import 'package:velocity_x/velocity_x.dart';

class Incidents {
  final String fullDesc;
  final double lng;
  final int severity;
  final String shortDesc;
  final int type;
  final bool impacting;
  final int eventCode;
  final String iconUrl;
  final double lat;

  Incidents({
    required this.fullDesc,
    required this.lng,
    required this.severity,
    required this.shortDesc,
    required this.type,
    required this.impacting,
    required this.eventCode,
    required this.iconUrl,
    required this.lat,
  });
}

//* class IncidentsApi
class IncidentsApi {
  //* stream varaible type Incidents
  static late StreamVariable<List<Incidents>> _incidentsStream;

  static late StreamVariable<int> _events;

  //* making it singleton
  static final IncidentsApi _incidentsApi = IncidentsApi.init();
  IncidentsApi.init() {
    _incidentsStream = StreamVariable<List<Incidents>>();
    _incidentsStream.setVariable = [];
    _incidentsStream.variableSink.add(_incidentsStream.getVariable);

    _position = StreamVariable<LatLng>();
    _position.setVariable = LatLng(.0, .0);
    _position.variableSink.add(_position.getVariable);

    _events = StreamVariable<int>();
    _events.setVariable = 0;
    _events.variableSink.add(_events.getVariable);
  }

  factory IncidentsApi() => _incidentsApi;

  static final List<Incidents> _incidents = [];

  //* latitude and logitude varaible
  static late StreamVariable<LatLng> _position;

  //* method for getting data
  static changeData(
      {required double nELa,
      required BuildContext context,
      required double nELo,
      required double sELa,
      required double sELo,
      required double latitude,
      required double longitude}) async {
    _position.setVariable = LatLng(latitude, longitude);
    _position.variableSink.add(_position.getVariable);

    //* delete all from list
    _incidents.clear();

    try {
      final response = await http.get(Uri.parse(
          'http://www.mapquestapi.com/traffic/v2/incidents?key=$apiKey&boundingBox=$nELa,$nELo,$sELa,$sELo&filters=construction,incidents,congestion,event'));
      final data = jsonDecode(response.body);

      for (var res in data['incidents']) {
        _incidents.add(Incidents(
            fullDesc: res['fullDesc'],
            lng: res['lng'],
            severity: res['severity'],
            shortDesc: res['shortDesc'],
            type: res['type'],
            impacting: res['impacting'],
            eventCode: res['eventCode'],
            iconUrl: res['iconURL'],
            lat: res['lat']));
      }
    } on Exception {
      VxToast.show(context,
          msg: 'Area Is Too Large', position: VxToastPosition.top);
    }

    //* add to stream
    _events.setVariable = _incidents.length;
    _events.variableSink.add(_events.getVariable);

    //* add data to stream
    _incidentsStream.setVariable = _incidents;
    _incidentsStream.variableSink.add(_incidentsStream.getVariable);
  }

  //* getter for stream
  static Stream<List<Incidents>> get data => _incidentsStream.variableStream;
  static Stream<LatLng> get position => _position.variableStream;
  static Stream<int> get event => _events.variableStream;
  static List<Incidents> get incidents => _incidents;
}

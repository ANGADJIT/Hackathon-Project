import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:stream_variable/stream_variable.dart';
import 'package:traffic_congestion/utils/api_key.dart';

class _Incidents {
  final String fullDesc;
  final double lng;
  final int severity;
  final String shortDesc;
  final int type;
  final bool impacting;
  final int eventCode;
  final String iconUrl;
  final double lat;

  _Incidents({
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
  //* stream varaible type _Incidents
  static late StreamVariable<List<_Incidents>> _incidentsStream;

  //* making it singleton
  static final IncidentsApi _incidentsApi = IncidentsApi.init();
  IncidentsApi.init() {
    _incidentsStream = StreamVariable<List<_Incidents>>();
    _incidentsStream.setVariable = [];
    _incidentsStream.variableSink.add(_incidentsStream.getVariable);

    _position = StreamVariable<LatLng>();
    _position.setVariable = LatLng(.0, .0);
    _position.variableSink.add(_position.getVariable);
  }

  factory IncidentsApi() => _incidentsApi;

  static final List<_Incidents> _incidents = [];

  //* latitude and logitude varaible
  static late StreamVariable<LatLng> _position;

  //* method for getting data
  static changeData(
      {required double nELa,
      required double nELo,
      required double sELa,
      required double sELo,
      required double latitude,
      required double longitude}) async {
    _position.setVariable = LatLng(latitude, longitude);
    _position.variableSink.add(_position.getVariable);

    //* delete all from list
    _incidents.clear();

    // final respose = await http.get(Uri.parse(
    //     'http://www.mapquestapi.com/traffic/v2/incidents?key=$apiKey&boundingBox=$nELa,$nELo,$sELa,$sELo&filters=construction,incidents,congestion,event'));

    final response = await http.get(Uri.parse(
        'http://www.mapquestapi.com/traffic/v2/incidents?key=$apiKey&boundingBox=39.95,-105.25,39.52,-104.71&filters=construction,incidents'));

    final data = jsonDecode(response.body);

    for (var res in data['incidents']) {
      _incidents.add(_Incidents(
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

    //* add data to stream
    _incidentsStream.setVariable = _incidents;
    _incidentsStream.variableSink.add(_incidentsStream.getVariable);
  }

  //* getter for stream
  static Stream<List<_Incidents>> get data => _incidentsStream.variableStream;
  static Stream<LatLng> get position => _position.variableStream;
}

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traffic_congestion/utils/api_key.dart';
import 'package:velocity_x/velocity_x.dart';

//* Home page
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //* style json string
  late String _style;

  //* method to check wether is there connection or not
  void _checkConnectivity() async {
    final _result = await Connectivity().checkConnectivity();

    if (_result != ConnectivityResult.wifi &&
        _result != ConnectivityResult.mobile) {
      VxToast.show(context,
          msg: 'No Internet',
          position: VxToastPosition.bottom,
          bgColor: Vx.hexToColor('#204f5a'));
    }
  }

  //* method to get json file
  Future<String> _getCustomMapConfigFile() async {
    return await rootBundle.loadString('assets/config/map_mode.json');
  }

  //* initial position of map
  static final LatLng _initialPosition = LatLng(31.6340, 74.872261);

  //* Camera position
  final CameraPosition _cameraPosition =
      CameraPosition(target: _initialPosition, zoom: 14.0);

  //* Google map controller
  GoogleMapController? _googleMapController;

  @override
  void initState() {
    //* every 2 seconds we will check for connectivity
    Timer.periodic(5.seconds, (timer) => _checkConnectivity());
    //* init map style
    _getCustomMapConfigFile().then((value) => _style = value);

    super.initState();
  }

  @override
  void dispose() {
    _googleMapController!.dispose(); //* close map controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VxAppBar(
        elevation: 2.5,
        backgroundColor: Vx.hexToColor('#204f5a'),
        title: 'Traffic Congestion'
            .text
            .hexColor(Vx.whiteHex)
            .headline5(context)
            .make(),
      ),
      body: SafeArea(
        child: Stack(children: [
          GoogleMap(
              onCameraIdle: () async {
                final callback = context.showLoading(msg: '');

                final bounds = await _googleMapController!.getVisibleRegion();
                final result = await http.get(Uri.parse(
                    'http://www.mapquestapi.com/traffic/v2/incidents?key=$apiKey&boundingBox=${bounds.northeast.latitude},${bounds.northeast.longitude},${bounds.southwest.latitude},${bounds.southwest.longitude}&filters=construction,incidents,congestion,event'));
                
                print(jsonDecode(result.body));

                Future.delayed(1.milliseconds, callback.call());
              },
              trafficEnabled: true,
              mapType: MapType.normal,
              compassEnabled: true,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              initialCameraPosition: _cameraPosition,
              zoomGesturesEnabled: true,
              onMapCreated: (controller) => {
                    _googleMapController = controller,
                    _googleMapController!
                        .setMapStyle(_style), //* change map style
                  }),
        ]),
      ),
    );
  }
}

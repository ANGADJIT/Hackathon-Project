import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traffic_congestion/model/incidents_model.dart';
import 'package:traffic_congestion/screens/details.dart';
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

  double roundDouble(double value, int places) {
    double mod = pow(10.0, places).toDouble();
    return ((value * mod).round().toDouble() / mod);
  }

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
    //* initialize Api stream
    IncidentsApi.init();

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
                final callback = context.showLoading(
                    msg: '', bgColor: Vx.hexToColor('#204f5a'));

                final bounds = await _googleMapController!.getVisibleRegion();

                final positions = await _googleMapController!.getLatLng(
                    ScreenCoordinate(
                        x: (context.screenWidth ~/ 2),
                        y: (context.screenHeight ~/ 2)));

                Future.delayed(
                  2.seconds,
                );

                await IncidentsApi.changeData(
                    context: context,
                    longitude: positions.longitude,
                    latitude: positions.latitude,
                    nELa: bounds.northeast.latitude,
                    nELo: bounds.northeast.longitude,
                    sELa: bounds.southwest.latitude,
                    sELo: bounds.southwest.longitude);

                Future.delayed(1.microseconds, callback.call());
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

          Align(
            alignment: Alignment.topLeft,
            child: StreamBuilder<int>(
                initialData: 0,
                stream: IncidentsApi.event,
                builder: (context, snapshot) {
                  return VxBox(
                          child: 'Incidents ${snapshot.data!}'
                              .text
                              .italic
                              .light
                              .hexColor(Vx.whiteHex)
                              .size(context.screenWidth * .02)
                              .makeCentered())
                      .rounded
                      .hexColor('#204f5a')
                      .shadowMax
                      .border(color: Vx.hexToColor(Vx.grayHex300), width: .4)
                      .size(
                          context.screenWidth * .42, context.screenHeight * .09)
                      .make()
                      .pSymmetric(h: 20.0, v: 25.0)
                      .onTap(() {
                    if (snapshot.data! != 0) {
                      context
                          .nextPage(Details(details: IncidentsApi.incidents));
                    } else {
                      VxToast.show(context,
                          msg: 'No Incindents', bgColor: Vx.red300);
                    }
                  });
                }),
          ),

          //* data presenter widget
          Align(
            alignment: Alignment.bottomRight,
            child: VxBox(
                    child: StreamBuilder<List>(
                        initialData: const [],
                        stream: IncidentsApi.data,
                        builder: (context, AsyncSnapshot<List> snapshot) {
                          int length = snapshot.data!.length;
                          String congestion = '';
                          Color? color;

                          if (length <= 100) {
                            congestion = 'Low';
                            color = Vx.hexToColor('#1e8a30');
                          } else if (length > 101 && length <= 200) {
                            congestion = 'Medium';
                            color = Vx.hexToColor('#915f0d');
                          } else {
                            congestion = 'High';
                            color = Vx.hexToColor('#f01d60');
                          }

                          return VStack([
                            HStack([
                              'Congestion'
                                  .text
                                  .size(context.screenWidth * .043)
                                  .hexColor(Vx.whiteHex)
                                  .makeCentered()
                                  .pSymmetric(h: 15.0, v: 12.0),
                              const Spacer(),
                              congestion.text.italic
                              .overflow(TextOverflow.ellipsis)
                                  .size(context.screenWidth * .038)
                                  .color(color)
                                  .makeCentered()
                                  .pSymmetric(h: 15.0, v: 12.0),
                            ]).py(3.0),
                            StreamBuilder<LatLng>(
                                stream: IncidentsApi.position,
                                builder: (context, snapshot) {
                                  return VStack([
                                    HStack([
                                      'Latitude'
                                          .text
                                          .size(context.screenWidth * .02)
                                          .hexColor(Vx.whiteHex)
                                          .makeCentered()
                                          .pSymmetric(h: 15.0, v: 12.0),
                                      const Spacer(),
                                      roundDouble(snapshot.data!.longitude, 4)
                                          .text
                                          .light
                                          .italic
                                          .size(context.screenWidth * .02)
                                          .hexColor(Vx.whiteHex)
                                          .makeCentered()
                                          .pSymmetric(h: 15.0, v: 12.0),
                                    ]).py(2.0),
                                    HStack([
                                      'Longitude'
                                          .text
                                          .size(context.screenWidth * .02)
                                          .hexColor(Vx.whiteHex)
                                          .makeCentered()
                                          .pSymmetric(h: 15.0, v: 12.0),
                                      const Spacer(),
                                      roundDouble(snapshot.data!.latitude, 4)
                                          .text
                                          .light
                                          .italic
                                          .size(context.screenWidth * .02)
                                          .hexColor(Vx.whiteHex)
                                          .makeCentered()
                                          .pSymmetric(h: 15.0, v: 12.0),
                                    ]),
                                  ]);
                                }),
                          ]);
                        }))
                .rounded
                .hexColor('#204f5a')
                .shadowMax
                .border(color: Vx.hexToColor(Vx.grayHex300), width: .4)
                .size(context.screenWidth * .6, context.screenHeight * .18)
                .make()
                .pSymmetric(h: 20.0, v: 25.0),
          )
        ]),
      ),
    );
  }
}

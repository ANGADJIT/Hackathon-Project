import 'package:flutter/material.dart';
import 'package:traffic_congestion/model/incidents_model.dart';
import 'package:velocity_x/velocity_x.dart';

//* Details page
class Details extends StatefulWidget {
  const Details({Key? key, required this.details}) : super(key: key);

  final List<Incidents> details;

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Vx.hexToColor('#203153'),
        appBar: VxAppBar(
          backgroundColor: Vx.hexToColor('#204f5a'),
          title:
              'Incidents'.text.hexColor(Vx.whiteHex).headline5(context).make(),
        ),
        body: ListView.builder(
            itemCount: widget.details.length,
            itemBuilder: (context, index) {
              return ListTile(
                subtitle: 'LAT : ${widget.details[index].lat}     LNG : ${widget.details[index].lat}'.text
                    .hexColor(Vx.grayHex300)
                    .light.
                    italic
                    .size(context.screenWidth * .01)
                    .overflow(TextOverflow.ellipsis)
                    .make(),
                leading: Image.network(widget.details[index].iconUrl),
                title: widget.details[index].shortDesc.text
                    .hexColor(Vx.whiteHex)
                    .size(context.screenWidth * .02)
                    .overflow(TextOverflow.ellipsis)
                    .make(),
              );
            }),
      ),
    );
  }
}

import 'dart:async';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Geocsv',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<dynamic>> _master = [];
  List<List<dynamic>> _data = [];

  final List<LatLng> _points = <LatLng>[];

  final Set<Marker> _markers = {};

  final Completer<GoogleMapController> _controller = Completer();

  Future<List<List<dynamic>>> _loadCSV(String file) async {
    final _rawData = await rootBundle.loadString("assets/$file.csv");

    return const CsvToListConverter().convert(_rawData);
  }

  Future<void> _goToTheLake(double latitude, double longitude) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(latitude, longitude), zoom: 18),
    ));
  }

  Map<PolylineId, Polyline> polylines = <PolylineId, Polyline>{};
  int _polylineIdCounter = 0;

  void _add() {
    final String polylineIdVal = 'polyline_id_$_polylineIdCounter';
    _polylineIdCounter++;
    final PolylineId polylineId = PolylineId(polylineIdVal);

    final Polyline polyline = Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      color: Colors.orange,
      width: 5,
      points: _points,
    );

    setState(() {
      polylines[polylineId] = polyline;
    });
  }

  void _addPoints(double lat, double lng) {
    _points.add(LatLng(lat, lng));

    _markers.add(
      Marker(
        markerId: MarkerId('$lat$lng'),
        position: LatLng(lat, lng),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadMaster();
  }

  Future<void> _loadMaster() async => _master = await _loadCSV('master');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                const Card(
                  // margin: const EdgeInsets.all(3),
                  child: ListTile(
                    title: Text('CSV Name'),
                    trailing: Text('Duration'),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _master.length,
                    itemBuilder: (_, i) {
                      return Card(
                        child: ListTile(
                          onTap: () async {
                            _data = await _loadCSV(
                                _master[i][0].toString().padLeft(4, '0'));
                            _points.clear();
                            _markers.clear();
                            for (List<dynamic> e in _data) {
                              _addPoints(e[1], e[2]);
                            }
                            _add();
                            await _goToTheLake(_data[0][1], _data[0][2]);
                            setState(() {});
                          },
                          title: Text(_master[i][0].toString().padLeft(4, '0')),
                          trailing: Text(_master[i][1].toString()),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              SizedBox(
                width: (MediaQuery.of(context).size.width * 2) / 3,
                height: MediaQuery.of(context).size.height / 2,
                child: GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.5937, 78.9629),
                    zoom: 3,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  polylines: Set<Polyline>.of(polylines.values),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width * 2) / 3,
                height: MediaQuery.of(context).size.height / 2,
                child: Column(
                  children: <Widget>[
                    Card(
                      margin: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: Table(
                          children: const [
                            TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 15.0),
                                  child: Text('Timestamp'),
                                ),
                                Text('Latitude'),
                                Text('Longitude'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          controller: ScrollController(),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            return GestureDetector(
                              onTap: () async =>
                                  await _goToTheLake(_data[i][1], _data[i][2]),
                              child: Card(
                                margin: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15.0),
                                  child: Table(
                                    children: [
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 15.0),
                                            child: Text(_data[i][0].toString()),
                                          ),
                                          Text(_data[i][1].toString()),
                                          Text(_data[i][2].toString()),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

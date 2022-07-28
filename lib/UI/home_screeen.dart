import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline_new/google_map_polyline_new.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  late String searchText;
  bool mapToggle = false;
  var currentLocation;
  bool clientToggle = false;
  var clients = [];
//  List<Marker> _markers = [];
  final Set<Marker> _markers = <Marker>{};
  var currentBearing;
  var currentClient;
  var filterDist;
  //for ploylines
  // final Set<Polyline> _ploylines = <Polyline>{};
  GoogleMapPolyline googleMapPolyline =
      GoogleMapPolyline(apiKey: "AIzaSyDie1Px5fMyj4FVXRYcuT7OuTozX87CSL8");
  LatLng _mapInitLocation = LatLng(40.683337, -73.940432);

  final LatLng _originLocation = const LatLng(40.677939, -73.941755);
  final LatLng _destinationLocation = const LatLng(40.698432, -73.924038);
  int _polylineCount = 1;
  final Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  //Polyline patterns
  List<List<PatternItem>> patterns = <List<PatternItem>>[
    <PatternItem>[], //line
    <PatternItem>[PatternItem.dash(30.0), PatternItem.gap(20.0)], //dash
    <PatternItem>[PatternItem.dot, PatternItem.gap(10.0)], //dot
    <PatternItem>[
      //dash-dot
      PatternItem.dash(30.0),
      PatternItem.gap(20.0),
      PatternItem.dot,
      PatternItem.gap(20.0)
    ],
  ];

  @override
  void initState() {
    super.initState();
    determinePosition().then((value) {
      _getPolylinesWithLocation();
    });
  }

  addBearing() {
    mapController
        .animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: LatLng(currentClient['location'].latitude,
              currentClient['location'].longitude),
          bearing:
              currentBearing == 360.0 ? currentBearing + 90 : currentBearing,
          zoom: 14,
          tilt: 45),
    ))
        .then((value) {
      setState(() {
        if (currentBearing == 0.0) {
        } else {
          currentBearing = currentBearing + 90;
        }
      });
    });
  }

  removeBearing() {
    mapController
        .animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: LatLng(currentClient['location'].latitude,
              currentClient['location'].longitude),
          bearing: currentBearing == 0.0 ? currentBearing - 90 : currentBearing,
          zoom: 14,
          tilt: 45),
    ))
        .then((value) {
      setState(() {
        if (currentBearing == 360.0) {
        } else {
          currentBearing = currentBearing - 90;
        }
      });
    });
  }

  Future<Position?> determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location Not Available');
      }
    } else {
      return await Geolocator.getCurrentPosition().then((currentPosition) {
        setState(() {
          currentLocation = currentPosition;
          mapToggle = true;
          populateClients();
        });
      });
    }
  }

  populateClients() {
    clients = [];
    FirebaseFirestore.instance.collection('marker').get().then((docs) {
      if (docs.docs.isNotEmpty) {
        for (int i = 0; i < docs.docs.length; i++) {
          clients.add(docs.docs[i].data());
          initMarker(docs.docs[i].data());
        }
      }
    });
  }

  initMarker(client) {
    // print("called");
    // _markers.clear();
    _markers.add(Marker(
      visible: true,
      draggable: false,
      icon: BitmapDescriptor.defaultMarker,
      markerId: MarkerId(client['id']),
      infoWindow:
          InfoWindow(title: "Client Name", snippet: "${client['client_name']}"),
      position:
          LatLng(client['location'].latitude, client['location'].longitude),
    ));
    debugPrint("$_markers");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          mapToggle
              ? GoogleMap(
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                  markers: _markers,
                  onMapCreated: onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _mapInitLocation,
                    // LatLng(
                    //     currentLocation.latitude, currentLocation.longitude),
                    zoom: 14.4746,
                  ),
                )
              : const Center(
                  child: Text("Please wait... Loading..."),
                ),
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 10, top: 15),
                    hintText: "Search Address",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                        onPressed: searchAndNavigate,
                        icon: const Icon(CupertinoIcons.search))),
                onChanged: (val) {
                  setState(() {
                    searchText = val;
                  });
                },
              ),
            ),
          ),
          Positioned(
              top: 100,
              left: 20,
              child: CircleAvatar(
                child: IconButton(
                    onPressed: () async {
                      //   print("then");
                      getFilter();
                    },
                    icon: const Icon(Icons.filter_list_outlined)),
              )),
          clientToggle
              ? Positioned(
                  top: 100,
                  right: 20,
                  child: CircleAvatar(
                    child: IconButton(
                        onPressed: () async {
                          //   print("then");
                          mapController
                              .animateCamera(
                                  CameraUpdate.newCameraPosition(CameraPosition(
                            target: _mapInitLocation,
                            // LatLng(currentLocation.latitude,
                            //     currentLocation.longitude),
                            zoom: 14.4746,
                          )))
                              .then((value) {
                            setState(() {
                              clientToggle = false;
                            });
                          });
                        },
                        icon: const Icon(CupertinoIcons.location)),
                  ))
              : SizedBox(),
          clientToggle
              ? Positioned(
                  top: 100,
                  right: 70,
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                        onPressed: () async {
                          //   print("then");
                          await addBearing();
                        },
                        icon: const Icon(Icons.rotate_right)),
                  ))
              : SizedBox(),
          clientToggle
              ? Positioned(
                  top: 100,
                  right: 120,
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: IconButton(
                        onPressed: () async {
                          //   print("then");
                          await removeBearing();
                        },
                        icon: const Icon(Icons.rotate_left)),
                  ))
              : SizedBox(),
          Positioned(
              bottom: 50,
              left: 20,
              right: 60,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: clients.map((elements) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            currentClient = elements;
                            currentBearing = 90.0;
                            clientToggle = true;
                          });
                          mapController.animateCamera(
                              CameraUpdate.newCameraPosition(CameraPosition(
                                  bearing: 45.0,
                                  tilt: 20,
                                  zoom: 20,
                                  target: LatLng(elements['location'].latitude,
                                      elements['location'].longitude))));
                        },
                        child: Container(
                            // height: 50,
                            width: 130,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white),
                            child:
                                Center(child: Text(elements['client_name']))),
                      ),
                    );
                  }).toList(),
                ),
              ))
        ],
      ),
    );
  }

  //seasrch nearest clients
  getFilter() {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Enter the distance to the nearest"),
            contentPadding: const EdgeInsets.all(10),
            content: TextField(
              onChanged: (val) {
                setState(() {
                  filterDist = val;
                });
              },
            ),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    filterMarker(filterDist);
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"))
            ],
          );
        });
  }

  searchAndNavigate() {
    locationFromAddress(searchText).then((result) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(result[0].latitude, result[0].longitude),
          zoom: 10.0)));
    });
  }

  void onMapCreated(controller) {
    setState(() {
      mapController = controller;
    });
  }

  filterMarker(filter) {
    for (int i = 0; i < clients.length; ++i) {
      var calDis = Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.latitude,
          clients[i]['location'].latitude,
          clients[i]['location'].longitude);
      print("Distancee=======> ${calDis / 1000}");
      if (calDis / 1000 > double.parse(filter)) {
        placeFilterMarker(clients[i], calDis / 1000);
      } else {
        print("Conditon false");
      }
    }
  }

  placeFilterMarker(cli, dis) {
    _markers.clear();
    _markers.add(Marker(
      visible: true,
      draggable: false,
      icon: BitmapDescriptor.defaultMarker,
      markerId: MarkerId(cli['id']),
      infoWindow:
          InfoWindow(title: "Client Name", snippet: "${cli['client_name']}"),
      position: LatLng(cli['location'].latitude, cli['location'].longitude),
    ));
  }

  _getPolylinesWithLocation() async {
    // print("curentLocation : ${currentLocation.latitude}");
    // _setLoadingMenu(true);
    List<LatLng>? coordinates =
        await googleMapPolyline.getCoordinatesWithLocation(
            origin: _originLocation,
            destination: _destinationLocation,
            mode: RouteMode.driving);

    // setState(() {
    //   _polylines.clear();
    // });
    debugPrint("coordinates: $coordinates");
    _addPolyline(coordinates);
    //  _setLoadingMenu(false);
  }

  _addPolyline(List<LatLng>? coordinates) {
    PolylineId id = PolylineId("poly$_polylineCount");
    Polyline polyline = Polyline(
        polylineId: id,
        patterns: patterns[0],
        color: Colors.red,
        points: coordinates!,
        width: 10,
        onTap: () {});

    setState(() {
      _polylines[id] = polyline;
      _polylineCount++;
    });
    print("Polyline: ${polyline.toJson()}");
  }

  // _setLoadingMenu(bool _status) {
  //   setState(() {
  //     _loading = _status;
  //   });
  // }
}

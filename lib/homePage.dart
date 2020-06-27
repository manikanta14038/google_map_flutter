import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static LatLng _center;
  MapType _currentMapType = MapType.normal;
  final Set<Marker> _markers = {};
  LatLng _lastMapPosition = _center;
  double _zoom = 14.0;
  CameraPosition _cameraPosition = CameraPosition(target: LatLng(0.0, 0.0));
  GoogleMapController mapController;
  TextEditingController _start = TextEditingController();
  TextEditingController _destination = TextEditingController();
  String _currentAddress, _startAddress, _destinationAddress;
  Position _currentPosition;

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    _currentPosition = position;
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      _cameraPosition = CameraPosition(zoom: _zoom, target: _center);
    });
    await _getAddress();
  }

  void _onAddMarkerButtonPressed() {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(_lastMapPosition.toString()),
          position: _lastMapPosition,
          infoWindow: InfoWindow(
            title: 'Really cool place',
            snippet: '5 Star Rating',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  void _changeMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void addMarker(LatLng val) async {
    List<Placemark> p = await Geolocator()
        .placemarkFromCoordinates(val.latitude, val.longitude);
    Placemark place = p[0];
    setState(() {
      _destinationAddress =
          "${place.name},${place.subLocality},${place.locality},${place.administrativeArea},${place.postalCode},${place.country}";
      _destination.text = _destinationAddress;
      _markers.add(
        Marker(
          markerId: MarkerId(_lastMapPosition.toString()),
          position: val,
          icon: BitmapDescriptor.defaultMarker,
          // infoWindow:
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  _getAddress() async {
    try {
      List<Placemark> p = await Geolocator()
          .placemarkFromCoordinates(_center.latitude, _center.longitude);
      Placemark place = p[0];
      setState(() {
        _currentAddress =
            "${place.name},${place.subLocality},${place.locality},${place.administrativeArea},${place.postalCode},${place.country}";
        _start.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  _calculateRoute() async {
    List<Placemark> startPlacement =
        await Geolocator().placemarkFromAddress(_startAddress);
    List<Placemark> destinationPlacement =
        await Geolocator().placemarkFromAddress(_destinationAddress);
    Position startCoordinates = _startAddress == _currentAddress
        ? Position(
            latitude: _currentPosition.latitude,
            longitude: _currentPosition.longitude)
        : startPlacement[0].position;

    Position destinationCoordinates = destinationPlacement[0].position;
    Marker startMarker = Marker(
      markerId: MarkerId('$startCoordinates'),
      position: LatLng(
        startCoordinates.latitude,
        startCoordinates.longitude,
      ),
      infoWindow: InfoWindow(
        title: 'Start',
        snippet: _startAddress,
      ),
      icon: BitmapDescriptor.defaultMarker,
    );
    Marker destinationMarker = Marker(
      markerId: MarkerId('$destinationCoordinates'),
      position: LatLng(
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      ),
      infoWindow: InfoWindow(
        title: 'Destination',
        snippet: _destinationAddress,
      ),
      icon: BitmapDescriptor.defaultMarker,
    );
    setState(() {
      _markers.add(startMarker);
      _markers.add(destinationMarker);
    });

    print('START COORDINATES: $startCoordinates');
    print('DESTINATION COORDINATES: $destinationCoordinates');
  }

  @override
  void initState() {
    _getCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Around Me'),
      ),
      body: _center != null
          ? Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _cameraPosition,
                  mapType: _currentMapType,
                  markers: _markers,
                  onCameraMove: _onCameraMove,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  zoomControlsEnabled: false,
                  onTap: (LatLng val) => addMarker(val),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ClipOval(
                        child: Material(
                          color: Colors.blue[100],
                          child: InkWell(
                            splashColor: Colors.blue,
                            child: SizedBox(
                              height: 50.0,
                              width: 50.0,
                              child: Icon(Icons.add),
                            ),
                            onTap: () async {
                              mapController
                                  .animateCamera(CameraUpdate.zoomIn());
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 5.0),
                      ClipOval(
                        child: Material(
                          color: Colors.blue[100],
                          child: InkWell(
                            splashColor: Colors.blue,
                            child: SizedBox(
                              height: 50.0,
                              width: 50.0,
                              child: Icon(Icons.remove),
                            ),
                            onTap: () async {
                              mapController
                                  .animateCamera(CameraUpdate.zoomOut());
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(8.0),
                      width: width * 0.8,
                      child: TextField(
                        autofocus: false,
                        controller: _start,
                        onChanged: (val) {},
                        decoration: InputDecoration(
                          hintText: 'Start',
                          prefixIcon: Icon(
                            Icons.looks_one,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.my_location),
                            onPressed: () {
                              _start.text = _currentAddress;
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Colors.grey[400],
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                            borderSide: BorderSide(
                              color: Colors.blue[300],
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      width: width * 0.8,
                      child: TextField(
                        autofocus: false,
                        controller: _destination,
                        decoration: InputDecoration(
                          hintText: 'Destination',
                          prefixIcon: Icon(
                            Icons.looks_two,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Colors.grey[400],
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                            borderSide: BorderSide(
                              color: Colors.blue[300],
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    SizedBox(height: 5.0),
                    _destinationAddress != null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RaisedButton(
                              color: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0)),
                              child: Text('Show Route'),
                              onPressed: () {
                                _calculateRoute();
                              },
                            ),
                          )
                        : Container(),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        FloatingActionButton(
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          backgroundColor: Colors.white,
                          child:
                              Icon(Icons.map, size: 30.0, color: Colors.black),
                          onPressed: _changeMapType,
                        ),
                        SizedBox(height: 10.0),
                        FloatingActionButton(
                          child: Icon(
                            Icons.add_location,
                            size: 30.0,
                            color: Colors.black,
                          ),
                          backgroundColor: Colors.white,
                          onPressed: _onAddMarkerButtonPressed,
                        ),
                        SizedBox(height: 10.0),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                      child: ClipOval(
                        child: Material(
                          color: Colors.orange[100], // button color
                          child: InkWell(
                            splashColor: Colors.orange, // inkwell color
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(Icons.my_location),
                            ),
                            onTap: () async {
                              mapController.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      _center.latitude,
                                      _center.longitude,
                                    ),
                                    zoom: 16.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(),
    );
  }
}

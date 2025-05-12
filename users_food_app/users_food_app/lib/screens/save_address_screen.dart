// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:users_food_app/global/global.dart';
import 'package:users_food_app/maps/maps.dart';
import 'package:users_food_app/models/address.dart';
import 'package:users_food_app/widgets/simple_app_bar.dart';
import 'package:users_food_app/widgets/text_field.dart';

class SaveAddressScreen extends StatelessWidget {
  final _name = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _flatNumber = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _completeAddress = TextEditingController();
  final _locationController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<Placemark>? placemarks;
  Position? position;

  SaveAddressScreen({Key? key}) : super(key: key);

  getUserLocationAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: "Location permissions are permanently denied.",
      );
      return;
    }

    // Permissions granted, proceed to get position
    Position newPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    position = newPosition;

    placemarks = await placemarkFromCoordinates(
      position!.latitude,
      position!.longitude,
    );

    Placemark pMark = placemarks![0];

    String fullAddress =
        '${pMark.subThoroughfare} ${pMark.thoroughfare}, ${pMark.subLocality} ${pMark.locality}, ${pMark.subAdministrativeArea}, ${pMark.administrativeArea} ${pMark.postalCode}, ${pMark.country}';

    _locationController.text = fullAddress;
    _flatNumber.text =
        '${pMark.subThoroughfare} ${pMark.thoroughfare}, ${pMark.subLocality} ${pMark.locality}';
    _city.text =
        '${pMark.subAdministrativeArea}, ${pMark.administrativeArea} ${pMark.postalCode}';
    _state.text = '${pMark.country}';
    _completeAddress.text = fullAddress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SimpleAppBar(title: "iFood"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            if (formKey.currentState!.validate()) {
              // Check if user is logged in
              if (sharedPreferences == null || sharedPreferences!.getString("uid") == null) {
                Fluttertoast.showToast(msg: "Please login to save address");
                return;
              }

              // Check if location is available
              if (position == null) {
                Fluttertoast.showToast(msg: "Please get your location first");
                return;
              }

              // Create address model
              final model = Address(
                name: _name.text.trim(),
                state: _state.text.trim(),
                fullAddress: _completeAddress.text.trim(),
                phoneNumber: _phoneNumber.text.trim(),
                flatNumber: _flatNumber.text.trim(),
                city: _city.text.trim(),
                lat: position!.latitude,
                lng: position!.longitude,
              ).toJson();

              // Save to Firestore
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(sharedPreferences!.getString("uid"))
                  .collection("userAddress")
                  .doc(DateTime.now().millisecondsSinceEpoch.toString())
                  .set(model);

              Fluttertoast.showToast(msg: "New Address has been saved.");
              
              // Reset form
              formKey.currentState!.reset();
              
              // Navigate back
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          } catch (e) {
            print("Error saving address: $e");
            Fluttertoast.showToast(
              msg: "Error saving address. Please try again.",
              backgroundColor: Colors.red,
            );
          }
        },
        label: const Text("Save"),
        icon: const Icon(Icons.check),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 6),
            const Align(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "Save New Address: ",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_pin_circle,
                color: Colors.red,
                size: 35,
              ),
              title: SizedBox(
                width: 250,
                child: TextField(
                  style: const TextStyle(color: Colors.black),
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: "What's your Address?",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              label: const Text(
                "Get my Address",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.location_on, color: Colors.red),
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.orangeAccent),
                  ),
                ),
              ),
              onPressed: () async {
                await getUserLocationAddress();
                if (position != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Location obtained successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            if (position != null) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1F5FE), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Location Preview",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF57C00),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Latitude: ${position!.latitude.toStringAsFixed(6)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      "Longitude: ${position!.longitude.toStringAsFixed(6)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await MapsUtils.openMapWithPosition(
                              position!.latitude,
                              position!.longitude,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error opening map: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: Text(
                          "Open in Google Maps",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: Column(
                children: [
                  MyTextField(hint: "Name", controller: _name),
                  MyTextField(hint: "Phone Number", controller: _phoneNumber),
                  MyTextField(hint: "City", controller: _city),
                  MyTextField(hint: "State / Country", controller: _state),
                  MyTextField(hint: "Address Line", controller: _flatNumber),
                  MyTextField(
                    hint: "Complete Address",
                    controller: _completeAddress,
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

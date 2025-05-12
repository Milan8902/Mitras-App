import 'package:cloud_firestore/cloud_firestore.dart';

class Menus {
  String? menuID;
  String? sellerUID;
  String? menuTitle;
  String? menuInfo;
  Timestamp? publishDate;
  String? thumbnailUrl;
  String? status;
  String? imageUrl; // Add base64Image field

  Menus({
    this.menuID,
    this.menuInfo,
    this.menuTitle,
    this.publishDate,
    this.sellerUID,
    this.status,
    this.thumbnailUrl,
    this.imageUrl, // Include base64Image in the constructor
  });

  // Create Menus object from Firestore document
  Menus.fromJson(Map<String, dynamic> json) {
    menuID = json["menuID"];
    menuInfo = json["menuInfo"];
    menuTitle = json["menuTitle"];
    publishDate = json["publishDate"];
    sellerUID = json["sellerUID"];
    status = json["status"];
    thumbnailUrl = json["thumbnailUrl"];
    imageUrl = json["imageUrl"]; // Add base64Image to be parsed from Firestore
  }

  // Convert Menus object to a Firestore document
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["menuID"] = menuID;
    data["menuInfo"] = menuInfo;
    data["menuTitle"] = menuTitle;
    data["publishDate"] = publishDate;
    data["sellerUID"] = sellerUID;
    data["status"] = status;
    data["thumbnailUrl"] = thumbnailUrl;
    data["imageUrl"] = imageUrl; // Include base64Image when saving to Firestore
    return data;
  }
}

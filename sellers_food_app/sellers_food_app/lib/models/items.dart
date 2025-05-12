import 'package:cloud_firestore/cloud_firestore.dart';

class Items {
  String? menuID;
  String? sellerUID;
  String? itemID;
  String? title;
  String? shortInfo;
  Timestamp? publishedDate;
  String? imageUrl;
  String? longDescription;
  String? status;
  int? price;

  Items({
    this.itemID,
    this.longDescription,
    this.menuID,
    this.price,
    this.publishedDate,
    this.sellerUID,
    this.shortInfo,
    this.status,
    this.imageUrl,
    this.title,
  });

  Items.fromJson(Map<String, dynamic> json) {
    menuID = json["menuID"];
    sellerUID = json["sellerUID"];
    itemID = json["itemID"];
    title = json["title"];
    shortInfo = json["shortInfo"];
    publishedDate = json["publishedDate"];
    imageUrl = json["imageUrl"];
    longDescription = json["longDescription"];
    status = json["status"];
    price = json["price"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["menuID"] = menuID;
    data["sellerUID"] = sellerUID;
    data["itemID"] = itemID;
    data["title"] = title;
    data["shortInfo"] = shortInfo;
    data["publishedDate"] = publishedDate;
    data["imageUrl"] = imageUrl;
    data["longDescription"] = longDescription;
    data["status"] = status;
    data["price"] = price;

    return data;
  }
}

class Sellers {
  String? sellerUID;
  String? sellerName;
  String? sellerAvatarBase64;
  String? sellerEmail;
  String? sellerAddress;
  String? sellerPhone;
  String? sellerOperatingHours;
  String? sellerId;

  Sellers({
    this.sellerUID,
    this.sellerName,
    this.sellerAvatarBase64,
    this.sellerEmail,
    this.sellerAddress,
    this.sellerPhone,
    this.sellerOperatingHours,
  });

  Sellers.fromJson(Map<String, dynamic> json) {
    sellerUID = json["sellerUID"] ?? json["uid"];
    sellerName = json["sellerName"] ?? json["name"];
    sellerEmail = json["sellerEmail"] ?? json["email"];
    sellerId = json["sellerId"] ?? json["uid"];

    // Updated to match your actual Firestore fields
    sellerAvatarBase64 =
        json["sellerAvatarBase64"] ?? json["photoUrl"] ?? json["photolr1"];
    sellerAddress = json["sellerAddress"] ?? json["address"];
    sellerPhone = json["sellerPhone"] ?? json["phone"];
    sellerOperatingHours = json["sellerOperatingHours"] ?? json["operatingHours"];
    // Removed sellerAvatarUrl since it doesn't exist in your data
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["sellerUID"] = sellerUID;
    data["sellerName"] = sellerName;
    data["sellerAvatarBase64"] = sellerAvatarBase64;
    data["sellerEmail"] = sellerEmail;
    data["sellerAddress"] = sellerAddress;
    data["sellerPhone"] = sellerPhone;
    data["sellerOperatingHours"] = sellerOperatingHours;
    data["sellerId"] = sellerId;
    return data;
  }
}

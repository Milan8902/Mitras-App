import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../assistantMethods/assistant_methods.dart';
import '../global/global.dart';
import '../widgets/order_card_design.dart';
import '../widgets/progress_bar.dart';
import '../widgets/simple_app_bar.dart';

class NewOrdersScreen extends StatefulWidget {
  const NewOrdersScreen({Key? key}) : super(key: key);

  @override
  _NewOrdersScreenState createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    String? sellerUID = sharedPreferences!.getString("uid");
    print("📦 Seller UID for New Orders: $sellerUID");

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SimpleAppBar(title: "New Orders"),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [Color(0xFFFFFFFF), Color(0xFFFAC898)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection("orders")
                  .where("status", isEqualTo: "normal")
                  .where("sellerUID", isEqualTo: sellerUID)
                  .orderBy("orderTime", descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              print("📡 Waiting for new orders...");
              return Center(child: circularProgress());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No new orders."));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> orderData =
                    snapshot.data!.docs[index].data()! as Map<String, dynamic>;

                List<String> productIDs = separateOrderItemIDs(
                  orderData["productIDs"],
                );
                List<String> quantities = separateOrderItemQuantities(
                  orderData["productIDs"],
                );

                print("🛒 Order ${index + 1} productIDs: $productIDs");

                return FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection("items")
                          .where("itemID", whereIn: productIDs)
                          .where("sellerUID", isEqualTo: sellerUID)
                          .orderBy("publishedDate", descending: true)
                          .get(),
                  builder: (context, itemSnapshot) {
                    if (!itemSnapshot.hasData) {
                      return Center(child: circularProgress());
                    }

                    return OrderCardDesign(
                      itemCount: itemSnapshot.data!.docs.length,    
                      data: itemSnapshot.data!.docs,
                      orderID: snapshot.data!.docs[index].id,
                      seperateQuantitiesList: quantities,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<String> separateOrderItemIDs(dynamic productIDs) {
    if (productIDs is List) {
      return productIDs.map((e) {
        if (e is String && e.contains(":")) {
          return e.split(":")[0]; // itemID
        }
        return e.toString();
      }).toList();
    }
    return [];
  }

  List<String> separateOrderItemQuantities(dynamic productIDs) {
    if (productIDs is List) {
      return productIDs.map((e) {
        if (e is String && e.contains(":")) {
          return e.split(":")[1]; // quantity
        }
        return "1"; // default quantity
      }).toList();
    }
    return [];
  }
}

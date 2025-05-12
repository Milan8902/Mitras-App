import 'package:bringapp_admin_web_portal/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../widgets/simple_app_bar.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    Widget displayPaymentsDesign() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("payment").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No payments found!",
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              var payment = snapshot.data!.docs[i];
              String userName = payment.get("userName") ?? "Unknown User";
              String productName = payment.get("productName") ?? "Unknown Product";
              double productPrice = (payment.get("productPrice") ?? 0.0).toDouble();
              String sellerUID = payment.get("sellerUID") ?? "Unknown Seller";
              String orderId = payment.get("orderId") ?? "Unknown Order";
              Timestamp? timestamp = payment.get("timestamp");
              String formattedDate = timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                  : "Unknown Date";

              return Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Header
                      ListTile(
                        leading: const Icon(
                          Icons.payment,
                          color: Colors.amber,
                          size: 40,
                        ),
                        title: Text(
                          "Payment #$orderId",
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        subtitle: Text(
                          formattedDate,
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.black26),
                      // Payment Details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              icon: Icons.person,
                              label: "User",
                              value: userName,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.fastfood,
                              label: "Product",
                              value: productName,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.attach_money,
                              label: "Price",
                              value: "Rs ${productPrice.toStringAsFixed(2)}",
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.store,
                              label: "Seller",
                              value: sellerUID,
                            ),
                          ],
                        ),
                      ),
                      // Action Button (Optional)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            foregroundColor: Colors.white,
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.all(Colors.transparent),
                            overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                          ),
                          onPressed: () {
                            SnackBar snackBar = SnackBar(
                              content: Text(
                                "Payment Details: $productName - Rs ${productPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              backgroundColor: Colors.amber,
                              duration: const Duration(seconds: 2),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          },
                          icon: const Icon(Icons.info),
                          label: Text(
                            "View Details".toUpperCase(),
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff1b232A),
      appBar: SimpleAppBar(
        title: "All Payments",
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: displayPaymentsDesign(),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(width: 10),
        Text(
          "$label: ",
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
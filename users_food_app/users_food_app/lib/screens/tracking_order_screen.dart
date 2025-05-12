import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:users_food_app/global/global.dart';
import 'package:users_food_app/widgets/progress_bar.dart';

class TrackingOrderScreen extends StatefulWidget {
  final String? orderID;
  final String? sellerUID;
  final String? riderUID;

  const TrackingOrderScreen({
    Key? key,
    this.orderID,
    this.sellerUID,
    this.riderUID,
  }) : super(key: key);

  @override
  _TrackingOrderScreenState createState() => _TrackingOrderScreenState();
}

class _TrackingOrderScreenState extends State<TrackingOrderScreen> {
  String orderStatus = "";
  String riderName = "";
  String sellerName = "";
  String estimatedTime = "";

  @override
  void initState() {
    super.initState();
    getOrderDetails();
  }

  getOrderDetails() async {
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderID)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          orderStatus = snapshot.data()!["status"].toString();
        });
      }
    });

    if (widget.riderUID != null && widget.riderUID!.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("riders")
          .doc(widget.riderUID)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          setState(() {
            riderName = snapshot.data()!["riderName"].toString();
          });
        }
      });
    }

    if (widget.sellerUID != null && widget.sellerUID!.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(widget.sellerUID)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          setState(() {
            sellerName = snapshot.data()!["sellerName"].toString();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Track Order",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFAC898),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Status",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTrackingSteps(),
                      const SizedBox(height: 20),
                      if (orderStatus == "delivering")
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delivery_dining,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Your order is on the way!",
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Order Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Details",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow("Order ID", widget.orderID ?? "N/A"),
                      const Divider(),
                      _buildDetailRow("Restaurant", sellerName),
                      const Divider(),
                      if (riderName.isNotEmpty) ...[
                        _buildDetailRow("Rider", riderName),
                        const Divider(),
                      ],
                      _buildDetailRow(
                        "Status",
                        _getStatusText(orderStatus),
                        isStatus: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingSteps() {
    return Column(
      children: [
        _buildStep(
          "Order Placed",
          true,
          Icons.shopping_cart,
          "Your order has been placed",
        ),
        _buildStep(
          "Order Packed",
          orderStatus != "normal",
          Icons.inventory_2,
          "Restaurant is preparing your order",
        ),
        _buildStep(
          "Rider Picked",
          orderStatus == "picking" || orderStatus == "delivering" || orderStatus == "ended",
          Icons.delivery_dining,
          "Rider is on the way to pick up your order",
        ),
        _buildStep(
          "Delivered",
          orderStatus == "ended",
          Icons.check_circle,
          "Order has been delivered",
        ),
      ],
    );
  }

  Widget _buildStep(String title, bool isCompleted, IconData icon, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isStatus ? _getStatusColor(orderStatus) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case "normal":
        return "Order Placed";
      case "picking":
        return "Rider Picked";
      case "delivering":
        return "On the Way";
      case "ended":
        return "Delivered";
      default:
        return "Unknown";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "normal":
        return Colors.blue;
      case "picking":
        return Colors.orange;
      case "delivering":
        return Colors.green;
      case "ended":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 
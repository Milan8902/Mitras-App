import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../assistantMethods/order_status_helper.dart';
import '../../models/items.dart';

class OrderCard extends StatefulWidget {
  final int? itemCount;
  final List<dynamic>? data;
  final List<String>? seperateQuantitiesList;
  final String? orderID;
  final String? orderStatus;
  final String? sellerUID;

  const OrderCard({
    Key? key,
    this.itemCount,
    this.data,
    this.seperateQuantitiesList,
    this.orderID,
    this.orderStatus,
    this.sellerUID,
  }) : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _markOrderAsReceived() async {
    if (widget.orderID == null || widget.orderID!.isEmpty) {
      if (_isMounted) {
        Fluttertoast.showToast(
          msg: "Error: Invalid order ID",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
      return;
    }

    try {
      await OrderStatusHelper.updateOrderStatus(
        orderId: widget.orderID!,
        status: 'received',
      );
      
      if (_isMounted) {
        setState(() {}); // Refresh the UI
        Fluttertoast.showToast(
          msg: "Order marked as received!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (_isMounted) {
        Fluttertoast.showToast(
          msg: "Error: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == null || widget.data == null || widget.seperateQuantitiesList == null) {
      return const SizedBox.shrink();
    }

    final status = (widget.orderStatus ?? 'normal').toLowerCase();
    final displayStatus = OrderStatusHelper.getStatusDisplayText(status);
    
    Widget _buildDeliveredStatus() {
      return Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          Text(
            status == 'received' ? 'Order Received' : 'Order Delivered',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(OrderStatusHelper.getStatusColor(widget.orderStatus ?? 'normal')).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(OrderStatusHelper.getStatusColor(widget.orderStatus ?? 'normal')).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  size: 20,
                  color: Color(OrderStatusHelper.getStatusColor(widget.orderStatus ?? 'normal')),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: $displayStatus',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(OrderStatusHelper.getStatusColor(widget.orderStatus ?? 'normal')),
                  ),
                ),
                const Spacer(),
                Text(
                  'Order #${widget.orderID?.substring(widget.orderID!.length - 6) ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Restaurant Name
          if (widget.sellerUID != null && widget.sellerUID!.isNotEmpty)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("sellers")
                  .doc(widget.sellerUID)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                  final sellerData = snapshot.data!.data() as Map<String, dynamic>?;
                  if (sellerData == null) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF57C00).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF57C00).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          color: Color(0xFFF57C00),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sellerData["sellerName"] ?? "Unknown Restaurant",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF57C00),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          const SizedBox(height: 12),
          // Items List
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                ...List.generate(widget.itemCount!, (index) {
                  if (index >= widget.data!.length || index >= widget.seperateQuantitiesList!.length) {
                    return const SizedBox.shrink();
                  }
                  
                  Items model = Items.fromJson(
                    widget.data![index].data()! as Map<String, dynamic>,
                  );
                  
                  // Add divider between items except for the last one
                  return Column(
                    children: [
                      placedOrderDesignWidget(
                        model,
                        context,
                        widget.seperateQuantitiesList![index],
                      ),
                      if (index < widget.itemCount! - 1)
                        Divider(height: 1, color: Colors.grey[200]),
                    ],
                  );
                }),
                if (status == 'delivered' || status == 'received')
                  _buildDeliveredStatus(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Order Actions
          if (status == "ended")
            Column(
              children: [
                const Divider(thickness: 1, height: 1, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "Has your order been delivered?",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _markOrderAsReceived,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF57C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Confirm Order Received",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else if (status == "received")
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[800], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Order completed successfully!",
                    style: GoogleFonts.poppins(
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget placedOrderDesignWidget(
  Items model,
  BuildContext context,
  String seperateQuantitiesList,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Image
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              model.imageUrl!,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFFF57C00),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Item Details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title ?? 'Unnamed Item',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Rs ${model.price?.toStringAsFixed(2) ?? '0.00'}",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF57C00),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        "Qty: $seperateQuantitiesList",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

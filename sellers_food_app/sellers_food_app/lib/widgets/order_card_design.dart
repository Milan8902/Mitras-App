import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/items.dart';
import '../screens/order_details_screen.dart';

class OrderCardDesign extends StatelessWidget {
  final int? itemCount;
  final List<DocumentSnapshot>? data;
  final String? orderID;
  final List<String>? seperateQuantitiesList;
  final String? userId;

  const OrderCardDesign({
    Key? key,
    this.itemCount,
    this.data,
    this.orderID,
    this.seperateQuantitiesList,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: userId != null && userId!.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(userId).get()
          : null,
      builder: (context, userSnapshot) {
        String userName = 'Unknown User';
        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData['name'] != null && userData['name'].toString().isNotEmpty) {
            userName = userData['name'];
          }
        }
        if (userName == 'Unknown User') {
          return const SizedBox.shrink();
        }
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(orderID: orderID),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                ...List.generate(itemCount!, (index) {
                  Items model = Items.fromJson(
                    data![index].data()! as Map<String, dynamic>,
                  );
                  return placedOrderDesignWidgetWithUser(
                    model,
                    context,
                    seperateQuantitiesList![index],
                    userName,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget placedOrderDesignWidgetWithUser(
  Items model,
  BuildContext context,
  String quantity,
  String userName,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: model.imageUrl != null && model.imageUrl!.isNotEmpty
              ? Image.network(
                  model.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                model.title ?? 'Unnamed Item',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "\$${model.price?.toString() ?? '0.00'}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFA726),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "Quantity: ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    quantity,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Arrow Icon
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      ],
    ),
  );
}

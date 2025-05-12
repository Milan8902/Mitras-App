import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sellers_food_app/global/global.dart';
import 'dart:convert';

class SellerInfo extends StatefulWidget {
  const SellerInfo({Key? key}) : super(key: key);

  @override
  State<SellerInfo> createState() => _SellerInfoState();
}

class _SellerInfoState extends State<SellerInfo>
    with SingleTickerProviderStateMixin {
  double sellerTotalEarnings = 0;
  String? imageUrl;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  retrieveSellerEarnings() async {
    final uid = sharedPreferences!.getString("uid");
    if (uid != null) {
      final snap =
          await FirebaseFirestore.instance.collection("sellers").doc(uid).get();
      setState(() {
        sellerTotalEarnings = double.parse(
          snap.data()?["earnings"].toString() ?? "0",
        );
        imageUrl = snap.data()?["sellerAvatarBase64"];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    retrieveSellerEarnings();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius =
        screenWidth < 400 ? 27.0 : 27.0; // Smaller avatar on narrow screens

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(
            screenWidth < 400 ? 16 : 20,
          ), // Adaptive padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Restaurant Info',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEC7D10),
                    ),
                  ),
                  const Icon(
                    Icons.storefront,
                    color: Color(0xFFEC407A),
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant Name
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5FE).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.restaurant_menu,
                                color: Color(0xFFF57C00),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  sharedPreferences!.getString("name") ??
                                      "Unknown",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Email
                        Text(
                          sharedPreferences!.getString("email") ?? "No email",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 12),

                        // Earnings
                        Row(
                          children: [
                            Text(
                              'Earnings: ',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '₹${sellerTotalEarnings.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4CAF50),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Profile Avatar
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(avatarRadius),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF4081),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                              ? (imageUrl!.startsWith('http')
                                  ? NetworkImage(imageUrl!)
                                  : MemoryImage(base64Decode(imageUrl!)))
                              : const AssetImage('images/seller.png') as ImageProvider,
                          onBackgroundImageError: (exception, stackTrace) {
                            print('Error loading profile image: $exception');
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Divider
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 12),

              // Menus Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: Color(0xFFF57C00),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Menus',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

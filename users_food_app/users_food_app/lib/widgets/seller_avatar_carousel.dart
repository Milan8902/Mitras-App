import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:users_food_app/widgets/progress_bar.dart';
import 'dart:convert';
import '../models/sellers.dart';
import '../screens/restaurant_detail_screen.dart';

class SellerCarouselWidget extends StatefulWidget {
  const SellerCarouselWidget({Key? key}) : super(key: key);

  @override
  _SellerCarouselWidgetState createState() => _SellerCarouselWidgetState();
}

class _SellerCarouselWidgetState extends State<SellerCarouselWidget> {
  bool isBase64(String str) {
    try {
      if (str.startsWith('data:image')) {
        return true;
      }
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("sellers")
            .where("status", isEqualTo: "approved")
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print('Error fetching sellers: ${snapshot.error}');
            return Center(
              child: Text(
                'Error loading restaurants',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No restaurants available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          return CarouselSlider(
            options: CarouselOptions(
              height: 200,
              aspectRatio: 16 / 9,
              viewportFraction: 0.4,
              initialPage: 0,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOut,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
            ),
            items: snapshot.data!.docs.map((document) {
              String avatar = document['sellerAvatarBase64'] ?? '';
              String name = document['sellerName'] ?? 'Unknown';
              String sellerUID = document.id;
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => RestaurantDetailScreen(
                        model: Sellers.fromJson(document.data() as Map<String, dynamic>),
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFAC898), Color(0xFFFFE0B2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Avatar Image
                        Positioned.fill(
                          child: avatar.isNotEmpty
                              ? (avatar.startsWith('http')
                                  ? Image.network(
                                      avatar,
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
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading network image: $error');
                                        return _buildPlaceholder();
                                      },
                                    )
                                  : (isBase64(avatar)
                                      ? Image.memory(
                                          avatar.startsWith('data:image')
                                              ? base64Decode(avatar.split(',')[1])
                                              : base64Decode(avatar),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading base64 image: $error');
                                            return _buildPlaceholder();
                                          },
                                        )
                                      : _buildPlaceholder()))
                              : _buildPlaceholder(),
                        ),
                        // Name Overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.store,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
}

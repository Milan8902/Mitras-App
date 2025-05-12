import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sellers_food_app/models/menus.dart';
import '../global/global.dart';
import '../screens/items_screen.dart';

class InfoDesignWidget extends StatefulWidget {
  final Menus? model;
  final BuildContext? context;

  const InfoDesignWidget({Key? key, this.context, this.model})
    : super(key: key);

  @override
  _InfoDesignWidgetState createState() => _InfoDesignWidgetState();
}

class _InfoDesignWidgetState extends State<InfoDesignWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void deleteMenu(String menuID) {
    FirebaseFirestore.instance
        .collection("sellers")
        .doc(sharedPreferences!.getString("uid"))
        .collection("menus")
        .doc(menuID)
        .delete();

    Fluttertoast.showToast(msg: "Menu Deleted");
  }

  @override
  Widget build(BuildContext context) {
    if (widget.model == null) {
      return const Center(child: Text("No menu data available."));
    }

    Widget imageWidget;
    const double imageSize = 70; // Adjusted for vertical layout

    // Priority: imageUrl > base64Image
    if (widget.model!.imageUrl != null && widget.model!.imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        widget.model!.imageUrl!,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: imageSize,
            height: imageSize,
            child: Center(
              child: CircularProgressIndicator(color: const Color(0xFFF57C00)),
            ),
          );
        },
        errorBuilder:
            (context, error, stackTrace) => Icon(
              Icons.broken_image,
              size: imageSize,
              color: Colors.grey[400],
            ),
      );
    } else if (widget.model!.imageUrl != null &&
        widget.model!.imageUrl!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(widget.model!.imageUrl!);
        imageWidget = Image.memory(
          imageBytes,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
        );
      } catch (e) {
        imageWidget = Icon(
          Icons.broken_image,
          size: imageSize,
          color: Colors.grey[400],
        );
      }
    } else {
      imageWidget = Icon(
        Icons.image_not_supported,
        size: imageSize,
        color: Colors.grey[400],
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => ItemsScreen(model: widget.model)),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE1F5FE),
                          width: 2,
                        ),
                      ),
                      child: imageWidget,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Text Content
                  Text(
                    widget.model!.menuTitle ?? "No Title",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  Text(
                    widget.model!.menuInfo ?? "No Info",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Popup Menu
                  // Align(
                  //   alignment: Alignment.topRight,
                  //   child: PopupMenuButton<String>(
                  //     onSelected: (value) {
                  //       if (value == 'delete') {
                  //         deleteMenu(widget.model!.menuID!);
                  //       }
                  //     },
                  //     itemBuilder:
                  //         (BuildContext context) => [
                  //           PopupMenuItem<String>(
                  //             value: 'delete',
                  //             child: Row(
                  //               children: [
                  //                 const Icon(
                  //                   Icons.delete,
                  //                   color: Color(0xFFFF4081),
                  //                 ),
                  //                 const SizedBox(width: 8),
                  //                 Text(
                  //                   'Delete',
                  //                   style: GoogleFonts.poppins(
                  //                     fontSize: 14,
                  //                     color: Colors.black87,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ),
                  //         ],
                  //     icon: const Icon(
                  //       Icons.more_vert,
                  //       color: Color(0xFF0288D1),
                  //       size: 20,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     color: Colors.white,
                  //     elevation: 4,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

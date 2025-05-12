import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:users_food_app/models/menus.dart';
import 'package:users_food_app/screens/items_screen.dart';

// ignore: must_be_immutable
class MenusDesignWidget extends StatefulWidget {
  Menus? model;

  MenusDesignWidget({Key? key, this.model}) : super(key: key);

  @override
  _MenusDesignWidgetState createState() => _MenusDesignWidgetState();
}

class _MenusDesignWidgetState extends State<MenusDesignWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  // Function to determine if a string is a valid Base64 format
  bool isBase64(String str) {
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return base64Pattern.hasMatch(str);
  }

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

  @override
  Widget build(BuildContext context) {
    // Check if model is null
    if (widget.model == null) {
      return const Center(
        child: Text(
          "No menu data available",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Image widget logic
    Widget imageWidget;
    const double imageSize = 120; // Match ItemsDesign

    if (widget.model?.imageUrl != null) {
      final imgStr = widget.model!.imageUrl!;
      if (imgStr.startsWith('http')) {
        // Handle as image URL
        imageWidget = Image.network(
          imgStr,
          height: imageSize,
          width: imageSize,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: imageSize,
              width: imageSize,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF40C4FF),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image,
            size: imageSize * 0.5,
            color: Colors.grey[400],
          ),
        );
      } else if (isBase64(imgStr)) {
        // Try decoding as base64
        try {
          final imageBytes = base64Decode(imgStr);
          imageWidget = Image.memory(
            imageBytes,
            height: imageSize,
            width: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image,
              size: imageSize * 0.5,
              color: Colors.grey[400],
            ),
          );
        } catch (e) {
          imageWidget = Icon(
            Icons.broken_image,
            size: imageSize * 0.5,
            color: Colors.grey[400],
          );
        }
      } else {
        imageWidget = Icon(
          Icons.broken_image,
          size: imageSize * 0.5,
          color: Colors.grey[400],
        );
      }
    } else {
      // No image provided
      imageWidget = Container(
        height: imageSize,
        width: imageSize,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.restaurant_menu,
          size: 50,
          color: Color(0xFFF57C00),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ItemsScreen(model: widget.model),
          ),
        );
      },
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          transformAlignment: Alignment.center,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(3),
          height: 220, // Fixed height to match ItemsDesign
          width: 160, // Fixed width to match ItemsDesign
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE1F5FE),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageWidget,
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                widget.model?.menuTitle ?? 'No Title',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF57C00),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                widget.model?.menuInfo ?? 'No description',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sellers.dart';
import '../../screens/menus_screen.dart';

class SellersDesignWidget extends StatefulWidget {
  final Sellers? model;
  final BuildContext? context;

  const SellersDesignWidget({Key? key, this.context, this.model})
    : super(key: key);

  @override
  _SellersDesignWidgetState createState() => _SellersDesignWidgetState();
}

class _SellersDesignWidgetState extends State<SellersDesignWidget> {
  Widget _buildAvatar() {
    try {
      final avatar = widget.model?.sellerAvatarBase64;
      if (avatar == null || avatar.isEmpty) return _buildPlaceholder();

      // Handle network image
      if (avatar.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Image.network(
            avatar,
            height: 80,
            width: 80,
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
              print("Error loading network image: $error");
              return _buildPlaceholder();
            },
          ),
        );
      }

      // Handle Base64 image
      if (avatar.startsWith('data:image') || avatar.startsWith('data:image/jpeg') || avatar.startsWith('data:image/png')) {
        try {
          final imageBytes = base64Decode(avatar.split(',')[1]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.memory(
              imageBytes,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print("Error loading Base64 image: $error");
                return _buildPlaceholder();
              },
            ),
          );
        } catch (e) {
          print("Error decoding Base64 image: $e");
          return _buildPlaceholder();
        }
      }

      // Try direct base64 decoding
      try {
        final imageBytes = base64Decode(avatar);
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Image.memory(
            imageBytes,
            height: 80,
            width: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("Error loading direct Base64 image: $error");
              return _buildPlaceholder();
            },
          ),
        );
      } catch (e) {
        print("Error decoding direct Base64 image: $e");
        return _buildPlaceholder();
      }
    } catch (e) {
      print("Error building avatar: $e");
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.store,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => MenusScreen(model: widget.model)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white.withOpacity(0.9)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(height: 16),
              // Details
              Text(
                widget.model?.sellerName ?? "Unknown",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.model?.sellerEmail ?? "No email",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.amber,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

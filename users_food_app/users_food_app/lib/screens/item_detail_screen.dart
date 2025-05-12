import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:number_inc_dec/number_inc_dec.dart';
import '../assistantMethods/assistant_methods.dart';
import '../models/items.dart';
import '../widgets/app_bar.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Items? model;
  const ItemDetailsScreen({Key? key, this.model}) : super(key: key);

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController counterTextEditingController = TextEditingController();
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
    counterTextEditingController.text = '1';
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
    counterTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Image widget logic
    Widget imageWidget;
    const double imageSize = 200;

    if (widget.model?.imageUrl != null) {
      final imgStr = widget.model!.imageUrl!;
      if (imgStr.startsWith('http')) {
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
        try {
          final imageBytes = base64Decode(imgStr);
          imageWidget = Image.memory(
            imageBytes,
            height: imageSize,
            width: imageSize,
            fit: BoxFit.cover,
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
      imageWidget = Container(
        height: imageSize,
        width: imageSize,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.fastfood,
          size: 50,
          color: Color(0xFFF57C00),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MyAppBar(sellerUID: widget.model!.sellerUID),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isHovered = true),
            onTapUp: (_) => setState(() => _isHovered = false),
            onTapCancel: () => setState(() => _isHovered = false),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
                transformAlignment: Alignment.center,
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      widget.model?.title ?? 'No Title',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF57C00),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      widget.model?.longDescription ?? 'No description',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Price: ",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Rs ${widget.model?.price?.toString() ?? '0'}",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF57C00),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Counter
                    Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE1F5FE),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: NumberInputWithIncrementDecrement(
                        controller: counterTextEditingController,
                        numberFieldDecoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        widgetContainerDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF57C00),
                            width: 1,
                          ),
                        ),
                        incIconDecoration: BoxDecoration(
                          color: const Color(0xFFF57C00),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        decIconDecoration: BoxDecoration(
                          color: const Color(0xFFF57C00),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        incIcon: Icons.add,
                        decIcon: Icons.remove,
                        incIconSize: 20,
                        decIconSize: 20,
                        max: 9,
                        min: 1,
                        initialValue: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Add to Cart Button
                    GestureDetector(
                      onTap: () {
                        int itemCounter =
                            int.parse(counterTextEditingController.text);
                        List<String> separateItemIDsList = separateItemIDs();
                        separateItemIDsList.contains(widget.model!.itemID)
                            ? Fluttertoast.showToast(
                                msg: "Item is already in Cart")
                            : addItemToCart(
                                widget.model!.itemID, context, itemCounter);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 40),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF57C00), Color(0xFFEF5350)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Add to Cart'.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
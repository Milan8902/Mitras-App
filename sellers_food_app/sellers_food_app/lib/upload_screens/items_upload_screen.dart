// ignore_for_file: library_prefixes

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sellers_food_app/global/global.dart';
import 'package:sellers_food_app/widgets/progress_bar.dart';
import '../models/menus.dart';

class ItemsUploadScreen extends StatefulWidget {
  final Menus? model;

  const ItemsUploadScreen({Key? key, this.model}) : super(key: key);

  @override
  _ItemsUploadScreenState createState() => _ItemsUploadScreenState();
}

class _ItemsUploadScreenState extends State<ItemsUploadScreen>
    with SingleTickerProviderStateMixin {
  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController shortInfoController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  bool uploading = false;
  bool useImageUrl = false;
  String uniqueIdName = DateTime.now().millisecondsSinceEpoch.toString();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    shortInfoController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void clearMenuUploadFrom() {
    setState(() {
      shortInfoController.clear();
      titleController.clear();
      priceController.clear();
      descriptionController.clear();
      imageUrlController.clear();
      imageXFile = null;
      useImageUrl = false;
    });
  }

  Future<void> validateUploadForm() async {
    if (useImageUrl ? imageUrlController.text.isNotEmpty : imageXFile != null) {
      if (shortInfoController.text.isNotEmpty &&
          titleController.text.isNotEmpty &&
          descriptionController.text.isNotEmpty &&
          priceController.text.isNotEmpty) {
        setState(() => uploading = true);

        try {
          if (useImageUrl) {
            String imageUrl = imageUrlController.text.trim();
            // Format URL if needed
            imageUrl = _formatImageUrl(imageUrl);
            await saveInfoWithUrl(imageUrl);
          } else {
            String imageBase64 = await convertImageToBase64(File(imageXFile!.path));
            await saveInfo(imageBase64);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item uploaded successfully")),
          );
        } catch (e) {
          setState(() => uploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(useImageUrl
              ? "Please enter an image URL"
              : "Please pick an image"),
        ),
      );
    }
  }

  String _formatImageUrl(String url) {
    // Remove any whitespace
    url = url.trim();
    
    // If URL doesn't start with http:// or https://, add https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    return url;
  }

  Future<String> convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> saveInfo(String imageBase64) async {
    final ref = FirebaseFirestore.instance
        .collection("sellers")
        .doc(sharedPreferences!.getString("uid"))
        .collection("menus")
        .doc(widget.model!.menuID)
        .collection("items");

    final itemsRef = FirebaseFirestore.instance.collection("items");

    final data = {
      "itemID": uniqueIdName,
      "menuID": widget.model!.menuID,
      "sellerUID": sharedPreferences!.getString("uid"),
      "sellerName": sharedPreferences!.getString("name"),
      "shortInfo": shortInfoController.text.trim(),
      "longDescription": descriptionController.text.trim(),
      "price": int.parse(priceController.text.trim()),
      "title": titleController.text.trim(),
      "publishedDate": DateTime.now(),
      "status": "available",
      "imageBase64": imageBase64,
    };

    await ref.doc(uniqueIdName).set(data);
    await itemsRef.doc(uniqueIdName).set(data);

    clearMenuUploadFrom();
    setState(() {
      uniqueIdName = DateTime.now().millisecondsSinceEpoch.toString();
      uploading = false;
    });
  }

  Future<void> saveInfoWithUrl(String imageUrl) async {
    final ref = FirebaseFirestore.instance
        .collection("sellers")
        .doc(sharedPreferences!.getString("uid"))
        .collection("menus")
        .doc(widget.model!.menuID)
        .collection("items");

    final itemsRef = FirebaseFirestore.instance.collection("items");

    final data = {
      "itemID": uniqueIdName,
      "menuID": widget.model!.menuID,
      "sellerUID": sharedPreferences!.getString("uid"),
      "sellerName": sharedPreferences!.getString("name"),
      "shortInfo": shortInfoController.text.trim(),
      "longDescription": descriptionController.text.trim(),
      "price": int.parse(priceController.text.trim()),
      "title": titleController.text.trim(),
      "publishedDate": DateTime.now(),
      "status": "available",
      "imageUrl": imageUrl,
    };

    await ref.doc(uniqueIdName).set(data);
    await itemsRef.doc(uniqueIdName).set(data);

    clearMenuUploadFrom();
    setState(() {
      uniqueIdName = DateTime.now().millisecondsSinceEpoch.toString();
      uploading = false;
    });
  }

  void takeImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) {
        return SimpleDialog(
          title: Text(
            "Item Image",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFA726),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          children: [
            SimpleDialogOption(
              child: Text(
                "Enter Image URL",
                style: GoogleFonts.poppins(color: Colors.grey.shade700),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => useImageUrl = true);
                _showImageUrlDialog();
              },
            ),
            SimpleDialogOption(
              child: Center(
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showImageUrlDialog() {
    showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text(
            "Enter Image URL",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFA726),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  hintText: "example.com/image.jpg",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You can enter:\n• Full URL (https://example.com/image.jpg)\n• Domain only (example.com/image.jpg)",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                if (imageUrlController.text.isNotEmpty) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter an image URL")),
                  );
                }
              },
              child: Text(
                "OK",
                style: GoogleFonts.poppins(color: const Color(0xFFFFA726)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget defaultScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Add New Item",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFFFA726), const Color(0xFFF57C00)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, const Color(0xFFFFF3E0).withOpacity(0.5)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shop_two,
                      size: 100,
                      color: const Color(0xFFFFA726).withOpacity(0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Add a New Item",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select an image to start",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => takeImage(context),
                      icon: const Icon(Icons.add_a_photo, size: 20),
                      label: Text(
                        "Select Image",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA726),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
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

  Widget itemsUploadFormScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "New Item Form",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFFFA726), const Color(0xFFF57C00)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: clearMenuUploadFrom,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: uploading ? null : validateUploadForm,
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, const Color(0xFFFFF3E0).withOpacity(0.5)],
          ),
        ),
        child: uploading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFA726),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add Item Details",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (useImageUrl)
                            TextField(
                              controller: imageUrlController,
                              decoration: InputDecoration(
                                labelText: "Image URL",
                                labelStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFA726),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            )
                          else
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade100,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: imageXFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(imageXFile!.path),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: 50,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey.shade400,
                                        size: 50,
                                      ),
                                    ),
                            ),
                          if (useImageUrl) const SizedBox(height: 16),
                          if (useImageUrl && imageUrlController.text.isNotEmpty)
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade100,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrlController.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: "Item Title",
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFA726),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: shortInfoController,
                            decoration: InputDecoration(
                              labelText: "Short Info",
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFA726),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                              labelText: "Description",
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFA726),
                                  width: 2,
                                ),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Price",
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFA726),
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.monetization_on,
                                color: Color(0xFFFFA726),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: uploading ? null : validateUploadForm,
                              icon: const Icon(Icons.cloud_upload, size: 20),
                              label: Text(
                                "Upload Item",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA726),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 2,
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

  @override
  Widget build(BuildContext context) {
    return (imageXFile == null && !useImageUrl)
        ? defaultScreen()
        : itemsUploadFormScreen();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadMenuScreen extends StatefulWidget {
  const UploadMenuScreen({Key? key}) : super(key: key);

  @override
  State<UploadMenuScreen> createState() => _UploadMenuScreenState();
}

class _UploadMenuScreenState extends State<UploadMenuScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController shortInfoController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  bool uploading = false;
  String uniqueIdName = DateTime.now().millisecondsSinceEpoch.toString();
  late SharedPreferences sharedPreferences;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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
    titleController.dispose();
    shortInfoController.dispose();
    imageUrlController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  Future<void> saveInfo() async {
    final uid = sharedPreferences.getString("uid");
    final imageUrl = imageUrlController.text.trim();
    final title = titleController.text.trim();
    final info = shortInfoController.text.trim();

    if (uid == null || imageUrl.isEmpty || title.isEmpty || info.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => uploading = true);

    try {
      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(uid)
          .collection("menus")
          .doc(uniqueIdName)
          .set({
            "menuID": uniqueIdName,
            "sellerUID": uid,
            "menuTitle": title,
            "menuInfo": info,
            "publishedDate": DateTime.now(),
            "status": "available",
            "imageUrl": imageUrl,
          });

      setState(() {
        uploading = false;
        uniqueIdName = DateTime.now().millisecondsSinceEpoch.toString();
        titleController.clear();
        shortInfoController.clear();
        imageUrlController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menu uploaded successfully")),
      );
    } catch (e) {
      setState(() => uploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Upload Menu",
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
        child:
            uploading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFA726)),
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
                              "Add New Menu",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
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
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade100,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child:
                                  imageUrlController.text.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrlController.text.trim(),
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
                            const SizedBox(height: 20),
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: "Menu Title",
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
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: saveInfo,
                                icon: const Icon(Icons.cloud_upload, size: 20),
                                label: Text(
                                  "Upload Menu",
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
}

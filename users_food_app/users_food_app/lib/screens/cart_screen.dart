import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:users_food_app/assistantMethods/assistant_methods.dart';
import 'package:users_food_app/assistantMethods/total_amount.dart';
import 'package:users_food_app/global/global.dart';
import 'package:users_food_app/splash_screen/splash_screen.dart';
import 'package:users_food_app/widgets/design/cart_item_design.dart';
import 'package:users_food_app/widgets/progress_bar.dart';
import '../assistantMethods/cart_item_counter.dart';
import '../models/items.dart';
import '../widgets/text_widget_header.dart';
import 'address_screen.dart';
import 'home_screen.dart';

class CartScreen extends StatefulWidget {
  final String? sellerUID;

  const CartScreen({Key? key, this.sellerUID}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  List<int>? separateItemQuantityList;
  num totalAmount = 0;
  String? firstProductName;
  double? firstProductPrice;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isClearHovered = false;
  bool _isCheckoutHovered = false;

  @override
  void initState() {
    super.initState();
    totalAmount = 0;
    Provider.of<TotalAmount>(context, listen: false).displayTotalAmount(0);
    separateItemQuantityList = separateItemQuantities();
    firstProductName = getFirstProductName();
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

  String? getFirstProductName() {
    List<String> userCartList =
        sharedPreferences!.getStringList("userCart") ?? [];
    if (userCartList.isNotEmpty) {
      List<String> parts = userCartList[0].split("--");
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFF3E0)],
            ),
          ),
        ),
        title: Text(
          "My Cart",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF57C00),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.amber, Colors.orange]),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF3E0)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // SliverPersistentHeader(
            //   pinned: true,
            //   delegate: TextWidgetHeader(title: "Cart Items"),
            // ),
            SliverToBoxAdapter(
              child: Consumer2<TotalAmount, CartItemCounter>(
                builder: (context, amountProvider, cartProvider, c) {
                  return cartProvider.count == 0
                      ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            "Your cart is empty",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                      : Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
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
                        child: Text(
                          "Total Price: Rs ${amountProvider.tAmount.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF57C00),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                },
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("items")
                      .where("itemID", whereIn: separateItemIDs())
                      .orderBy("publishedDate", descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SliverToBoxAdapter(
                    child: Center(child: circularProgress()),
                  );
                }

                totalAmount = 0;
                final itemList = snapshot.data!.docs;

                if (itemList.isNotEmpty) {
                  Items firstItem = Items.fromJson(
                    itemList[0].data() as Map<String, dynamic>,
                  );
                  firstProductPrice = firstItem.price?.toDouble();
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    Items model = Items.fromJson(
                      itemList[index].data() as Map<String, dynamic>,
                    );
                    totalAmount +=
                        model.price! * separateItemQuantityList![index];

                    if (index == itemList.length - 1) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Provider.of<TotalAmount>(
                          context,
                          listen: false,
                        ).displayTotalAmount(totalAmount.toDouble());
                      });
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: CartItemDesign(
                        model: model,
                        context: context,
                        quanNumber: separateItemQuantityList![index],
                      ),
                    );
                  }, childCount: itemList.length),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100, // Space for floating buttons
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTapDown: (_) => setState(() => _isClearHovered = true),
            onTapUp: (_) => setState(() => _isClearHovered = false),
            onTapCancel: () => setState(() => _isClearHovered = false),
            onTap: () {
              clearCartNow(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const HomeScreen()),
              );
              Fluttertoast.showToast(msg: "Cart has been cleared.");
            },
            child: ScaleTransition(
              scale:
                  _isClearHovered
                      ? Tween<double>(
                        begin: 1.0,
                        end: 1.05,
                      ).animate(_controller)
                      : Tween<double>(
                        begin: 1.0,
                        end: 1.0,
                      ).animate(_controller),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.clear_all, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Clear Cart",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTapDown: (_) => setState(() => _isCheckoutHovered = true),
            onTapUp: (_) => setState(() => _isCheckoutHovered = false),
            onTapCancel: () => setState(() => _isCheckoutHovered = false),
            onTap: () {
              if (separateItemQuantityList == null || separateItemQuantityList!.isEmpty) {
                Fluttertoast.showToast(msg: "Your cart is empty. Please add items to proceed.");
                return;
              }
              
              if (totalAmount <= 0) {
                Fluttertoast.showToast(msg: "Please add items to your cart.");
                return;
              }
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (c) => AddressScreen(
                        totalAmount: totalAmount.toDouble(),
                        sellerUID: widget.sellerUID,
                        firstProductName: firstProductName,
                        firstProductPrice: firstProductPrice,
                      ),
                ),
              );
            },
            child: ScaleTransition(
              scale:
                  _isCheckoutHovered
                      ? Tween<double>(
                        begin: 1.0,
                        end: 1.05,
                      ).animate(_controller)
                      : Tween<double>(
                        begin: 1.0,
                        end: 1.0,
                      ).animate(_controller),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.navigate_next,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Check Out",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

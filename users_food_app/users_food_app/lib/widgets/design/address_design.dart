import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:users_food_app/assistantMethods/address_changer.dart';
import 'package:users_food_app/maps/maps.dart';
import 'package:users_food_app/models/address.dart';
import 'package:users_food_app/screens/placed_order_screen.dart';

class AddressDesign extends StatefulWidget {
  final Address? model;
  final int? currentIndex;
  final int? value;
  final String? addressID;
  final double? totalAmount;
  final String? sellerUID;
  final String? firstProductName;
  final double? firstProductPrice;

  const AddressDesign({
    Key? key,
    this.model,
    this.currentIndex,
    this.value,
    this.addressID,
    this.totalAmount,
    this.sellerUID,
    this.firstProductName,
    this.firstProductPrice,
  }) : super(key: key);

  @override
  _AddressDesignState createState() => _AddressDesignState();
}

class _AddressDesignState extends State<AddressDesign>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

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

  void _handleAddressSelection() async {
    try {
      await Provider.of<AddressChanger>(
        context,
        listen: false,
      ).displayResult(widget.value);

      if (mounted) {
        setState(() {
          // Only synchronous work here
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error selecting address: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: _handleAddressSelection,
      child: ScaleTransition(
        scale:
            _isHovered
                ? Tween<double>(begin: 1.0, end: 1.05).animate(_controller)
                : Tween<double>(begin: 1.0, end: 1.0).animate(_controller),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1F5FE), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<int>(
                      value: widget.value!,
                      groupValue: widget.currentIndex,
                      onChanged: (val) {
                        Provider.of<AddressChanger>(
                          context,
                          listen: false,
                        ).displayResult(val);
                      },
                      activeColor: const Color(0xFFF57C00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Name: ",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF57C00),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  model?.name ?? "N/A",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Phone Number: ",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF57C00),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  model?.phoneNumber ?? "N/A",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Full Address: ",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF57C00),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  model?.fullAddress ?? "N/A",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (widget.model?.lat != null && widget.model?.lng != null) {
                          await MapsUtils.openMapWithPosition(
                            widget.model!.lat!,
                            widget.model!.lng!,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Location coordinates not available"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error opening map: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF57C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 32),
                    ),
                    child: Text(
                      "Check on Maps",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                if (widget.value == Provider.of<AddressChanger>(context).count)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (c) => PlacedOrderScreen(
                                    addressID: widget.addressID,
                                    totalAmount: widget.totalAmount,
                                    sellerUID: widget.sellerUID,
                                    firstProductName: widget.firstProductName,
                                    firstProductPrice: widget.firstProductPrice,
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 32),
                        ),
                        child: Text(
                          "Proceed",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:users_food_app/assistantMethods/address_changer.dart';
// import 'package:users_food_app/maps/maps.dart';
// import 'package:users_food_app/models/address.dart';
// import 'package:users_food_app/screens/placed_order_screen.dart';

// class AddressDesign extends StatefulWidget {
//   final Address? model;
//   final int? currentIndex;
//   final int? value;
//   final String? addressID;
//   final double? totalAmount;
//   final String? sellerUID;
//   final String? firstProductName;
//   final double? firstProductPrice;

//   const AddressDesign({
//     Key? key,
//     this.model,
//     this.currentIndex,
//     this.value,
//     this.addressID,
//     this.totalAmount,
//     this.sellerUID,
//     this.firstProductName,
//     this.firstProductPrice,
//   }) : super(key: key);

//   @override
//   _AddressDesignState createState() => _AddressDesignState();
// }

// class _AddressDesignState extends State<AddressDesign>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   bool _isHovered = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );
//     _scaleAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOut,
//     );
//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => setState(() => _isHovered = true),
//       onTapUp: (_) => setState(() => _isHovered = false),
//       onTapCancel: () => setState(() => _isHovered = false),
//       onTap: () {
//         Provider.of<AddressChanger>(
//           context,
//           listen: false,
//         ).displayResult(widget.value);
//       },
//       child: ScaleTransition(
//         scale:
//             _isHovered
//                 ? Tween<double>(begin: 1.0, end: 1.05).animate(_controller)
//                 : Tween<double>(begin: 1.0, end: 1.0).animate(_controller),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: const Color(0xFFE1F5FE), width: 2),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey.withOpacity(0.2),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           clipBehavior: Clip.hardEdge, // Clip overflowing content
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Radio Button
//                     Radio<int>(
//                       value: widget.value!,
//                       groupValue: widget.currentIndex,
//                       onChanged: (val) {
//                         Provider.of<AddressChanger>(
//                           context,
//                           listen: false,
//                         ).displayResult(val);
//                       },
//                       activeColor: const Color(0xFFF57C00),
//                     ),
//                     const SizedBox(width: 8),
//                     // Address Details
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Name
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Name: ",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: const Color(0xFFF57C00),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Text(
//                                   widget.model!.name.toString(),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w400,
//                                     color: Colors.grey[600],
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                   maxLines: 1,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           // Phone Number
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Phone Number: ",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                   color: const Color(0xFFF57C00),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Text(
//                                   widget.model!.phoneNumber.toString(),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w400,
//                                     color: Colors.grey[600],
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                   maxLines: 1,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           // Full Address
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Full Address: ",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                   color: const Color(0xFFF57C00),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Text(
//                                   widget.model!.fullAddress.toString(),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w400,
//                                     color: Colors.grey[600],
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                   maxLines: 2,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 // Check on Maps Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       MapsUtils.openMapWithPosition(
//                         widget.model!.lat!,
//                         widget.model!.lng!,
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFF57C00),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       minimumSize: const Size(double.infinity, 32),
//                     ),
//                     child: Text(
//                       "Check on Maps",
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                     ),
//                   ),
//                 ),
//                 // Proceed Button (Conditional)
//                 if (widget.value == Provider.of<AddressChanger>(context).count)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (c) => PlacedOrderScreen(
//                                     addressID: widget.addressID,
//                                     totalAmount: widget.totalAmount,
//                                     sellerUID: widget.sellerUID,
//                                     firstProductName: widget.firstProductName,
//                                     firstProductPrice: widget.firstProductPrice,
//                                   ),
//                             ),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFF57C00),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           minimumSize: const Size(double.infinity, 32),
//                         ),
//                         child: Text(
//                           "Proceed",
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bringapp_admin_web_portal/screens/home_screen.dart';

class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget? bottom;
  final String? title;
  final List<Widget>? actions;

  const SimpleAppBar({
    super.key, 
    this.bottom, 
    this.title,
    this.actions,
  });

  @override
  Size get preferredSize => bottom == null
      ? Size.fromHeight(kToolbarHeight)
      : Size.fromHeight(kToolbarHeight + 80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff1b232A),
              Colors.white,
            ],
            begin: FractionalOffset(0, 0),
            end: FractionalOffset(6, 0),
            stops: [0, 1],
            tileMode: TileMode.clamp,
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
      ),
      title: Text(
        title ?? '',
        style: GoogleFonts.lato(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      bottom: bottom,
      automaticallyImplyLeading: true,
      actions: actions,
    );
  }
}

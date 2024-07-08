import 'package:flutter/material.dart';
import 'package:ceta/pages/auth_screen.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/auth/auth_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final AuthService authService;
  final UserWrapper? user;
  final bool hasIcons;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.authService,
    required this.user,
  }) : hasIcons = user != null;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  void handleLogOut() async {
    try {
      if (mounted) {
        Widget nextPage = AuthScreen(authService: widget.authService);
        await widget.authService.signOut();
        
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      }
    } catch (e) {
      if (mounted) {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      title: Row(
        children: [
          widget.hasIcons
              ? CircleAvatar(
                  backgroundImage: NetworkImage(
                    widget.user?.firebaseUser.photoURL ??
                        'https://via.placeholder.com/150',
                  ),
                  radius: 20,
                )
              : const SizedBox(
                  width: 40,
                  height: 40,
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        widget.hasIcons
            ? IconButton(
                color: Colors.white,
                icon: const Icon(Icons.logout),
                onPressed: handleLogOut,
              )
            : const SizedBox(),
      ],
    );
  }
}

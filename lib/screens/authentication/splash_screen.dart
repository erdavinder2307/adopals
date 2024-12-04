import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Find",
              style: TextStyle(
                fontSize: 40,
                color: Color(0xFF8B5EA9),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your Perfect Pet Companion!",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF8B5EA9),
              ),
            ),
            const SizedBox(height: 30),
            Stack(

                alignment: Alignment.center,
                children: [
                const CircleAvatar(
                  radius: 200,
                  backgroundColor: Color.fromARGB(255, 255, 171, 171), // Transparent background color
                ),
                Positioned(
                  top: 0,
                  left: 60,
                  child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent, // Transparent background color
                  foregroundImage: const AssetImage('assets/images/puppy.jpg'),
                  child: ClipOval(
                    child: Image.asset(
                    'assets/images/puppy.jpg',
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    ),
                  ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 60,
                  child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent, // Transparent background color
                  foregroundImage: const AssetImage('assets/images/parrot.jpg'),
                  child: ClipOval(
                    child: Image.asset(
                    'assets/images/parrot.jpg',
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    ),
                  ),
                  ),
                ),
                Positioned(
                  top: 90,
                  left: 0,
                  child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent, // Transparent background color
                  foregroundImage: const AssetImage('assets/images/small-fish.jpg'),
                  child: ClipOval(
                    child: Image.asset(
                    'assets/images/small-fish.jpg',
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    ),
                  ),
                  ),
                ),
                Positioned(
                  top: 90,
                  right: 0,
                  child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent, // Transparent background color
                  foregroundImage: const AssetImage('assets/images/baby-cat.jpg'),
                  child: ClipOval(
                    child: Image.asset(
                    'assets/images/baby-cat.jpg',
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    ),
                  ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: CircleAvatar(
                  minRadius: 120,
                  backgroundColor: Colors.transparent, // Transparent background color
                  child: ClipOval(
                    child: Image.asset(
                    'assets/images/woman.png',
                    fit: BoxFit.scaleDown,
                    width: 330,
                    height: 320,
                    ),
                  ),
                  ),
                ),
                ],
              
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                // Add navigation action here
              },
              child: const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF8B5EA9),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

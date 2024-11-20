import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFA9FF), // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Find",
              style: TextStyle(
                fontSize: 40,
                color: Color(0xFF8B5EA9),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your Perfect Pet Companion!",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF8B5EA9),
              ),
            ),
            SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundColor:
                      Colors.pinkAccent[100], // Circle background color
                ),
                Positioned(
                  top: 20,
                  left: 50,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/puppy.jpg'),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 50,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/parrot.jpg'),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 50,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/small-fish.jpg'),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 50,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/baby-cat.jpg'),
                  ),
                ),
                Positioned(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        AssetImage('assets/images/woman.jpg'), // Center image
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                // Add navigation action here
              },
              child: CircleAvatar(
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

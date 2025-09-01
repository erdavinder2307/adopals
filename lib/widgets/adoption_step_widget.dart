import 'package:flutter/material.dart';

class AdoptionStepWidget extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;
  final String? imagePath;
  final IconData? iconData;

  const AdoptionStepWidget({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.imagePath,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step number circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Image or Icon
            if (imagePath != null)
              Container(
                width: 80,
                height: 80,
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.contain,
                ),
              )
            else if (iconData != null)
              Icon(
                iconData!,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

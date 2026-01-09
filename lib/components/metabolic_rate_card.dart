import 'package:flutter/material.dart';

class MetabolicRateCard extends StatelessWidget {
  final int bmr;
  const MetabolicRateCard({super.key, required this.bmr});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AspectRatio(
      aspectRatio: 1.1,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.favorite_outline, color: isDarkMode ? Colors.pink[300] : Colors.white70, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Metabolic Rate',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                bmr.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              'Kcal',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

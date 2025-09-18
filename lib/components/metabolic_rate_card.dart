import 'package:flutter/material.dart';

class MetabolicRateCard extends StatelessWidget {
  final int bmr;
  const MetabolicRateCard({super.key, required this.bmr});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.favorite_outline, color: Colors.white70, size: 22),
                SizedBox(width: 8),
                Text('Metabolic Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white70)),
              ],
            ),
            Text(
              bmr.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
            ),
            const Text('Kcal', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

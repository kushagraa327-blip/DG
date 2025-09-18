import 'package:flutter/material.dart';

class CaloriesCard extends StatelessWidget {
  final int caloriesConsumed;
  final int calorieGoal;
  final double percent;

  const CaloriesCard({
    super.key,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        return Center(
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: Colors.grey[700], size: 22),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Calories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[700])),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: size * 0.35,
                          height: size * 0.35,
                          child: CircularProgressIndicator(
                            value: percent,
                            strokeWidth: 7,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA25B)),
                          ),
                        ),
                        Text('${(percent * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFFFFA25B))),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: caloriesConsumed.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.grey[800]),
                          ),
                          TextSpan(
                            text: ' out of ',
                            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.grey[600]),
                          ),
                          TextSpan(
                            text: calorieGoal.toString(),
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

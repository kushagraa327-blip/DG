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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
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
                      Icon(Icons.wb_sunny_outlined, color: isDarkMode ? Colors.grey[400] : Colors.grey[700], size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Calories',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: size * 0.4,
                          height: size * 0.4,
                          child: CircularProgressIndicator(
                            value: percent.clamp(0.0, 1.0),
                            strokeWidth: 8,
                            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA25B)),
                          ),
                        ),
                        Text(
                          '${(percent * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDarkMode ? const Color(0xFFFFA25B) : const Color(0xFFFFA25B),
                          ),
                        ),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: isDarkMode ? Colors.white : Colors.grey[800],
                            ),
                          ),
                          TextSpan(
                            text: ' out of ',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          TextSpan(
                            text: calorieGoal.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
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

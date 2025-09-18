import 'package:flutter/material.dart';

class SignUpStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SignUpStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Step $currentStep/$totalSteps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          // Step pagination with underlines
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber <= currentStep;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

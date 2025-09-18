import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../main.dart';
import '../models/meal_entry_model.dart';

class EmojiTestWidget extends StatelessWidget {
  const EmojiTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emoji Test')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Observer(
            builder: (_) => Column(
              children: [
                Text('Current Mood: ${nutritionStore.avatarMood}'),
                Text('Current Emoji: ${nutritionStore.avatarMood.emoji}'),
                const SizedBox(height: 20),
                Text(
                  nutritionStore.avatarMood.emoji,
                  style: const TextStyle(fontSize: 60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              print('🔍 Before change: ${nutritionStore.avatarMood}');
              if (nutritionStore.avatarMood == AvatarMood.neutral) {
                nutritionStore.setAvatarMood(AvatarMood.joyful);
                print('🔄 Changed to joyful');
              } else {
                nutritionStore.setAvatarMood(AvatarMood.neutral);
                print('🔄 Changed to neutral');
              }
              print('🔍 After change: ${nutritionStore.avatarMood}');
            },
            child: const Text('Toggle Emoji'),
          ),
        ],
      ),
    );
  }
}

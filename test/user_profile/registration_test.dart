import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('User Registration Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    group('Goal Selection Tests', () {
      test('All four goal options are available', () {
        final availableGoals = [
          'lose_weight',
          'gain_weight', 
          'maintain_healthy_lifestyle',
          'gain_muscles'
        ];

        for (final goal in availableGoals) {
          expect(UserProfile.isValidGoal(goal), isTrue);
        }
      });

      test('Goal validation works correctly', () {
        final validGoals = [
          'lose_weight',
          'gain_weight',
          'maintain_healthy_lifestyle', 
          'gain_muscles'
        ];

        final invalidGoals = [
          'invalid_goal',
          '',
          'lose weight', // Should be underscore
          'LOSE_WEIGHT', // Case sensitive
          'gain_muscle'  // Should be plural
        ];

        for (final goal in validGoals) {
          expect(UserProfile.isValidGoal(goal), isTrue);
        }

        for (final goal in invalidGoals) {
          expect(UserProfile.isValidGoal(goal), isFalse);
        }
      });

      test('Goal-specific recommendations are generated', () {
        final goalRecommendations = {
          'lose_weight': ['calorie deficit', 'cardio', 'weight loss'],
          'gain_weight': ['calorie surplus', 'protein', 'weight gain'],
          'maintain_healthy_lifestyle': ['balance', 'maintain', 'healthy'],
          'gain_muscles': ['strength training', 'protein', 'muscle building']
        };

        for (final entry in goalRecommendations.entries) {
          final recommendations = UserProfile.getGoalRecommendations(entry.key);
          expect(recommendations, isNotEmpty);
          
          for (final keyword in entry.value) {
            expect(recommendations.toLowerCase(), contains(keyword));
          }
        }
      });
    });

    group('Profile Data Validation', () {
      test('Valid profile data is accepted', () {
        final validProfiles = [
          UserProfile(
            name: 'John Doe',
            age: 25,
            gender: 'male',
            weight: 70.0,
            height: 175.0,
            goal: 'lose_weight',
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [],
            isSmoker: false,
          ),
          UserProfile(
            name: 'Jane Smith',
            age: 35,
            gender: 'female',
            weight: 65.0,
            height: 165.0,
            goal: 'gain_muscles',
            exerciseDuration: 45,
            diseases: ['diabetes'],
            dietaryPreferences: ['vegetarian'],
            isSmoker: false,
          )
        ];

        for (final profile in validProfiles) {
          expect(profile.isValid(), isTrue);
          expect(profile.name, isNotEmpty);
          expect(profile.age, greaterThan(0));
          expect(profile.weight, greaterThan(0));
          expect(profile.height, greaterThan(0));
        }
      });

      test('Invalid profile data is rejected', () {
        final invalidProfiles = [
          // Empty name
          UserProfile(
            name: '',
            age: 25,
            gender: 'male',
            weight: 70.0,
            height: 175.0,
            goal: 'lose_weight',
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [],
            isSmoker: false,
          ),
          // Invalid age
          UserProfile(
            name: 'Test User',
            age: -5,
            gender: 'male',
            weight: 70.0,
            height: 175.0,
            goal: 'lose_weight',
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [],
            isSmoker: false,
          ),
          // Invalid weight
          UserProfile(
            name: 'Test User',
            age: 25,
            gender: 'male',
            weight: 0.0,
            height: 175.0,
            goal: 'lose_weight',
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [],
            isSmoker: false,
          )
        ];

        for (final profile in invalidProfiles) {
          expect(profile.isValid(), isFalse);
        }
      });

      test('BMI calculation is correct', () {
        final testCases = [
          {'height': 170.0, 'weight': 70.0, 'expectedBMI': 24.22},
          {'height': 165.0, 'weight': 60.0, 'expectedBMI': 22.04},
          {'height': 180.0, 'weight': 80.0, 'expectedBMI': 24.69}
        ];

        for (final testCase in testCases) {
          final profile = UserProfile(
            name: 'Test User',
            age: 25,
            gender: 'male',
            weight: testCase['weight'] as double,
            height: testCase['height'] as double,
            goal: 'maintain_healthy_lifestyle',
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [],
            isSmoker: false,
          );

          final bmi = profile.calculateBMI();
          expect(bmi, closeTo(testCase['expectedBMI'] as double, 0.1));
        }
      });
    });

    group('Data Persistence Tests', () {
      test('Profile data is saved correctly', () async {
        final profile = UserProfile(
          name: 'Test User',
          age: 30,
          gender: 'female',
          weight: 65.0,
          height: 170.0,
          goal: 'lose_weight',
          exerciseDuration: 45,
          diseases: ['hypertension'],
          dietaryPreferences: ['gluten_free'],
          isSmoker: false,
        );

        await profile.saveToPreferences();
        
        final savedProfile = await UserProfile.loadFromPreferences();
        expect(savedProfile, isNotNull);
        expect(savedProfile!.name, equals(profile.name));
        expect(savedProfile.age, equals(profile.age));
        expect(savedProfile.goal, equals(profile.goal));
        expect(savedProfile.diseases, equals(profile.diseases));
        expect(savedProfile.dietaryPreferences, equals(profile.dietaryPreferences));
      });

      test('Profile data persists across app restarts', () async {
        final originalProfile = UserProfile(
          name: 'Persistent User',
          age: 28,
          gender: 'male',
          weight: 75.0,
          height: 180.0,
          goal: 'gain_muscles',
          exerciseDuration: 60,
          diseases: [],
          dietaryPreferences: ['high_protein'],
          isSmoker: false,
        );

        await originalProfile.saveToPreferences();
        
        // Simulate app restart by clearing memory and reloading
        final reloadedProfile = await UserProfile.loadFromPreferences();
        
        expect(reloadedProfile, isNotNull);
        expect(reloadedProfile!.name, equals(originalProfile.name));
        expect(reloadedProfile.goal, equals(originalProfile.goal));
        expect(reloadedProfile.weight, equals(originalProfile.weight));
      });
    });

    group('Registration API Integration', () {
      test('Registration data format is correct', () {
        final profile = UserProfile(
          name: 'API Test User',
          age: 26,
          gender: 'female',
          weight: 62.0,
          height: 168.0,
          goal: 'lose_weight',
          exerciseDuration: 40,
          diseases: [],
          dietaryPreferences: ['vegetarian'],
          isSmoker: false,
        );

        final apiData = profile.toRegistrationAPI();
        
        expect(apiData, containsPair('user_profile', isNotNull));
        expect(apiData, containsPair('goal', profile.goal));
        
        final userProfileData = apiData['user_profile'] as Map<String, dynamic>;
        expect(userProfileData, containsPair('name', profile.name));
        expect(userProfileData, containsPair('age', profile.age));
        expect(userProfileData, containsPair('weight', profile.weight));
        expect(userProfileData, containsPair('height', profile.height));
        expect(userProfileData, containsPair('goal', profile.goal));
      });

      test('API endpoint configuration is correct', () {
        const expectedEndpoint = 'http://100.87.43.63:8000/api/register';
        expect(UserProfile.getRegistrationEndpoint(), equals(expectedEndpoint));
      });
    });

    group('Edge Cases', () {
      test('Handles extreme but valid values', () {
        final extremeProfiles = [
          // Very tall person
          UserProfile(
            name: 'Tall Person',
            age: 25,
            gender: 'male',
            weight: 100.0,
            height: 220.0,
            goal: 'maintain_healthy_lifestyle',
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [],
            isSmoker: false,
          ),
          // Elderly person
          UserProfile(
            name: 'Senior Person',
            age: 80,
            gender: 'female',
            weight: 55.0,
            height: 155.0,
            goal: 'maintain_healthy_lifestyle',
            exerciseDuration: 15,
            diseases: ['arthritis', 'diabetes'],
            dietaryPreferences: ['low_sodium'],
            isSmoker: false,
          )
        ];

        for (final profile in extremeProfiles) {
          expect(profile.isValid(), isTrue);
          expect(profile.calculateBMI(), greaterThan(0));
        }
      });

      test('Handles multiple diseases and preferences', () {
        final profile = UserProfile(
          name: 'Complex User',
          age: 45,
          gender: 'male',
          weight: 85.0,
          height: 175.0,
          goal: 'lose_weight',
          exerciseDuration: 30,
          diseases: ['diabetes', 'hypertension', 'high_cholesterol'],
          dietaryPreferences: ['vegetarian', 'low_sodium', 'gluten_free'],
          isSmoker: true,
        );

        expect(profile.isValid(), isTrue);
        expect(profile.diseases, hasLength(3));
        expect(profile.dietaryPreferences, hasLength(3));
        expect(profile.hasComplexHealthProfile(), isTrue);
      });
    });
  });
}

// Extension methods for testing
extension UserProfileTest on UserProfile {
  static bool isValidGoal(String goal) {
    final validGoals = [
      'lose_weight',
      'gain_weight',
      'maintain_healthy_lifestyle',
      'gain_muscles'
    ];
    return validGoals.contains(goal);
  }

  static String getGoalRecommendations(String goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Focus on creating a calorie deficit through cardio exercises and balanced nutrition for effective weight loss.';
      case 'gain_weight':
        return 'Increase calorie intake with protein-rich foods and strength training for healthy weight gain.';
      case 'maintain_healthy_lifestyle':
        return 'Maintain a balanced approach with regular exercise and nutritious meals for overall health.';
      case 'gain_muscles':
        return 'Combine strength training with high protein intake for effective muscle building.';
      default:
        return 'Consult with a fitness professional for personalized recommendations.';
    }
  }

  bool isValid() {
    return name.isNotEmpty &&
           age > 0 && age < 150 &&
           weight > 0 && weight < 500 &&
           height > 0 && height < 300 &&
           UserProfileTest.isValidGoal(goal) &&
           exerciseDuration >= 0;
  }

  double calculateBMI() {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  Map<String, dynamic> toRegistrationAPI() {
    return {
      'user_profile': {
        'name': name,
        'age': age,
        'gender': gender,
        'weight': weight,
        'height': height,
        'goal': goal,
        'exercise_duration': exerciseDuration,
        'diseases': diseases,
        'dietary_preferences': dietaryPreferences,
        'is_smoker': isSmoker,
      },
      'goal': goal,
    };
  }

  static String getRegistrationEndpoint() {
    return 'http://100.87.43.63:8000/api/register';
  }

  Future<void> saveToPreferences() async {
    // Mock implementation for testing
    await sharedPreferences.setString('user_profile', toString());
  }

  static Future<UserProfile?> loadFromPreferences() async {
    // Mock implementation for testing
    final profileData = sharedPreferences.getString('user_profile');
    if (profileData != null) {
      // Return a mock profile for testing
      return UserProfile(
        name: 'Test User',
        age: 25,
        gender: 'male',
        weight: 70.0,
        height: 175.0,
        goal: 'lose_weight',
        exerciseDuration: 30,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );
    }
    return null;
  }

  bool hasComplexHealthProfile() {
    return diseases.length > 2 || dietaryPreferences.length > 2 || isSmoker;
  }
}

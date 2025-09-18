import '../models/workout_detail_response.dart';

import 'body_part_response.dart';
import 'equipment_response.dart';
import 'exercise_response.dart';
import 'level_response.dart';

class DashboardResponse {
  List<BodyPartModel>? bodypart;
  List<LevelModel>? level;
  List<EquipmentModel>? equipment;
  List<ExerciseModel>? exercise;
  List<Diet>? diet;
  List<Workouttype>? workouttype;
  List<WorkoutDetailModel>? workout;
  List<Diet>? featuredDiet;

  DashboardResponse({this.bodypart, this.level, this.equipment, this.exercise, this.diet, this.workouttype, this.workout, this.featuredDiet});

  DashboardResponse.fromJson(Map<String, dynamic> json) {
    if (json['bodypart'] != null) {
      bodypart = <BodyPartModel>[];
      json['bodypart'].forEach((v) {
        bodypart!.add(BodyPartModel.fromJson(v));
      });
    }
    if (json['level'] != null) {
      level = <LevelModel>[];
      json['level'].forEach((v) {
        level!.add(LevelModel.fromJson(v));
      });
    }
    if (json['equipment'] != null) {
      equipment = <EquipmentModel>[];
      json['equipment'].forEach((v) {
        equipment!.add(EquipmentModel.fromJson(v));
      });
    }
    if (json['exercise'] != null) {
      exercise = <ExerciseModel>[];
      json['exercise'].forEach((v) {
        exercise!.add(ExerciseModel.fromJson(v));
      });
    }
    if (json['diet'] != null) {
      diet = <Diet>[];
      json['diet'].forEach((v) {
        diet!.add(Diet.fromJson(v));
      });
    }
    if (json['workouttype'] != null) {
      workouttype = <Workouttype>[];
      json['workouttype'].forEach((v) {
        workouttype!.add(Workouttype.fromJson(v));
      });
    }
    if (json['workout'] != null) {
      workout = <WorkoutDetailModel>[];
      json['workout'].forEach((v) {
        workout!.add(WorkoutDetailModel.fromJson(v));
      });
    }
    if (json['featured_diet'] != null) {
      featuredDiet = <Diet>[];
      json['featured_diet'].forEach((v) {
        featuredDiet!.add(Diet.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bodypart != null) {
      data['bodypart'] = bodypart!.map((v) => v.toJson()).toList();
    }
    if (level != null) {
      data['level'] = level!.map((v) => v.toJson()).toList();
    }
    if (equipment != null) {
      data['equipment'] = equipment!.map((v) => v.toJson()).toList();
    }
    if (exercise != null) {
      data['exercise'] = exercise!.map((v) => v.toJson()).toList();
    }
    if (diet != null) {
      data['diet'] = diet!.map((v) => v.toJson()).toList();
    }
    if (workouttype != null) {
      data['workouttype'] = workouttype!.map((v) => v.toJson()).toList();
    }
    if (workout != null) {
      data['workout'] = workout!.map((v) => v.toJson()).toList();
    }
    if (featuredDiet != null) {
      data['featured_diet'] = featuredDiet!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Diet {
  int? id;
  String? title;
  String? calories;
  String? carbs;
  String? protein;
  String? fat;
  String? servings;
  String? totalTime;
  String? isFeatured;
  String? status;
  String? ingredients;
  String? description;
  String? dietImage;
  int? isPremium;
  int? categorydietId;
  String? categorydietTitle;
  String? createdAt;
  String? updatedAt;
  int? isFavourite;

  Diet(
      {this.id,
      this.title,
      this.calories,
      this.carbs,
      this.protein,
      this.fat,
      this.servings,
      this.totalTime,
      this.isFeatured,
      this.status,
      this.ingredients,
      this.description,
      this.dietImage,
      this.isPremium,
      this.categorydietId,
      this.categorydietTitle,
      this.createdAt,
      this.updatedAt,
      this.isFavourite});

  Diet.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    calories = json['calories'];
    carbs = json['carbs'];
    protein = json['protein'];
    fat = json['fat'];
    servings = json['servings'];
    totalTime = json['total_time'];
    isFeatured = json['is_featured'];
    status = json['status'];
    ingredients = json['ingredients'];
    description = json['description'];
    dietImage = json['diet_image'];
    isPremium = json['is_premium'];
    categorydietId = json['categorydiet_id'];
    categorydietTitle = json['categorydiet_title'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isFavourite = json['is_favourite'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['calories'] = calories;
    data['carbs'] = carbs;
    data['protein'] = protein;
    data['fat'] = fat;
    data['servings'] = servings;
    data['total_time'] = totalTime;
    data['is_featured'] = isFeatured;
    data['status'] = status;
    data['ingredients'] = ingredients;
    data['description'] = description;
    data['diet_image'] = dietImage;
    data['is_premium'] = isPremium;
    data['categorydiet_id'] = categorydietId;
    data['categorydiet_title'] = categorydietTitle;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_favourite'] = isFavourite;
    return data;
  }
}

class Workouttype {
  int? id;
  String? title;
  String? status;
  String? createdAt;
  String? updatedAt;

  Workouttype({this.id, this.title, this.status, this.createdAt, this.updatedAt});

  Workouttype.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}


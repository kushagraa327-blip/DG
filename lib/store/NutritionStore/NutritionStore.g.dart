// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NutritionStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NutritionStore on NutritionStoreBase, Store {
  Computed<List<MealEntry>>? _$todayMealsComputed;

  @override
  List<MealEntry> get todayMeals => (_$todayMealsComputed ??=
          Computed<List<MealEntry>>(() => super.todayMeals,
              name: 'NutritionStoreBase.todayMeals'))
      .value;
  Computed<DailyNutrition>? _$todayNutritionComputed;

  @override
  DailyNutrition get todayNutrition => (_$todayNutritionComputed ??=
          Computed<DailyNutrition>(() => super.todayNutrition,
              name: 'NutritionStoreBase.todayNutrition'))
      .value;
  Computed<double>? _$calorieProgressComputed;

  @override
  double get calorieProgress => (_$calorieProgressComputed ??= Computed<double>(
          () => super.calorieProgress,
          name: 'NutritionStoreBase.calorieProgress'))
      .value;
  Computed<double>? _$proteinProgressComputed;

  @override
  double get proteinProgress => (_$proteinProgressComputed ??= Computed<double>(
          () => super.proteinProgress,
          name: 'NutritionStoreBase.proteinProgress'))
      .value;
  Computed<double>? _$carbsProgressComputed;

  @override
  double get carbsProgress =>
      (_$carbsProgressComputed ??= Computed<double>(() => super.carbsProgress,
              name: 'NutritionStoreBase.carbsProgress'))
          .value;
  Computed<double>? _$fatProgressComputed;

  @override
  double get fatProgress =>
      (_$fatProgressComputed ??= Computed<double>(() => super.fatProgress,
              name: 'NutritionStoreBase.fatProgress'))
          .value;
  Computed<double>? _$weeklyAverageCaloriesComputed;

  @override
  double get weeklyAverageCalories => (_$weeklyAverageCaloriesComputed ??=
          Computed<double>(() => super.weeklyAverageCalories,
              name: 'NutritionStoreBase.weeklyAverageCalories'))
      .value;
  Computed<bool>? _$isOnTrackWithGoalsComputed;

  @override
  bool get isOnTrackWithGoals => (_$isOnTrackWithGoalsComputed ??=
          Computed<bool>(() => super.isOnTrackWithGoals,
              name: 'NutritionStoreBase.isOnTrackWithGoals'))
      .value;

  late final _$mealEntriesAtom =
      Atom(name: 'NutritionStoreBase.mealEntries', context: context);

  @override
  ObservableList<MealEntry> get mealEntries {
    _$mealEntriesAtom.reportRead();
    return super.mealEntries;
  }

  @override
  set mealEntries(ObservableList<MealEntry> value) {
    _$mealEntriesAtom.reportWrite(value, super.mealEntries, () {
      super.mealEntries = value;
    });
  }

  late final _$avatarMoodAtom =
      Atom(name: 'NutritionStoreBase.avatarMood', context: context);

  @override
  AvatarMood get avatarMood {
    _$avatarMoodAtom.reportRead();
    return super.avatarMood;
  }

  @override
  set avatarMood(AvatarMood value) {
    _$avatarMoodAtom.reportWrite(value, super.avatarMood, () {
      super.avatarMood = value;
    });
  }

  late final _$isAvatarMoodManuallySetAtom = Atom(
      name: 'NutritionStoreBase.isAvatarMoodManuallySet', context: context);

  @override
  bool get isAvatarMoodManuallySet {
    _$isAvatarMoodManuallySetAtom.reportRead();
    return super.isAvatarMoodManuallySet;
  }

  @override
  set isAvatarMoodManuallySet(bool value) {
    _$isAvatarMoodManuallySetAtom
        .reportWrite(value, super.isAvatarMoodManuallySet, () {
      super.isAvatarMoodManuallySet = value;
    });
  }

  late final _$nutritionGoalsAtom =
      Atom(name: 'NutritionStoreBase.nutritionGoals', context: context);

  @override
  NutritionGoals? get nutritionGoals {
    _$nutritionGoalsAtom.reportRead();
    return super.nutritionGoals;
  }

  @override
  set nutritionGoals(NutritionGoals? value) {
    _$nutritionGoalsAtom.reportWrite(value, super.nutritionGoals, () {
      super.nutritionGoals = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'NutritionStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$streakCountAtom =
      Atom(name: 'NutritionStoreBase.streakCount', context: context);

  @override
  int get streakCount {
    _$streakCountAtom.reportRead();
    return super.streakCount;
  }

  @override
  set streakCount(int value) {
    _$streakCountAtom.reportWrite(value, super.streakCount, () {
      super.streakCount = value;
    });
  }

  late final _$lastSyncDateAtom =
      Atom(name: 'NutritionStoreBase.lastSyncDate', context: context);

  @override
  String get lastSyncDate {
    _$lastSyncDateAtom.reportRead();
    return super.lastSyncDate;
  }

  @override
  set lastSyncDate(String value) {
    _$lastSyncDateAtom.reportWrite(value, super.lastSyncDate, () {
      super.lastSyncDate = value;
    });
  }

  late final _$initializeStoreAsyncAction =
      AsyncAction('NutritionStoreBase.initializeStore', context: context);

  @override
  Future<void> initializeStore() {
    return _$initializeStoreAsyncAction.run(() => super.initializeStore());
  }

  late final _$loadMealEntriesAsyncAction =
      AsyncAction('NutritionStoreBase.loadMealEntries', context: context);

  @override
  Future<void> loadMealEntries() {
    return _$loadMealEntriesAsyncAction.run(() => super.loadMealEntries());
  }

  late final _$saveMealEntriesAsyncAction =
      AsyncAction('NutritionStoreBase.saveMealEntries', context: context);

  @override
  Future<void> saveMealEntries() {
    return _$saveMealEntriesAsyncAction.run(() => super.saveMealEntries());
  }

  late final _$loadNutritionGoalsAsyncAction =
      AsyncAction('NutritionStoreBase.loadNutritionGoals', context: context);

  @override
  Future<void> loadNutritionGoals() {
    return _$loadNutritionGoalsAsyncAction
        .run(() => super.loadNutritionGoals());
  }

  late final _$saveNutritionGoalsAsyncAction =
      AsyncAction('NutritionStoreBase.saveNutritionGoals', context: context);

  @override
  Future<void> saveNutritionGoals() {
    return _$saveNutritionGoalsAsyncAction
        .run(() => super.saveNutritionGoals());
  }

  late final _$updateNutritionGoalsFromProfileAsyncAction = AsyncAction(
      'NutritionStoreBase.updateNutritionGoalsFromProfile',
      context: context);

  @override
  Future<void> updateNutritionGoalsFromProfile() {
    return _$updateNutritionGoalsFromProfileAsyncAction
        .run(() => super.updateNutritionGoalsFromProfile());
  }

  late final _$addMealEntryAsyncAction =
      AsyncAction('NutritionStoreBase.addMealEntry', context: context);

  @override
  Future<void> addMealEntry(MealEntry meal) {
    return _$addMealEntryAsyncAction.run(() => super.addMealEntry(meal));
  }

  late final _$updateMealEntryAsyncAction =
      AsyncAction('NutritionStoreBase.updateMealEntry', context: context);

  @override
  Future<void> updateMealEntry(String mealId, MealEntry updatedMeal) {
    return _$updateMealEntryAsyncAction
        .run(() => super.updateMealEntry(mealId, updatedMeal));
  }

  late final _$deleteMealEntryAsyncAction =
      AsyncAction('NutritionStoreBase.deleteMealEntry', context: context);

  @override
  Future<void> deleteMealEntry(String mealId) {
    return _$deleteMealEntryAsyncAction
        .run(() => super.deleteMealEntry(mealId));
  }

  late final _$clearAllMealsAsyncAction =
      AsyncAction('NutritionStoreBase.clearAllMeals', context: context);

  @override
  Future<void> clearAllMeals() {
    return _$clearAllMealsAsyncAction.run(() => super.clearAllMeals());
  }

  late final _$NutritionStoreBaseActionController =
      ActionController(name: 'NutritionStoreBase', context: context);

  @override
  void calculateStreakCount() {
    final _$actionInfo = _$NutritionStoreBaseActionController.startAction(
        name: 'NutritionStoreBase.calculateStreakCount');
    try {
      return super.calculateStreakCount();
    } finally {
      _$NutritionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateAvatarMood() {
    final _$actionInfo = _$NutritionStoreBaseActionController.startAction(
        name: 'NutritionStoreBase.updateAvatarMood');
    try {
      return super.updateAvatarMood();
    } finally {
      _$NutritionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAvatarMood(AvatarMood mood) {
    final _$actionInfo = _$NutritionStoreBaseActionController.startAction(
        name: 'NutritionStoreBase.setAvatarMood');
    try {
      return super.setAvatarMood(mood);
    } finally {
      _$NutritionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetAvatarMoodToAuto() {
    final _$actionInfo = _$NutritionStoreBaseActionController.startAction(
        name: 'NutritionStoreBase.resetAvatarMoodToAuto');
    try {
      return super.resetAvatarMoodToAuto();
    } finally {
      _$NutritionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
mealEntries: ${mealEntries},
avatarMood: ${avatarMood},
isAvatarMoodManuallySet: ${isAvatarMoodManuallySet},
nutritionGoals: ${nutritionGoals},
isLoading: ${isLoading},
streakCount: ${streakCount},
lastSyncDate: ${lastSyncDate},
todayMeals: ${todayMeals},
todayNutrition: ${todayNutrition},
calorieProgress: ${calorieProgress},
proteinProgress: ${proteinProgress},
carbsProgress: ${carbsProgress},
fatProgress: ${fatProgress},
weeklyAverageCalories: ${weeklyAverageCalories},
isOnTrackWithGoals: ${isOnTrackWithGoals}
    ''';
  }
}

class HeartRiskData {
  late final int age;
  final String sex; // 'Male' or 'Female'
  final double cholesterol;
  final String bloodPressure; // 'systolic/diastolic'
  final int heartRate;
  final bool diabetes;
  final bool familyHistory;
  final bool smoking;
  final bool obesity;
  final String alcoholConsumption; // 'none', 'light', 'moderate', 'heavy'
  final double exerciseHours;
  final String diet; // 'healthy', 'average', 'nonhealthy'
  final bool previousHeartProblems;
  final bool medicationUse;
  final int stressLevel; // 1-10
  final double sedentaryHours;
  final double income;
  final double bmi;
  final double triglycerides;
  final int physicalActivityDays;
  final double sleepHours;

  HeartRiskData({
    required this.age,
    required this.sex,
    required this.cholesterol,
    required this.bloodPressure,
    required this.heartRate,
    required this.diabetes,
    required this.familyHistory,
    required this.smoking,
    required this.obesity,
    required this.alcoholConsumption,
    required this.exerciseHours,
    required this.diet,
    required this.previousHeartProblems,
    required this.medicationUse,
    required this.stressLevel,
    required this.sedentaryHours,
    required this.income,
    required this.bmi,
    required this.triglycerides,
    required this.physicalActivityDays,
    required this.sleepHours,
  });

  // Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'sex': sex.toLowerCase(),
      'cholesterol': cholesterol,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'diabetes': diabetes ? 1 : 0,
      'family_history': familyHistory ? 1 : 0,
      'smoking': smoking ? 1 : 0,
      'obesity': obesity ? 1 : 0,
      'alcohol_consumption': alcoholConsumption.toLowerCase(),
      'exercise_hours': exerciseHours,
      'diet': diet.toLowerCase(),
      'previous_heart_problems': previousHeartProblems ? 1 : 0,
      'medication_use': medicationUse ? 1 : 0,
      'stress_level': stressLevel,
      'sedentary_hours': sedentaryHours,
      'income': income,
      'bmi': bmi,
      'triglycerides': triglycerides,
      'physical_activity_days': physicalActivityDays,
      'sleep_hours': sleepHours,
    };
  }
}
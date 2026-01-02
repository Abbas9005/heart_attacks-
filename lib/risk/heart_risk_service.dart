import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:heart_risk_/risk/heart_risk_model.dart';
import 'package:http/http.dart' as http;

class HeartRiskService {
  static const String _apiUrl = 'https://your-api-endpoint.com/predict';
  static const Duration _networkTimeout = Duration(seconds: 5);

  Future<double> predictRisk(HeartRiskData data) async {
    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data.toJson()),
          )
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final dynamic rawScore = decoded is Map<String, dynamic>
            ? decoded['risk_score']
            : (decoded is Map ? decoded['risk_score'] : null);

        if (rawScore is num) {
          final double probability = rawScore.toDouble().clamp(0.0, 1.0);
          return probability;
        }
        // If response doesn't contain a valid score, fallback
        return localPredictRisk(data);
      } else {
        // Non-200: fallback to local prediction
        return localPredictRisk(data);
      }
    } on TimeoutException {
      // Timeout: fallback to local prediction
      return localPredictRisk(data);
    } catch (_) {
      // Any other error: fallback to local prediction
      return localPredictRisk(data);
    }
  }

  // For demo purposes - local prediction using simplified logistic regression
  double localPredictRisk(HeartRiskData data) {
    // Simplified version based on the research paper's key factors
    // These weights would come from your trained model
    const double intercept = -4.5;
    const double ageWeight = 0.05;
    const double heartRateWeight = 0.02;
    const double bmiWeight = 0.03;
    const double cholesterolWeight = 0.01;
    const double smokingWeight = 0.8;
    final double sexWeight = data.sex.toLowerCase() == 'male' ? 0.5 : 0.0;

    // Calculate linear combination
    double score = intercept +
        (ageWeight * data.age) +
        (heartRateWeight * data.heartRate) +
        (bmiWeight * data.bmi) +
        (cholesterolWeight * data.cholesterol) +
        (smokingWeight * (data.smoking ? 1 : 0)) +
        sexWeight;

    // Convert to probability using logistic function
    final double probability = 1 / (1 + exp(-score));

    return probability.clamp(0.0, 1.0);
  }
}

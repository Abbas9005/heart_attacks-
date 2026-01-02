import 'package:flutter/material.dart';
import 'heart_risk_model.dart';
import 'heart_risk_service.dart';

class HeartRiskResults extends StatelessWidget {
  final HeartRiskData data;
  final HeartRiskService _service = HeartRiskService();

  HeartRiskResults({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double riskScore = _service.localPredictRisk(data);
    final int riskPercentage = (riskScore * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Heart Attack Risk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Your Heart Attack Risk Score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: riskScore,
                            strokeWidth: 15,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getRiskColor(riskScore),
                            ),
                          ),
                        ),
                        Text(
                          '$riskPercentage%',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: _getRiskColor(riskScore),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getRiskMessage(riskScore),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Key Risk Factors:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _buildRiskFactor('Age', data.age.toString()),
            _buildRiskFactor('Heart Rate', '${data.heartRate} bpm'),
            _buildRiskFactor('BMI', data.bmi.toStringAsFixed(1)),
            _buildRiskFactor('Cholesterol', '${data.cholesterol} mg/dL'),
            _buildRiskFactor('Smoking', data.smoking ? 'Yes' : 'No'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Show recommendations based on risk factors
                _showRecommendations(context, riskScore);
              },
              child: const Text('Get Personalized Recommendations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFactor(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.3) return Colors.green;
    if (risk < 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getRiskMessage(double risk) {
    if (risk < 0.2) return 'Low risk - Maintain your healthy lifestyle!';
    if (risk < 0.4) return 'Moderate risk - Consider some lifestyle improvements';
    if (risk < 0.6) return 'High risk - Consult with your doctor about prevention';
    return 'Very high risk - Immediate medical consultation recommended';
  }

  void _showRecommendations(BuildContext context, double riskScore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personalized Recommendations'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _getRecommendations(riskScore),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _getRecommendations(double riskScore) {
    final recommendations = <Widget>[];
    
    if (data.smoking) {
      recommendations.add(_recommendationItem('🚭 Quit smoking - This is the single most important change you can make'));
    }
    
    if (data.bmi > 25) {
      recommendations.add(_recommendationItem('🏋️ Lose weight - Aim for a BMI under 25 through diet and exercise'));
    }
    
    if (data.cholesterol > 200) {
      recommendations.add(_recommendationItem('🥗 Improve your diet - Reduce saturated fats and increase fiber intake'));
    }
    
    if (data.exerciseHours < 2.5) {
      recommendations.add(_recommendationItem('🏃 Increase exercise - Aim for at least 150 minutes of moderate activity per week'));
    }
    
    if (data.stressLevel > 6) {
      recommendations.add(_recommendationItem('🧘 Manage stress - Try meditation, yoga, or other relaxation techniques'));
    }
    
    if (riskScore > 0.4) {
      recommendations.add(_recommendationItem('👨‍⚕️ Regular check-ups - Schedule annual physical exams with your doctor'));
    }
    
    if (recommendations.isEmpty) {
      recommendations.add(const Text('Keep up the good work! Your current lifestyle appears heart-healthy.'));
    }
    
    return recommendations;
  }

  Widget _recommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
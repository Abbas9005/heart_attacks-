import 'package:flutter/material.dart';


class StateSelectionScreen extends StatefulWidget {
  final int heartRate;

  const StateSelectionScreen({super.key, required this.heartRate});

  @override
  _StateSelectionScreenState createState() => _StateSelectionScreenState();
}

class _StateSelectionScreenState extends State<StateSelectionScreen> {
  String selectedState = 'Exercising';

  Map<String, Map<String, dynamic>> stateInfo = {
    'At rest': {
      'icon': Icons.airline_seat_individual_suite,
      'min': 60,
      'max': 100,
      'color': Colors.green
    },
    'Sitting': {
      'icon': Icons.chair,
      'min': 60,
      'max': 100,
      'color': Colors.green
    },
    'Lying': {
      'icon': Icons.hotel,
      'min': 60,
      'max': 100,
      'color': Colors.green
    },
    'Exercising': {
      'icon': Icons.local_fire_department,
      'min': 119,
      'max': 157,
      'color': Colors.red
    },
    'Running': {
      'icon': Icons.directions_run,
      'min': 157,
      'max': 177,
      'color': Colors.blue
    },
  };


   Map<String, Map<String, dynamic>> statetwo = {
    'At rest': {
      'icon': Icons.airline_seat_individual_suite,
      'min': 60,
      'max': 100,
      'color': Colors.green
    },
    'Sitting': {
      'icon': Icons.chair,
      'min': 60,
      'max': 100,
      'color': Colors.green
    },
    'Lying': {
      'icon': Icons.hotel,
      'min': 60,
      'max': 100,
      'color': Colors.green
    },
 
  };

  String getHeartRateZone(int heartRate, String state) {
    int minRange = stateInfo[state]!['min'];
    int maxRange = stateInfo[state]!['max'];

    if (heartRate < minRange) {
      return 'Below Zone';
    } else if (heartRate > maxRange) {
      return 'Above Zone';
    } else {
      return state == 'Exercising' ? 'WARM-UP ZONE' : 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    String heartRateZone = getHeartRateZone(widget.heartRate, selectedState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading',
              style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dec 12, 09:37 PM',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.heartRate}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' bpm',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                    ),
                    const WidgetSpan(
                      child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Male',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '22 years old',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stateInfo[selectedState]!['color'],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  heartRateZone,
                  style: TextStyle(
                    color: stateInfo[selectedState]!['color'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
           SliderTheme(
  data: SliderTheme.of(context).copyWith(
    activeTrackColor: stateInfo[selectedState]!['color'],
    inactiveTrackColor: Colors.yellow,
    trackShape: const RoundedRectSliderTrackShape(),
    trackHeight: 4.0,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
  ),
  child: Slider(
    value: widget.heartRate.clamp(
      stateInfo[selectedState]!['min'] as int,
      stateInfo[selectedState]!['max'] as int,
    ).toDouble(),
    min: 60.0,
    max: 177.0,
    onChanged: null,
  ),
),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '60',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '119',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '157',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '177',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              
            ),
            const SizedBox(height: 20),
            const Text(
              'Present State',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: stateInfo.entries.map((entry) {
                  String state = entry.key;
                  bool isSelected = selectedState == state;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedState = state;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? entry.value['color']
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? entry.value['color']
                              : Colors.grey.shade600,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            entry.value['icon'],
                            color: isSelected ? Colors.white : Colors.white70,
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            state,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),


                // : statetwo.entries.map((entry) {
                //   String state = entry.key;
                //   bool isSelected = selectedState == state;
                //   return GestureDetector(
                //     onTap: () {
                //       setState(() {
                //         selectedState = state;
                //       });
                //     },
                //     child: Container(
                //       margin: const EdgeInsets.only(right: 10),
                //       padding: const EdgeInsets.all(10),
                //       decoration: BoxDecoration(
                //         color: isSelected
                //             ? entry.value['color']
                //             : Colors.grey.shade800,
                //         borderRadius: BorderRadius.circular(12),
                //         border: Border.all(
                //           color: isSelected
                //               ? entry.value['color']
                //               : Colors.grey.shade600,
                //         ),
                //       ),
                //       child: Column(
                //         children: [
                //           Icon(
                //             entry.value['icon'],
                //             color: isSelected ? Colors.white : Colors.white70,
                //             size: 30,
                //           ),
                //           const SizedBox(height: 5),
                //           Text(
                //             state,
                //             style: TextStyle(
                //               color: isSelected ? Colors.white : Colors.white70,
                //               fontSize: 14,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   );
                // }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

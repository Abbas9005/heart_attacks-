import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_risk_/ai/consultpage.dart';
import 'package:heart_risk_/sencer/heart_censer.dart';
import 'package:heart_risk_/helper.dart';
import 'risk/heart_risk_form.dart';

class ProfilePage extends StatefulWidget {
  final String? email;
  const ProfilePage({super.key, this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _age = 25;
  String _gender = 'Male';
  bool _familyHistory = false;
  File? _profileImage; // Store the selected image

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = widget.email ?? prefs.getString('current_user_email');
    if (email != null) {
      String? firstName = prefs.getString('user_${email}_firstName');
      String? lastName = prefs.getString('user_${email}_lastName');
      int? age = prefs.getInt('user_${email}_age');
      String? gender = prefs.getString('user_${email}_gender');
      bool? familyHistory = prefs.getBool('user_${email}_familyHistory');
      String? profileImagePath = prefs.getString('user_${email}_profileImage');

      if (firstName != null && lastName != null) {
        _nameController.text = '$firstName $lastName';
      }
      if (age != null) {
        _age = age;
      }
      if (gender != null) {
        _gender = gender;
      }
      if (familyHistory != null) {
        _familyHistory = familyHistory;
      }
      if (profileImagePath != null) {
        _profileImage = File(profileImagePath);
      }
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      String? email = widget.email ?? prefs.getString('current_user_email');

      if (email != null) {
        await prefs.setInt('user_${email}_age', _age);
        await prefs.setString('user_${email}_gender', _gender);
        await prefs.setBool('user_${email}_familyHistory', _familyHistory);
        if (_profileImage != null) {
          await prefs.setString('user_${email}_profileImage', _profileImage!.path);
        }
      }

      await PreferencesHelper.saveProfileData(
        name: _nameController.text,
        age: _age,
        gender: _gender,
        familyHistory: _familyHistory,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HeartRiskForm(
            profileName: _nameController.text,
            profileAge: _age,
            profileGender: _gender,
            profileFamilyHistory: _familyHistory,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          "User Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Picture Section
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text("Pick from Gallery"),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text("Take a Photo"),
                              onTap: () {
                                Navigator.pop(context);
                                _takePhoto();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage('assets/profile_placeholder.png')
                              as ImageProvider,
                      backgroundColor: Colors.grey[300],
                      child: _profileImage == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                        labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 16),
                  // Age Field
                  TextFormField(
                    initialValue: _age.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Age",
                        labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.cake, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      final age = int.tryParse(value);
                      if (age != null) _age = age;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: InputDecoration(
                      labelText: "Gender",
                        labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.wc, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((gender) => DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Family History Toggle
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: const Text("Family History of Heart Disease"),
                      // subtitle: const Text("Does your family have a history of heart disease?"),
                      activeThumbColor: Colors.red,
                      secondary: const Icon(Icons.family_restroom, color: Color(0xFF2E7D32)),
                      value: _familyHistory,
                      onChanged: (value) => setState(() => _familyHistory = value),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: Colors.red),
            label: 'Heart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart, color: Colors.red),
            label: 'Heart Rate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, color: Colors.blue),
            label: 'AI Doctor',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Already on Profile
          } else if (index == 1) {
            _submitProfile();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HeartRateScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorHomePage(),
              ),
            );
          }
        },
      ),
    );
  }
}

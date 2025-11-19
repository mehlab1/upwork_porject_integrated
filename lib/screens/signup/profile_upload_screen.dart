import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../otp/otp_verification_screen.dart';

class ProfileUploadScreen extends StatefulWidget {
  const ProfileUploadScreen({super.key, required this.email});

  final String email;

  @override
  State<ProfileUploadScreen> createState() => _ProfileUploadScreenState();
}

class _ProfileUploadScreenState extends State<ProfileUploadScreen> {
  static const Color _primaryBlue = Color(0xFF155DFC);
  static const Color _headingColor = Color(0xFF0F172B);
  static const Color _subheadingColor = Color(0xFF62748E);
  static const Color _textColor = Color(0xFF45556C);
  static const Color _lightTextColor = Color(0xFF90A1B9);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _handleFinish() {
    // Navigate to OTP verification screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(email: widget.email),
      ),
    );
  }

  void _handleSkip() {
    // Navigate to OTP verification screen without image
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(email: widget.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // Title and Subtitle
                Column(
                  children: [
                    Text(
                      'Add Profile Picture',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500, // Rubik Medium
                        color: _headingColor,
                        fontFamily: 'Rubik',
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a photo that represents you best',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal, // Rubik Regular
                        color: _subheadingColor,
                        fontFamily: 'Rubik',
                        letterSpacing: 0,
                        height: 1.43,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 94),

                // Profile Picture Container
                SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      // Profile Picture Circle
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Profile Picture Circle
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: _slate50,
                              shape: BoxShape.circle,
                              border: Border.all(color: _slate100, width: 4),
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: SvgPicture.asset(
                                      'assets/authPages/profile.svg',
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                          ),

                          // Camera Button
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x1A000000),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0x1A000000),
                                      blurRadius: 25,
                                      offset: const Offset(0, 0),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/authPages/camera.svg',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Instructions Text
                      Column(
                        children: [
                          Text(
                            'Tap camera to add photo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal, // Rubik Regular
                              color: _textColor,
                              fontFamily: 'Rubik',
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG or GIF • Max 5MB',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal, // Rubik Regular
                              color: _lightTextColor,
                              fontFamily: 'Rubik',
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Info Box
                      Container(
                        width: 400,
                        padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
                        decoration: BoxDecoration(
                          color: _slate50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _slate100, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upload Icon
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(21, 93, 252, 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/authPages/upload.svg',
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info Text
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Choose a clear photo where your face is visible. You can update this anytime in your account settings.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.normal, // Rubik Regular
                                    color: _textColor,
                                    fontFamily: 'Rubik',
                                    letterSpacing: 0,
                                    height: 1.625,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 92),

                // Buttons
                SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      // Finish & Proceed Button
                      SizedBox(
                        width: 400,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleFinish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Finish & Proceed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500, // Rubik Medium
                              color: Colors.white,
                              fontFamily: 'Rubik',
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // I'll Add It Later Button
                      SizedBox(
                        width: 400,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _handleSkip,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "I'll Add It Later",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500, // Rubik Medium
                              color: _textColor,
                              fontFamily: 'Rubik',
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

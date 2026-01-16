import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../otp/otp_verification_screen.dart';
import '../../services/profile_picture_service.dart';
import '../../widgets/pal_toast.dart';
import '../../core/responsive/responsive.dart';

class ProfileUploadScreen extends StatefulWidget {
  const ProfileUploadScreen({super.key, required this.email});

  final String email;

  @override
  State<ProfileUploadScreen> createState() => _ProfileUploadScreenState();
}

class _ProfileUploadScreenState extends State<ProfileUploadScreen> {
  static const Color _primaryBlue = Color(0xFF155DFC);
  static const Color _headingColor = Color(0xFF0F172B);
  static const Color _textColor = Color(0xFF45556C);
  static const Color _lightTextColor = Color(0xFF90A1B9);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _primary900 = Color(0xFF100B3C);

  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  bool _isUploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset uploading state when returning to this screen
    // This handles the case where user navigates back from OTP screen
    if (_isUploading && _selectedImageBytes != null) {
      // If we have an image and are in uploading state, reset it
      // This means upload likely completed but state wasn't reset
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Read the image bytes directly from XFile
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _selectedImageBytes = imageBytes;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        PalToast.show(
          context,
          message: 'Error picking image: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleFinish() async {
    // If no image selected, navigate directly
    if (_selectedImageFile == null || _selectedImageBytes == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: widget.email),
        ),
      );
      return;
    }

    // Upload profile picture if image is selected
    setState(() {
      _isUploading = true;
    });

    try {
      await _profilePictureService.uploadProfilePictureFromBytes(
        _selectedImageBytes!,
        _selectedImageFile!.name,
        mimeType: _selectedImageFile!.mimeType,
      );

      if (!mounted) return;

      // Reset uploading state before navigation
      setState(() {
        _isUploading = false;
      });

      // Navigate to OTP verification screen on success
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: widget.email),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      // Show error but still allow navigation
      PalToast.show(
        context,
        message:
            'Failed to upload profile picture: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );

      // Show dialog to continue anyway
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Upload Failed'),
            content: const Text(
              'Would you like to continue without uploading a profile picture?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OtpVerificationScreen(email: widget.email),
                    ),
                  );
                },
                child: const Text('Continue Anyway'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleSkip() {
    // Navigate to OTP verification screen without image
    Navigator.push(
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
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF100B3C),
                      size: 32,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Title - centered
                  const Expanded(
                    child: Text(
                      'Add Profile Picture',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172B),
                        fontFamily: 'Rubik',
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Spacer to balance the back button
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        'Upload a photo that represents you best',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500, // Rubik Regular
                          color: _lightTextColor,
                          fontFamily: 'Rubik',
                          letterSpacing: 0,
                          height: 1.43,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 120),

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
                                    border: Border.all(
                                      color: _slate100,
                                      width: 4,
                                    ),
                                  ),
                                  child: _selectedImageBytes != null
                                      ? ClipOval(
                                          child: Image.memory(
                                            _selectedImageBytes!,
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
                                    fontWeight:
                                        FontWeight.normal, // Rubik Regular
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
                                    fontWeight:
                                        FontWeight.normal, // Rubik Regular
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
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.scaledPadding(
                                  context,
                                  17,
                                ),
                                vertical: Responsive.scaledPadding(context, 17),
                              ),
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
                                    width: Responsive.scaledIcon(context, 32),
                                    height: Responsive.scaledIcon(context, 32),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        21,
                                        93,
                                        252,
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/authPages/upload.svg',
                                        width: Responsive.scaledIcon(
                                          context,
                                          16,
                                        ),
                                        height: Responsive.scaledIcon(
                                          context,
                                          16,
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: Responsive.scaledPadding(
                                      context,
                                      12,
                                    ),
                                  ),
                                  // Info Text
                                  Expanded(
                                    child: Text(
                                      'Choose a clear photo where your face is visible. You can update this anytime in your account settings.',
                                      style: TextStyle(
                                        fontSize: Responsive.scaledFont(
                                          context,
                                          12,
                                        ),
                                        fontWeight:
                                            FontWeight.normal, // Rubik Regular
                                        color: _textColor,
                                        fontFamily: 'Rubik',
                                        letterSpacing: 0,
                                        height: 1.625,
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
                                onPressed: _isUploading ? null : _handleFinish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w500, // Rubik Medium
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
                                onPressed: _isUploading ? null : _handleSkip,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
          ],
        ),
      ),
    );
  }
}

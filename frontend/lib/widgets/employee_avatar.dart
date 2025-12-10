import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EmployeeAvatar extends StatelessWidget {
  final String? employeeFileName;
  final String initials;
  final double size;
  final double fontSize;
  final Gradient? gradient;

  const EmployeeAvatar({
    Key? key,
    this.employeeFileName,
    required this.initials,
    this.size = 70.0,
    this.fontSize = 24.0,
    this.gradient,
  }) : super(key: key);

  String? _buildPhotoUrl() {
    if (employeeFileName == null || employeeFileName!.isEmpty) {
      return null;
    }

    // URL encode filename to handle spaces and special characters
    final encodedFileName = Uri.encodeComponent(employeeFileName!);
    return '${ApiConfig.baseUrl}/employees/photo/$encodedFileName';
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.secondaryGradientLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _buildPhotoUrl();

    // If no photo URL, show fallback immediately
    if (photoUrl == null) {
      return _buildFallbackAvatar();
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return FutureBuilder<String?>(
      future: authProvider.getToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;
        if (token == null || token.isEmpty) {
          return _buildFallbackAvatar();
        }

        return CachedNetworkImage(
          imageUrl: photoUrl,
          httpHeaders: {
            'Authorization': 'Bearer $token',
          },
          imageBuilder: (context, imageProvider) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover, // center-crop to avoid squashing
                alignment: const Alignment(0, -0.35), // keep more of the head visible
              ),
            ),
          ),
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: gradient ?? AppColors.secondaryGradientLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackAvatar(),
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 100),
        );
      },
    );
  }
}

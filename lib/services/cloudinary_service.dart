import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;
  final ImagePicker _picker = ImagePicker();
  
  CloudinaryService() {
    _cloudinary = CloudinaryPublic(
      AppConstants.cloudinaryCloudName,
      AppConstants.cloudinaryUploadPreset,
      cache: false,
    );
  }
  
  // Upload profile picture
  Future<String?> uploadProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConstants.profileImageSize.toDouble(),
        maxHeight: AppConstants.profileImageSize.toDouble(),
        imageQuality: 85,
      );
      
      if (image == null) return null;
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: 'vibzcheck/profiles',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('❌ Upload profile picture error: $e');
      return null;
    }
  }
  
  // Upload playlist cover
  Future<String?> uploadPlaylistCover() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConstants.playlistCoverSize.toDouble(),
        maxHeight: AppConstants.playlistCoverSize.toDouble(),
        imageQuality: 85,
      );
      
      if (image == null) return null;
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: 'vibzcheck/playlists',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('❌ Upload playlist cover error: $e');
      return null;
    }
  }
  
  // Upload from file path
  Future<String?> uploadImage(String filePath, {String folder = 'vibzcheck'}) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('❌ Upload image error: $e');
      return null;
    }
  }
  
  // Delete image
  Future<bool> deleteImage(String publicId) async {
    try {
      await _cloudinary.deleteFile(
        publicId: publicId,
        resourceType: CloudinaryResourceType.Image,
        invalidate: true,
      );
      return true;
    } catch (e) {
      print('❌ Delete image error: $e');
      return false;
    }
  }
}
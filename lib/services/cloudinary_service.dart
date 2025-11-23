import 'package:cloudinary_public/cloudinary_public.dart';
import '../utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;
  final ImagePicker _picker = ImagePicker();
  
  CloudinaryService() {
    // REQUIRED - Initialize Cloudinary with credentials
    final cloudName = AppConstants.cloudinaryCloudName;
    final uploadPreset = AppConstants.cloudinaryUploadPreset;
    
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary credentials not configured. '
        'Please set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env file.'
      );
    }
    
    try {
      _cloudinary = CloudinaryPublic(
        cloudName,
        uploadPreset,
        cache: false,
      );
      Logger.info('✅ Cloudinary initialized');
    } catch (e) {
      throw Exception('Failed to initialize Cloudinary: $e');
    }
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
      Logger.info('❌ Upload profile picture error: $e');
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
      Logger.info('❌ Upload playlist cover error: $e');
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
      Logger.info('❌ Upload image error: $e');
      return null;
    }
  }
  
  // Delete image
  // Note: CloudinaryPublic doesn't support deleteFile method
  // If deletion is needed, use cloudinary_sdk package or implement via HTTP API
  Future<bool> deleteImage(String publicId) async {
    // TODO: Implement deletion using cloudinary_sdk or HTTP API if needed
    Logger.warning('Delete image not implemented - CloudinaryPublic doesn\'t support deletion');
    return false;
  }
}
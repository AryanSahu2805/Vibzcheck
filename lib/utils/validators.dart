class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    
    if (value.length > 30) {
      return 'Name must be less than 30 characters';
    }
    
    return null;
  }

  // Share code validation
  static String? validateShareCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Share code is required';
    }
    
    if (value.length != 6) {
      return 'Share code must be 6 characters';
    }
    
    return null;
  }

  // Playlist name validation
  static String? validatePlaylistName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Playlist name is required';
    }
    
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    return null;
  }

  // Message validation
  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Message cannot be empty';
    }
    
    if (value.length > 500) {
      return 'Message must be less than 500 characters';
    }
    
    return null;
  }
}
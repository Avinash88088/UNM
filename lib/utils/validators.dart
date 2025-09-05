class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Required field validation
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }
  
  // Name validation
  static String? name(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Name'} is required';
    }
    
    if (value.length < 2) {
      return '${fieldName ?? 'Name'} must be at least 2 characters long';
    }
    
    if (value.length > 50) {
      return '${fieldName ?? 'Name'} must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+").hasMatch(value)) {
      return '${fieldName ?? 'Name'} can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number must be less than 15 digits';
    }
    
    return null;
  }
  
  // URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Please enter a valid URL';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
  
  // Number validation
  static String? number(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && number < min) {
      return 'Number must be at least $min';
    }
    
    if (max != null && number > max) {
      return 'Number must be at most $max';
    }
    
    return null;
  }
  
  // Integer validation
  static String? integer(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Integer is required';
    }
    
    final integer = int.tryParse(value);
    if (integer == null) {
      return 'Please enter a valid integer';
    }
    
    if (min != null && integer < min) {
      return 'Integer must be at least $min';
    }
    
    if (max != null && integer > max) {
      return 'Integer must be at most $max';
    }
    
    return null;
  }
  
  // Date validation
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      DateTime.parse(value);
    } catch (e) {
      return 'Please enter a valid date';
    }
    
    return null;
  }
  
  // File size validation (in bytes)
  static String? fileSize(int? fileSize, int maxSizeInBytes) {
    if (fileSize == null) {
      return 'File size is required';
    }
    
    if (fileSize > maxSizeInBytes) {
      final maxSizeMB = (maxSizeInBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'File size must be less than ${maxSizeMB}MB';
    }
    
    return null;
  }
  
  // File type validation
  static String? fileType(String? fileName, List<String> allowedTypes) {
    if (fileName == null || fileName.isEmpty) {
      return 'File name is required';
    }
    
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedTypes.contains(extension)) {
      final allowedTypesString = allowedTypes.join(', ').toUpperCase();
      return 'File type must be one of: $allowedTypesString';
    }
    
    return null;
  }
  
  // Credit card validation (Luhn algorithm)
  static String? creditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit card number is required';
    }
    
    // Remove spaces and dashes
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    if (!RegExp(r'^\d{13,19}$').hasMatch(cleanNumber)) {
      return 'Please enter a valid credit card number';
    }
    
    // Luhn algorithm
    int sum = 0;
    bool isEven = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    if (sum % 10 != 0) {
      return 'Please enter a valid credit card number';
    }
    
    return null;
  }
  
  // Custom validation function
  static String? custom(String? value, bool Function(String) validator, String errorMessage) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (!validator(value)) {
      return errorMessage;
    }
    
    return null;
  }
  
  // Combine multiple validators
  static String? combine(List<String? Function(String?)> validators, String? value) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

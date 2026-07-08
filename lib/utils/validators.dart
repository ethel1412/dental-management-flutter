class Validators {
  // Mobile number validation
  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (value.length < 10) {
      return 'Mobile number must be at least 10 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Mobile number must contain only digits';
    }
    return null;
  }

  // Email validation (optional)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional in most cases
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Email validation (required)
  static String? validateEmailRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
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

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '$fieldName must be a number';
    }
    return null;
  }

  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only digits';
    }
    return null;
  }

  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Age must be a number';
    }
    if (age < 1 || age > 150) {
      return 'Enter a valid age';
    }
    return null;
  }

  // Experience validation
  static String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'Experience is required';
    }
    final exp = int.tryParse(value);
    if (exp == null) {
      return 'Experience must be a number';
    }
    if (exp < 0 || exp > 60) {
      return 'Enter valid years of experience';
    }
    return null;
  }

  // Fee validation
  static String? validateFee(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fee is required';
    }
    final fee = double.tryParse(value);
    if (fee == null) {
      return 'Fee must be a number';
    }
    if (fee < 0) {
      return 'Fee cannot be negative';
    }
    return null;
  }
}

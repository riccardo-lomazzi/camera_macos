import 'dart:convert';

class CameraMacOSException implements Exception {
  String code;
  String message;
  Object? details;

  CameraMacOSException({
    this.code = "",
    this.message = "",
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      'details': details,
    };
  }

  factory CameraMacOSException.fromMap(Map<String, dynamic> map) {
    return CameraMacOSException(
      code: map['code'] ?? '',
      message: map['message'] ?? '',
      details: map['details'],
    );
  }

  String toJson() => json.encode(toMap());
}

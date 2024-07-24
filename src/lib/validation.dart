import 'package:email_validator/email_validator.dart';

class ValidationCheck {
  String? userNameLengthCheck(String value) {
    if (value.isEmpty) {
      return 'ユーザー名を入力してください。';
    }
    if (value.length < 2) {
      return 'ユーザー名は2文字以上でお願いします。';
    }
    if (20 < value.length) {
      return 'ユーザー名は20文字以下でお願いします。';
    }
    return null;
  }

  String? emailAddressCheck(String value) {
    if (value.isEmpty) {
      return 'メールアドレスを入力して下さい。';
    }
    if (!EmailValidator.validate(value)) {
      return '正しい形式で入力下さい。';
    }
    return null;
  }

  String? passwordCheck(String value) {
    if (value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < 6) {
      return '6文字以上でお願いします。';
    }
    if (30 < value.length) {
      return '30文字以下でお願いします。';
    }

    if (!RegExp(r'^[a-zA-Z0-9.!*+?/-]+$').hasMatch(value)) {
      return '英数字記号(.!*+?/-)でお願いします。';
    }
    return null;
  }

  bool siginInCheck(
      String userName, String mailAddress, String password, bool termsChecked) {
    if (userNameLengthCheck(userName) == null &&
        emailAddressCheck(mailAddress) == null &&
        passwordCheck(password) == null) {
      return true;
    }
    return false;
  }

  bool loginCheck(String mailAddress, String password) {
    if (emailAddressCheck(mailAddress) == null &&
        passwordCheck(password) == null) {
      return true;
    }
    return false;
  }
}

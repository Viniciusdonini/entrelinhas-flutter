import '../constants/app_strings.dart';

abstract final class Validators {
  static String? name(String? value) {
    final text = value?.trim() ?? '';
    return text.length < 2 || text.length > 100 ? AppStrings.nameInvalid : null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    return text.length > 254 ||
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
        ? AppStrings.emailInvalid
        : null;
  }

  static String? password(String? value) =>
      value == null || value.length < 8 || value.length > 128
      ? AppStrings.passwordInvalid
      : null;

  static String? passwordConfirmation(String? value, String password) =>
      value != password
      ? AppStrings.passwordsDifferent
      : Validators.password(value);

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.titleRequired;
    return text.length > 120 ? AppStrings.titleLength : null;
  }

  static String? author(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.authorRequired;
    return text.length > 100 ? AppStrings.authorLength : null;
  }

  static String? totalPages(String? value) {
    final pages = int.tryParse(value?.trim() ?? '');
    return pages == null || pages < 1 || pages > 20000
        ? AppStrings.pagesInvalid
        : null;
  }

  static String? currentPage(String? value, {required int totalPages}) {
    final page = int.tryParse(value?.trim() ?? '');
    return page == null || page < 0 || page > totalPages
        ? AppStrings.currentPageInvalid
        : null;
  }

  static String? genre(String? value) =>
      (value?.trim().length ?? 0) > 60 ? AppStrings.genreLength : null;

  static String? coverUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 2048) return AppStrings.coverUrlLength;

    const hostLabel = r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?';
    final pattern = RegExp(
      r'^[hH][tT][tT][pP][sS]://' +
          hostLabel +
          r'(?:\.' +
          hostLabel +
          r')*(?::[0-9]{1,5})?(?:[/?#][^\s\\]*)?$',
    );
    final uri = Uri.tryParse(text);
    return uri == null || !pattern.hasMatch(text)
        ? AppStrings.coverUrlInvalid
        : null;
  }

  static String? notes(String? value) =>
      (value?.trim().length ?? 0) > 2000 ? AppStrings.notesLength : null;
}

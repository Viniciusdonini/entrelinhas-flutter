import '../constants/app_strings.dart';

abstract final class Validators {
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
  static String? notes(String? value) =>
      (value?.trim().length ?? 0) > 2000 ? AppStrings.notesLength : null;
}

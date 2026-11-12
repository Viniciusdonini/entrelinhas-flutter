import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/service_messages.dart';
import '../core/utils/validators.dart';
import '../models/book.dart';
import '../models/book_status.dart';
import 'book_service.dart';
import 'service_exception.dart';

/// All remote reads and writes are confined to this layer.
class FirestoreBookService implements BookService {
  FirestoreBookService({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _books = firestore.collection('users').doc(userId).collection('books');

  static const _timeout = Duration(seconds: 15);

  final CollectionReference<Map<String, dynamic>> _books;

  @override
  Stream<List<Book>> watchBooks() async* {
    try {
      var receivedServerSnapshot = false;
      final snapshots = _books
          .orderBy('createdAt', descending: true)
          .snapshots(includeMetadataChanges: true)
          .timeout(
            _timeout,
            onTimeout: (sink) {
              if (!receivedServerSnapshot) {
                sink.addError(TimeoutException('Initial Firestore connection'));
                sink.close();
              }
            },
          );
      await for (final snapshot in snapshots) {
        if (!snapshot.metadata.isFromCache) receivedServerSnapshot = true;
        // An empty local cache does not prove that the remote library is empty.
        if (snapshot.metadata.isFromCache && snapshot.docs.isEmpty) continue;
        yield snapshot.docs.map(_decode).toList(growable: false);
      }
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<Book?> getBook(String id) async {
    _checkId(id);
    try {
      final document = await _books
          .doc(id)
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      return document.exists ? _decode(document) : null;
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<String> createBook(Book book) async {
    final data = _writeData(book);
    final document = _books.doc();
    try {
      await document
          .set({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_timeout);
      return document.id;
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<void> updateBook(Book book) async {
    _checkId(book.id);
    final data = _writeData(book)..remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    try {
      // update() deliberately preserves the original creation timestamp.
      await _books.doc(book.id).update(data).timeout(_timeout);
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<void> deleteBook(String id) async {
    _checkId(id);
    try {
      await _books.doc(id).delete().timeout(_timeout);
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  Book _decode(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = Map<String, dynamic>.from(document.data()!);
    for (final key in ['createdAt', 'updatedAt']) {
      final value = data[key];
      if (value is Timestamp) {
        data[key] = value.toDate().toUtc().toIso8601String();
      }
    }
    return Book.fromMap(id: document.id, data: data);
  }

  Map<String, dynamic> _writeData(Book book) {
    final normalized = book.copyWith(
      title: book.title.trim(),
      author: book.author.trim(),
      genre: book.genre.trim(),
      notes: book.notes.trim(),
      coverUrl: book.coverUrl.trim(),
    );
    if (normalized.title.isEmpty || normalized.title.length > 120) {
      throw const ServiceException(ServiceMessages.invalidTitle);
    }
    if (normalized.author.isEmpty || normalized.author.length > 100) {
      throw const ServiceException(ServiceMessages.invalidAuthor);
    }
    if (normalized.genre.length > 60 || normalized.notes.length > 2000) {
      throw const ServiceException(ServiceMessages.textTooLong);
    }
    final coverUrlError = Validators.coverUrl(normalized.coverUrl);
    if (coverUrlError != null) {
      throw ServiceException(coverUrlError);
    }
    if (normalized.totalPages < 1 || normalized.totalPages > 20000) {
      throw const ServiceException(ServiceMessages.invalidTotalPages);
    }
    if (normalized.currentPage < 0 ||
        normalized.currentPage > normalized.totalPages) {
      throw const ServiceException(ServiceMessages.invalidCurrentPage);
    }
    if ((normalized.status == BookStatus.wantToRead &&
            normalized.currentPage != 0) ||
        (normalized.status == BookStatus.finished &&
            normalized.currentPage != normalized.totalPages)) {
      throw const ServiceException(ServiceMessages.inconsistentProgress);
    }
    return normalized.toMap();
  }

  void _checkId(String id) {
    if (id.trim().isEmpty || id.contains('/')) {
      throw const ServiceException(ServiceMessages.invalidBookId);
    }
  }

  ServiceException _translate(Object error) {
    if (error is ServiceException) return error;
    if (error is TimeoutException) {
      return const ServiceException(ServiceMessages.requestTimeout);
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' || 'unauthenticated' => const ServiceException(
          ServiceMessages.permissionDenied,
        ),
        'unavailable' || 'network-request-failed' => const ServiceException(
          ServiceMessages.serverUnavailable,
        ),
        'not-found' => const ServiceException(ServiceMessages.bookNotFound),
        _ => const ServiceException(ServiceMessages.operationFailed),
      };
    }
    return const ServiceException(ServiceMessages.invalidBookData);
  }
}

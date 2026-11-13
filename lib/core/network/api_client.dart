import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/service_messages.dart';
import 'api_exception.dart';

/// HTTP mechanics only. This layer knows neither screens nor services.
class ApiClient {
  ApiClient({
    required Uri baseUri,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUri = Uri.parse(
         '${baseUri.toString().replaceFirst(RegExp(r'/+$'), '')}/',
       ),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;
  String? _token;
  void Function()? onUnauthorized;

  void setToken(String? token) => _token = token;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final token = authenticated ? _token : null;
    final request = http.Request(method, _baseUri.resolve(path))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);
    late http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ServiceMessages.requestTimeout);
    } on http.ClientException {
      throw const ApiException(ServiceMessages.serverUnavailable);
    } on Object {
      throw const ApiException(ServiceMessages.serverUnavailable);
    }

    if (response.statusCode == 204) return const {};
    Map<String, dynamic>? decoded;
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map<String, dynamic>) decoded = json;
    } on FormatException {
      // Non-JSON errors are replaced with a controlled message below.
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded == null) {
        throw const ApiException(ServiceMessages.invalidBookData);
      }
      return decoded;
    }
    if (response.statusCode == 401 &&
        authenticated &&
        token != null &&
        token == _token) {
      onUnauthorized?.call();
    }
    final fallback = switch (response.statusCode) {
      401 =>
        authenticated
            ? ServiceMessages.sessionExpired
            : ServiceMessages.invalidCredentials,
      403 => ServiceMessages.permissionDenied,
      404 => ServiceMessages.bookNotFound,
      422 => ServiceMessages.invalidInput,
      429 => ServiceMessages.tooManyAttempts,
      >= 500 => ServiceMessages.serverUnavailable,
      _ => ServiceMessages.operationFailed,
    };
    var message = fallback;
    if (response.statusCode == 422) {
      final errors = decoded?['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty && value.first is String) {
            message = value.first as String;
            break;
          }
        }
      }
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  void close() => _client.close();
}

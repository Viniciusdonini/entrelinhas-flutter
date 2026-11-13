import '../constants/service_messages.dart';
import 'api_exception.dart';

abstract final class ApiConfig {
  static Uri get baseUri {
    const configured = String.fromEnvironment('API_BASE_URL');
    final uri = Uri.tryParse(configured);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ApiException(ServiceMessages.invalidConfiguration);
    }
    return Uri.parse('${uri.toString().replaceFirst(RegExp(r'/+$'), '')}/');
  }
}

/// Messages shared by services, repositories and the HTTP transport.
abstract final class ServiceMessages {
  static const invalidTitle = 'Informe um título com até 120 caracteres.';
  static const invalidAuthor = 'Informe um autor com até 100 caracteres.';
  static const textTooLong = 'Confira os limites do gênero e das anotações.';
  static const invalidTotalPages =
      'O total de páginas deve estar entre 1 e 20.000.';
  static const invalidCurrentPage =
      'A página atual deve estar entre zero e o total de páginas.';
  static const inconsistentProgress =
      'Livros que você quer ler devem estar na página zero. Livros concluídos devem estar na última página.';
  static const invalidBookId = 'O identificador deste livro é inválido.';
  static const requestTimeout =
      'O servidor demorou para responder. Confira sua conexão e a biblioteca antes de tentar novamente.';
  static const permissionDenied =
      'Você não tem permissão para acessar esse registro.';
  static const serverUnavailable =
      'Não foi possível conectar à API. Confira a conexão e se o servidor Laravel está iniciado.';
  static const bookNotFound = 'Este livro não está mais na biblioteca.';
  static const operationFailed =
      'Não foi possível concluir a operação. Tente novamente.';
  static const invalidBookData =
      'A API retornou dados em um formato inesperado.';
  static const sessionExpired = 'Sua sessão terminou. Entre novamente.';
  static const invalidCredentials = 'E-mail ou senha incorretos.';
  static const tooManyAttempts =
      'Muitas tentativas. Aguarde um pouco e tente novamente.';
  static const invalidConfiguration =
      'Configure API_BASE_URL com o endereço da API Laravel, conforme o README.';
  static const invalidInput = 'Confira os campos informados e tente novamente.';
}

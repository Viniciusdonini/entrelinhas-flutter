/// Human-readable messages shared by data access and initialization.
abstract final class ServiceMessages {
  static const invalidTitle = 'Informe um título com até 120 caracteres.';
  static const invalidAuthor = 'Informe um autor com até 100 caracteres.';
  static const textTooLong =
      'Confira os limites de tamanho do gênero e das anotações.';
  static const invalidTotalPages =
      'O total de páginas deve estar entre 1 e 20.000.';
  static const invalidCurrentPage =
      'A página atual deve estar entre zero e o total de páginas.';
  static const inconsistentProgress =
      'Livros que você quer ler devem estar na página zero. Livros concluídos '
      'devem estar na última página.';
  static const invalidBookId = 'O identificador deste livro é inválido.';
  static const requestTimeout =
      'O servidor demorou para responder. Confira sua conexão e a biblioteca '
      'antes de tentar novamente.';
  static const permissionDenied =
      'Não foi possível acessar sua biblioteca. Confira a autenticação '
      'e as regras do Firestore.';
  static const serverUnavailable =
      'Não foi possível conectar ao servidor. Confira sua conexão '
      'e tente novamente.';
  static const bookNotFound = 'Este livro não está mais na biblioteca.';
  static const operationFailed =
      'Não foi possível concluir a operação. Tente novamente.';
  static const invalidBookData =
      'Não foi possível ler os dados deste livro. Confira os registros '
      'no Firestore e tente novamente.';
  static const sessionFailed =
      'Não foi possível iniciar sua sessão. Tente novamente.';
  static const initializationTimeout =
      'O Firebase demorou para responder. Confira a conexão ou se os '
      'emuladores estão iniciados e tente novamente.';
  static const anonymousProviderDisabled =
      'Ative o provedor Anônimo no Firebase Authentication para '
      'acessar a biblioteca.';
  static const firebaseUnavailable =
      'Não foi possível conectar ao Firebase. Confira a conexão '
      'ou os emuladores e tente novamente.';
  static const initializationFailed =
      'Não foi possível iniciar o Firebase. Confira a configuração '
      'local conforme as instruções do README.';
  static const configurationRequired =
      'Configure seu projeto Firebase com --dart-define-from-file ou '
      'inicie o modo de emuladores conforme o README.';
  static const emulatorProjectRequired =
      'Use um projeto com prefixo demo- no modo de emuladores.';
  static const invalidEmulatorHost =
      'Informe FIREBASE_EMULATOR_HOST apenas com o endereço do computador, '
      'sem http://, caminho ou porta.';
  static const platformConfigurationRequired =
      'Use a configuração do aplicativo Firebase correspondente à plataforma '
      'atual. No iOS, informe também FIREBASE_IOS_BUNDLE_ID.';
}

abstract final class AppStrings {
  static const appName = 'Entrelinhas';
  static const tagline = 'UM ESPAÇO PARA SUAS HISTÓRIAS';
  static const home = 'Início';
  static const homePageTitle = 'Seu próximo capítulo';
  static const library = 'Biblioteca';
  static const about = 'Sobre';
  static const homeTitle = 'Toda leitura é um novo começo.';
  static const homeSubtitle =
      'Organize sua estante e acompanhe as histórias que fazem parte de você.';
  static const yourLibrary = 'SUA BIBLIOTECA PESSOAL';
  static const addBook = 'Adicionar livro';
  static const seeLibrary = 'Ver biblioteca';
  static const totalBooks = 'Na estante';
  static const readingBooks = 'Em leitura';
  static const finishedBooks = 'Concluídos';
  static const currentlyReading = 'Entre uma página e outra';
  static const currentlyReadingSubtitle = 'Suas leituras em andamento.';
  static const recentBooks = 'Chegaram à sua estante';
  static const recentBooksSubtitle =
      'Os livros que você adicionou recentemente.';
  static const allBooks = 'Todos';
  static const libraryTitle = 'Minha biblioteca';
  static const librarySubtitle =
      'As histórias que você guarda. E as que ainda vai descobrir.';
  static const searchHint = 'Buscar por título ou autor';
  static const clearSearch = 'Limpar busca';
  static const emptyTitle = 'Sua próxima história começa aqui';
  static const emptyMessage =
      'Adicione seu primeiro livro e dê vida à sua biblioteca.';
  static const noResultsTitle = 'Nenhum livro por aqui';
  static const noResultsMessage =
      'Experimente outro termo ou altere o filtro de leitura.';
  static const clearFilters = 'Limpar filtros';
  static const loading = 'Buscando suas histórias…';
  static const errorTitle = 'Não foi possível carregar';
  static const errorMessage = 'Confira sua conexão e tente novamente.';
  static const retry = 'Tentar novamente';
  static const newBookTitle = 'Uma nova história';
  static const editBookTitle = 'Editar livro';
  static const formSubtitle = 'Guarde os detalhes da sua próxima leitura.';
  static const bookTitleLabel = 'Título *';
  static const bookTitleHint = 'Como se chama o livro?';
  static const authorLabel = 'Autor ou autora *';
  static const authorHint = 'Quem escreveu esta história?';
  static const genreLabel = 'Gênero';
  static const genreHint = 'Ex.: romance, tecnologia, biografia';
  static const coverUrlLabel = 'Link da capa (opcional)';
  static const coverUrlHint = 'https://exemplo.com/capa.jpg';
  static const coverUrlHelper =
      'Use o link direto de uma imagem. Deixe vazio para usar a capa decorativa.';
  static const coverPreviewTitle = 'Prévia da capa';
  static const coverPreviewBookTitle = 'Título do livro';
  static const coverPreviewAuthor = 'Autoria';
  static const totalPagesLabel = 'Total de páginas *';
  static const totalPagesHint = 'Ex.: 240';
  static const currentPageLabel = 'Página atual';
  static const statusLabel = 'Status de leitura';
  static const notesLabel = 'Suas anotações';
  static const notesHint = 'Uma ideia, uma impressão ou algo para lembrar…';
  static const saveBook = 'Salvar livro';
  static const savingBook = 'Salvando…';
  static const cancel = 'Cancelar';
  static const backToLibrary = 'Voltar à biblioteca';
  static const bookNotFoundTitle = 'Este livro não está na estante';
  static const bookNotFoundMessage =
      'Ele pode ter sido excluído. Volte à biblioteca para escolher outro.';
  static const loadBookError =
      'Não foi possível abrir este livro. Tente novamente.';
  static const saveBookError =
      'Não foi possível salvar. Confira sua conexão e tente novamente.';
  static const bookDetailsTitle = 'Na sua estante';
  static const detailsSubtitle = 'Cada livro tem um lugar na sua história.';
  static const editBook = 'Editar livro';
  static const deleteBook = 'Excluir livro';
  static const deletingBook = 'Excluindo…';
  static const deleteBookTitle = 'Excluir da biblioteca?';
  static String deleteBookMessage(String title) =>
      '“$title” e suas anotações serão excluídos. Esta ação não pode ser desfeita.';
  static const confirmDelete = 'Sim, excluir';
  static const deleteBookError = 'Não foi possível excluir. Tente novamente.';
  static const readingProgress = 'Progresso da leitura';
  static String pagesProgress(int current, int total) =>
      '$current de $total páginas';
  static String pagesTotal(int total) => '$total páginas';
  static String bookCount(int count) => count == 1
      ? '1 livro na sua biblioteca'
      : '$count livros na sua biblioteca';
  static String percent(int value) => '$value%';
  static const bookInformation = 'Sobre esta edição';
  static const author = 'Autoria';
  static const genre = 'Gênero';
  static const pages = 'Páginas';
  static const status = 'Leitura';
  static const addedOn = 'Adicionado em';
  static const lastUpdated = 'Última atualização';
  static const noGenre = 'Não informado';
  static const noNotes =
      'As páginas estão em branco. Edite o livro para guardar suas impressões.';
  static const notes = 'Entre suas anotações';
  static const readingProgressHint = 'Seu ritmo, uma página de cada vez.';
  static const aboutTitle = 'Um lugar para suas leituras';
  static const aboutSubtitle =
      'Menos livros esquecidos. Mais histórias vividas.';
  static const aboutDescription =
      'Entrelinhas é sua biblioteca pessoal: organize os livros que quer ler, acompanhe suas leituras e guarde as impressões de cada história.';
  static const aboutPrivacyTitle = 'Sua biblioteca, seu espaço';
  static const aboutPrivacyDescription =
      'Seus livros são vinculados a uma sessão anônima neste dispositivo. Não é preciso criar uma senha. Ao limpar os dados do app ou desinstalá-lo, você pode perder o acesso a essa biblioteca. A sincronização entre dispositivos não está disponível.';
  static const aboutVersion = 'Entrelinhas · versão 1.0.0';
  static const aboutFooter = 'Feito para quem encontra um mundo em cada livro.';
  static const setupTitle = 'Vamos abrir sua biblioteca';
  static const setupSubtitle =
      'A conexão com o serviço de dados ainda não está pronta.';
  static const setupMessage =
      'Configure o Firebase conforme o README ou inicie os emuladores locais. Depois, tente conectar novamente.';
  static const setupLoading = 'Preparando sua biblioteca…';
  static const routeNotFound = 'Não encontramos esta página';
  static const routeNotFoundMessage =
      'Volte ao início para continuar sua leitura.';
  static const goHome = 'Ir para o início';
  static const titleRequired = 'Informe o título do livro.';
  static const titleLength = 'Use no máximo 120 caracteres.';
  static const authorRequired = 'Informe o nome de quem escreveu.';
  static const authorLength = 'Use no máximo 100 caracteres.';
  static const pagesInvalid = 'Informe um número inteiro entre 1 e 20.000.';
  static const currentPageInvalid =
      'A página atual deve estar entre zero e o total de páginas.';
  static const genreLength = 'Use no máximo 60 caracteres.';
  static const notesLength = 'Use no máximo 2.000 caracteres.';
  static const coverUrlInvalid = 'Informe um link HTTPS válido para a imagem.';
  static const coverUrlLength = 'Use um link com no máximo 2.048 caracteres.';
}

# Entrelinhas

Biblioteca pessoal em Flutter para organizar livros, acompanhar leituras e guardar anotações. O cadastro, a consulta, a edição e a exclusão usam o Firebase Firestore por meio de uma camada de serviços.

**Aluno:** Vinicius Donini Santos Machado

**Back-end escolhido:** opção B — Firebase Firestore

**Repositório:** [Viniciusdonini/entrelinhas-flutter](https://github.com/Viniciusdonini/entrelinhas-flutter)

**Prazo no Moodle:** 15/11/2026, às 23h59, horário de Brasília.

## Funcionalidades

- CRUD de livros com título, autoria, gênero, páginas, status, anotações e capa opcional por link HTTPS.
- Prévia da capa no formulário e capa decorativa quando não há link ou a imagem não pode ser carregada.
- Início com totais e leituras derivados dos registros do Firestore.
- Biblioteca com busca por título/autoria e filtros por status.
- Progresso de leitura: quero ler, em leitura ou concluído.
- Formulário validado, confirmação de exclusão e ações bloqueadas durante o envio.
- Estados de carregamento, falha com nova tentativa, lista vazia e livro inexistente.
- Tema próprio e interface que se adapta à largura disponível.
- Autenticação anônima e regras que separam a biblioteca de cada usuário.

Os livros são registros do back-end. O aplicativo não inclui uma lista fixa nem preenche o banco automaticamente. Cada livro pode usar uma imagem de capa por link ou a composição decorativa gerada a partir do título.

## Capas por link

No cadastro ou na edição, preencha **Link da capa (opcional)** com o endereço HTTPS direto de uma imagem. A prévia acompanha o título, a autoria e o link informados. O endereço deve ter até 2.048 caracteres, um host válido e não conter credenciais nem espaços internos. O formulário só tenta carregar a imagem quando o link passa pela validação.

Para trocar a capa, substitua o link e salve. Para removê-la, limpe o campo e salve: o livro volta a usar a capa decorativa. Um link com formato válido pode apontar para uma imagem indisponível; nesse caso, o componente também mostra a capa decorativa, preservando os dados do livro.

O Firestore armazena apenas a string `coverUrl`; a imagem é carregada pelo componente compartilhado `BookCover`, sem upload ou dependência do Firebase Storage. Registros antigos sem `coverUrl` continuam funcionando, pois o model considera o campo ausente como uma string vazia. Ao atualizar um projeto Firebase existente, publique novamente o arquivo `firestore.rules` desta versão antes de salvar os novos campos.

## Telas e rotas

São cinco telas principais. O mesmo formulário atende duas rotas, para cadastro e edição.

| Tela | Função | Nome da rota | Caminho |
| --- | --- | --- | --- |
| Início | Resumo da biblioteca e leituras recentes | `AppRoutes.home` / `home` | `/` |
| Biblioteca | Listagem, busca e filtros | `AppRoutes.books` / `books` | `/biblioteca` |
| Formulário | Cadastrar um livro | `AppRoutes.bookCreate` / `book-create` | `/biblioteca/novo` |
| Formulário | Editar um livro existente | `AppRoutes.bookEdit` / `book-edit` | `/biblioteca/:id/editar` |
| Detalhes | Consultar dados, editar e excluir | `AppRoutes.bookDetails` / `book-details` | `/biblioteca/:id` |
| Sobre | Apresentação e funcionamento da sessão anônima | `AppRoutes.about` / `about` | `/sobre` |

Há também uma tela de inicialização para carregamento e falha de configuração. As transições entre telas usam `context.goNamed(...)`. Edição e detalhes recebem o ID pelo caminho e consultam o service; não dependem de um objeto passado apenas em memória. Na web, a configuração padrão do Flutter utiliza URLs com `#`, por exemplo `/#/biblioteca/ID_DO_LIVRO`.

## Arquitetura

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/    # textos, rótulos e mensagens dos serviços
│   ├── routes/       # nomes e configuração do go_router
│   ├── theme/        # cores, espaçamentos e ThemeData
│   └── utils/        # validação e formatação
├── models/           # Book e BookStatus, sem Flutter/Firebase
├── services/         # contrato BookService, Firestore e inicialização
├── screens/
│   ├── home/
│   ├── books/
│   ├── about/
│   └── startup/
└── widgets/          # componentes compartilhados
```

`main.dart` prepara o Flutter e inicia a aplicação. `app.dart` reúne o tema, a inicialização e as telas. As telas recebem um `BookService`; somente `FirestoreBookService` lê e escreve os livros no Firestore.

O roteador fica em `core/routes/` e recebe funções construtoras de páginas, os *builders*, fornecidas por `app.dart`. Assim, `core/` configura as rotas sem importar `screens/` ou `services/`.

`Book.fromMap` e `Book.toMap` convertem os dados. O model representa datas de maneira compatível com JSON; o service transforma os timestamps do Firestore e utiliza o relógio do servidor nas gravações. A edição preserva `createdAt`.

Referência de organização utilizada na disciplina: [Guia Financeiro](https://github.com/matheushsouto/app-financas-flutter). O tema, os dados e as funcionalidades deste aplicativo são de biblioteca pessoal.

A tipografia utiliza a fonte **Lora**, obtida do [repositório Google Fonts](https://github.com/google/fonts/tree/main/ofl/lora). O arquivo está em `assets/fonts/Lora-Variable.ttf`; a licença SIL Open Font License 1.1 acompanha o projeto em [assets/fonts/OFL.txt](assets/fonts/OFL.txt).

## Ambiente e dependências

Ambiente de referência: **Flutter 3.47.1** e **Dart 3.13.1**. Para executar no Android, instale o Android SDK e disponibilize um dispositivo ou emulador. Para iOS, é necessário macOS com Xcode. A execução web usa Chrome.

| Dependência | Versão registrada no `pubspec.lock` | Uso |
| --- | --- | --- |
| `go_router` | 17.5.0 | Rotas nomeadas |
| `firebase_core` | 4.15.0 | Inicialização do Firebase |
| `firebase_auth` | 6.7.0 | Sessão anônima |
| `cloud_firestore` | 6.10.0 | Persistência e streams |
| `flutter_lints` | 6.0.0 | Análise de código |

`flutter_localizations`, `flutter_test`, `flutter_driver` e `integration_test` acompanham o SDK. Mantenha o `pubspec.lock` no repositório para reproduzir as versões utilizadas.

Na pasta que contém este README e o `pubspec.yaml`, execute:

```shell
flutter --version
flutter doctor
flutter pub get
```

## Executar com Firebase na nuvem

Este é o modo para conectar o trabalho ao seu projeto Firebase real.

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
2. Crie o banco Cloud Firestore padrão, em modo nativo, e habilite **Authentication → Sign-in method → Anonymous**.
3. Cadastre um aplicativo Firebase da plataforma que será executada. O identificador Android e o bundle iOS deste projeto são `br.edu.entrelinhas.entrelinhas`.
4. Copie `config/firebase.example.json` para um arquivo local e substitua todos os exemplos pelas opções do aplicativo cadastrado. No PowerShell:

   ```powershell
   Copy-Item config/firebase.example.json config/firebase.local.json
   ```

5. Instale a Firebase CLI, entre na sua conta e publique as regras deste projeto:

   ```shell
   npm install -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules --project SEU_PROJECT_ID
   ```

6. Execute o aplicativo usando o arquivo correspondente à plataforma:

   ```shell
   flutter run -d chrome --dart-define-from-file=config/firebase.local.json
   ```

| Opção do arquivo JSON | Conteúdo |
| --- | --- |
| `USE_FIREBASE_EMULATOR` | `false` para a nuvem |
| `FIREBASE_API_KEY` | `apiKey` do aplicativo Firebase |
| `FIREBASE_APP_ID` | `appId` do aplicativo da plataforma atual |
| `FIREBASE_MESSAGING_SENDER_ID` | `messagingSenderId` do projeto |
| `FIREBASE_PROJECT_ID` | `projectId` |
| `FIREBASE_AUTH_DOMAIN` | `authDomain`, quando informado na configuração web |
| `FIREBASE_STORAGE_BUCKET` | `storageBucket`, quando informado |
| `FIREBASE_IOS_BUNDLE_ID` | Bundle cadastrado no Firebase para iOS |

O `FIREBASE_APP_ID` de um aplicativo web contém `:web:`; o de Android contém `:android:`; o de iOS contém `:ios:`. Para Android e iOS, use arquivos separados, como `config/firebase.android.local.json` e `config/firebase.ios.local.json`, com as opções das respectivas plataformas. No iOS, preencha também `FIREBASE_IOS_BUNDLE_ID`.

Para selecionar um dispositivo Android disponível:

```shell
flutter devices
flutter run -d ID_DO_DISPOSITIVO --dart-define-from-file=config/firebase.android.local.json
```

O projeto inicializa o Firebase por `FirebaseOptions`, com dados fornecidos durante a compilação. Não é necessário adicionar ao repositório um `firebase_options.dart` gerado. Arquivos `config/*.local.json`, `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`, `.env` e chaves de assinatura estão no `.gitignore`.

## Executar com emuladores locais

O Firebase Emulator Suite permite desenvolver e verificar o CRUD sem criar um projeto na nuvem. Os dados continuam passando pelos SDKs e por um servidor Firestore local. Esse ambiente é separado do projeto real usado na entrega.

Instale **Node.js 22 ou superior**, **Java 21 ou superior** e a Firebase CLI. Confira a instalação:

```shell
node --version
java -version
npm install -g firebase-tools
firebase --version
```

Em um terminal na pasta do projeto, mantenha os emuladores executando:

```shell
firebase emulators:start --only auth,firestore --project demo-entrelinhas
```

Em outro terminal:

```shell
flutter run -d chrome --dart-define-from-file=config/emulator.json
```

O arquivo `config/emulator.json` contém somente identificadores fictícios. Não fixa `FIREBASE_EMULATOR_HOST` nem um `APP_ID` exclusivo de web: o bootstrap escolhe as opções adequadas à plataforma. O endereço padrão é `127.0.0.1` no Chrome/desktop e `10.0.2.2` no emulador Android. As portas são 9099 para Auth e 8080 para Firestore. A interface de inspeção fica em [localhost:4000](http://localhost:4000/).

Na versão web com emuladores, abra o aplicativo por `http://localhost:PORTA`. A versão atual de `firebase_auth_web` restaura a conexão ao Auth Emulator após recarregar somente quando o hostname da página é `localhost`; usar `127.0.0.1` na barra do navegador pode causar erro de chave de API fictícia. Isso se refere ao endereço da página; o host de conexão aos emuladores pode continuar sendo `127.0.0.1`.

No Android Emulator, use o mesmo comando com o ID do dispositivo no lugar de `chrome`. Em um celular físico, configure `FIREBASE_EMULATOR_HOST` com o IP local do computador, sem protocolo ou porta, em um arquivo `*.local.json`. Nesse caso, os emuladores precisam aceitar conexões da rede local; ajuste o `host` em `firebase.json` conforme o ambiente.

O cache persistente do Firestore fica desabilitado no modo emulador. Sem opções de importação/exportação, o banco local é limpo ao encerrar os emuladores. Para preservar dados de desenvolvimento entre sessões:

```shell
firebase emulators:start --only auth,firestore --project demo-entrelinhas --import=emulator-data --export-on-exit=emulator-data
```

Na primeira utilização, execute sem `--import` se a pasta ainda não existir. O diretório `emulator-data/` está ignorado pelo Git.

## Sessão e regras de acesso

O acesso anônimo cria uma identidade sem exigir senha. Cada biblioteca está em `users/{uid}/books/{bookId}`. As regras permitem operações somente ao usuário dono e validam campos, limites e timestamps.

A sessão fica vinculada aos dados locais do aplicativo ou ao perfil do navegador. Limpar esses dados ou desinstalar o aplicativo pode retirar o acesso à biblioteca anterior. Não há recuperação de conta ou sincronização da mesma identidade entre dispositivos nesta versão.

Se a conexão inicial falhar, o aplicativo apresenta uma mensagem e permite tentar novamente. Escritas e consultas individuais têm limite de espera de 15 segundos. Após um timeout de gravação, confira a biblioteca antes de repetir: uma operação enviada pode ser confirmada posteriormente pelo servidor.

## Verificação

```shell
dart format .
flutter analyze
flutter test
```

Os testes locais cobrem conversão do model, validações, dependências entre camadas e o fluxo da interface com um service controlado. O teste de integração utiliza o service real com os emuladores e verifica criação, leitura, atualização, stream e exclusão.

Para verificar o CRUD e as regras por requisições REST, mantenha os emuladores iniciados e execute com Node.js 22 ou superior:

```shell
node tools/test_emulator_rules.mjs
```

O script verifica persistência, preservação de timestamps, rejeição de dados inválidos e bloqueio de acesso sem autenticação ou por outro usuário. Ele cria registros de teste no emulador e remove o documento ao terminar.

Para a integração web, mantenha Auth e Firestore Emulator executando. Disponibilize um ChromeDriver compatível com a versão do Chrome e inicie-o em outro terminal:

```shell
chromedriver --port=4444
```

Depois execute:

```shell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/firestore_crud_test.dart -d web-server --headless --browser-name=chrome --browser-dimension=430x1100 --dart-define-from-file=config/emulator.json --no-web-resources-cdn
```

**Resultados da verificação de 12/11/2026:**

- `flutter analyze`: sem problemas encontrados.
- `dart format .`: 36 arquivos conferidos, sem alterações necessárias.
- `flutter test`: **33 testes aprovados** — 6 de model, 5 de arquitetura, 17 de validadores e 5 de widgets. O fluxo mobile, os estados de carregamento/erro e os casos adicionados para capas estão cobertos.
- `node tools/test_emulator_rules.mjs`: aprovado contra Auth e Firestore Emulator, com CRUD persistido, capa opcional, registros antigos, rejeição de dados inválidos e isolamento por usuário.
- Prévia manual no Flutter web: uma imagem do OpenLibrary foi carregada no formulário em `localhost:8642`. O livro permaneceu como rascunho, sem ser salvo nessa conferência.
- Integração Flutter/Chrome: o cenário de CRUD parou por timeout em `FirebaseBootstrap.initialize()`, antes de criar um livro. A captura das cinco telas foi concluída em 12/11/2026. Essa rodada não aprova a integração completa; o timeout anterior ao cadastro não comprova uma falha do CRUD. Consulte o [registro de verificação](docs/verificacao.md).
- O acesso ao projeto Firebase na nuvem depende da configuração local do aluno; os resultados de emulador não constituem uma verificação da nuvem.

## Prints

As cinco imagens abaixo foram atualizadas em **12/11/2026**. O cenário em `integration_test/` cadastra três livros no Firestore Emulator por meio do service real, captura as telas e limpa os registros ao terminar. A captura usa capas decorativas, sem depender de imagens externas. Esses exemplos ficam restritos ao teste; a aplicação não insere dados fixos.

| Início | Biblioteca |
| --- | --- |
| ![Início](docs/screenshots/inicio.png) | ![Biblioteca](docs/screenshots/biblioteca.png) |

| Formulário | Detalhes |
| --- | --- |
| ![Formulário](docs/screenshots/formulario.png) | ![Detalhes](docs/screenshots/detalhes.png) |

![Sobre](docs/screenshots/sobre.png)

## Estudo, vídeo e entrega

Leia o [guia de estudo](docs/guia_de_estudo.md) para revisar os fluxos e praticar a explicação do código. O [roteiro de vídeo](docs/roteiro_video.md) propõe uma demonstração de dois a quatro minutos. A rubrica menciona vídeo; confirme com o professor o formato de envio.

Antes de entregar:

- Revise o código e pratique sua explicação com o guia de estudo.
- Configure e demonstre o CRUD no projeto Firebase da entrega.
- Confira os prints e grave a demonstração.
- Confira se o repositório contém a versão revisada do projeto, preservando o `pubspec.lock` e o `.gitignore`.
- Libere o acesso ao professor, caso o repositório seja privado.
- Envie o link pelo Moodle até **15/11/2026, às 23h59**.

O desenvolvimento contou com apoio de IA. Cabe ao aluno revisar, adaptar e compreender a solução, incluindo os limites da autenticação anônima e a configuração do back-end.

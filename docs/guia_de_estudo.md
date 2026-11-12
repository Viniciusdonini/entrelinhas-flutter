# Guia de estudo — Entrelinhas

**Aluno:** Vinicius Donini Santos Machado

**Tema:** biblioteca pessoal

**Back-end:** opção B — Firebase Firestore

Este guia acompanha o código. Use-o para localizar as responsabilidades e depois explique os fluxos com suas próprias palavras. Execute as alterações em um ambiente de desenvolvimento e observe o resultado no Firestore.

## 1. Qual problema o aplicativo resolve?

O usuário registra os livros que quer ler, acompanha a página atual e guarda anotações. A entidade principal é `Book`. O CRUD permite criar um livro, consultar a biblioteca e os detalhes, atualizar dados/progresso e excluir um registro.

Título, autoria e total de páginas são obrigatórios. Gênero, notas e link da capa são opcionais. Os estados são `wantToRead`, `reading` e `finished`. O formulário mantém página zero para livros que o usuário quer ler e a última página para livros concluídos.

Os livros exibidos vêm do Firestore. Busca, filtros e contadores são calculados a partir desses registros. Uma capa pode vir de um link HTTPS informado no livro. Quando o link está vazio ou a imagem falha, o aplicativo exibe sua composição decorativa baseada no título.

## 2. Por que separar em camadas?

Cada camada responde por uma parte do trabalho. Essa separação permite alterar a persistência ou testar regras sem misturar consultas remotas com o desenho das telas.

| Local | Responsabilidade | O que observar |
| --- | --- | --- |
| `main.dart` | Preparar o Flutter e iniciar o app | `WidgetsFlutterBinding.ensureInitialized` e o future de inicialização |
| `app.dart` | Reunir dependências, tema, localização e roteador | O widget `App` entrega a mesma instância de `BookService` às telas |
| `core/constants/` | Textos, rótulos e mensagens de erro | `AppStrings`, `BookLabels` e `ServiceMessages` |
| `core/theme/` | Aparência compartilhada | `AppColors`, `AppSpacing` e `AppTheme` |
| `core/utils/` | Validação e formatação | `Validators` e `Formatters` |
| `core/routes/` | Nomes, caminhos e configuração das rotas | `AppRoutes` e `createAppRouter` |
| `models/` | Representar os dados | `Book` e `BookStatus`, sem imports de Flutter/Firebase |
| `services/` | Inicializar o acesso e conversar com o back-end | Contrato `BookService` e implementação `FirestoreBookService` |
| `screens/` | Interação e apresentação de cada área | Eventos chamam métodos do service |
| `widgets/` | Interface reutilizável | Estrutura de página, estados assíncronos, cards, capas e status |

As dependências seguem este fluxo:

```text
main → app → screens → BookService → FirestoreBookService → Firestore
        │       │                          │
        │       └→ widgets → core           └→ models
        └→ core/routes + core/theme
```

O service não devolve telas ou widgets. Ele devolve models, streams ou resultados de operações. As telas não importam o SDK do Firestore.

O tema carrega a fonte Lora do arquivo `assets/fonts/Lora-Variable.ttf`. A fonte vem do [Google Fonts](https://github.com/google/fonts/tree/main/ofl/lora), com a licença incluída em `assets/fonts/OFL.txt`.

## 3. Como o roteador fica em core sem conhecer as telas?

`createAppRouter` recebe funções que constroem as páginas. `app.dart` fornece essas funções, por exemplo uma função que cria `HomeScreen(service: service)`.

Com isso, `core/routes/` declara os nomes e caminhos sem importar `screens/` nem `services/`. Essa é uma forma simples de injeção de dependências: quem monta a aplicação entrega os objetos e funções de que outra parte precisa.

Para abrir um livro, a tela usa:

```dart
context.goNamed(
  AppRoutes.bookDetails,
  pathParameters: {'id': book.id},
);
```

O ID faz parte da URL. A página consegue buscar o registro ao ser aberta diretamente ou recarregada, sem depender de um `Book` que tenha sido passado apenas em memória. Uma rota com ID inexistente mostra um estado próprio.

Fechar o diálogo de confirmação com `Navigator.pop` apenas devolve uma resposta à tela que abriu o diálogo. As mudanças entre as telas do aplicativo usam rotas nomeadas.

## 4. O que é o model?

`Book` é uma classe imutável: seus campos são `final`. Ela contém ID, título, autoria, total de páginas, gênero, página atual, status, notas, `coverUrl` e datas de criação/alteração.

- `fromMap` constrói um `Book` a partir dos dados recebidos.
- `toMap` cria um mapa com valores compatíveis com JSON.
- `copyWith` cria outra instância, preservando os campos que não foram alterados.
- O ID é recebido separadamente, pois no Firestore ele identifica o documento e não precisa ser repetido dentro dele.
- `coverUrl` tem valor padrão vazio. `fromMap` também usa esse padrão quando lê documentos antigos sem o campo; `copyWith(coverUrl: '')` permite remover uma capa sem alterar os demais dados.

O model não usa `Timestamp`, que pertence ao Firebase. O service converte esse tipo para uma data que o model consegue interpretar. Na saída JSON, as datas são representadas por strings ISO 8601. Isso mantém a entidade independente do SDK.

Experimento: rode o teste de serialização e acompanhe um livro sendo convertido para JSON e restaurado. Verifique que ID, status, páginas e datas mantêm o significado.

## 5. Como acontece a inicialização?

`FirebaseBootstrap.initialize()` lê as opções fornecidas por `--dart-define-from-file`, inicializa o Firebase e prepara Auth/Firestore. O código obtém a sessão anônima existente ou inicia outra. Depois cria um `FirestoreBookService` com o UID desse usuário.

`app.dart` acompanha esse `Future<BookService>` com `FutureBuilder`. Enquanto espera, mostra a inicialização. Se há falha, mostra uma mensagem e uma ação de nova tentativa. Quando o service está pronto, cria o roteador.

Os dados de configuração da nuvem ficam em arquivos locais ignorados pelo Git. O arquivo de emuladores utiliza um projeto fictício com prefixo `demo-`. O APP_ID real precisa corresponder à plataforma atual.

## 6. Como funciona o CRUD?

### Criar

1. O formulário valida os campos com `Validators`.
2. A tela constrói um `Book` e chama `await service.createBook(book)`.
3. O service normaliza os textos, valida os limites e gera uma referência com ID.
4. O Firestore recebe os campos e os timestamps gerados pelo servidor.
5. As regras verificam o usuário e os dados.
6. Depois da confirmação, o service devolve o ID e a tela abre os detalhes por rota nomeada.

### Listar

`watchBooks()` observa os documentos da biblioteca do usuário, ordenados por criação. A cada snapshot, converte os documentos para `List<Book>`.

Início e biblioteca usam `StreamBuilder`. Os streams são guardados no estado da tela para evitar criar uma nova assinatura em cada reconstrução. A interface mostra carregamento, erro ou os dados recebidos. Uma lista sem registros produz o estado vazio.

A busca por título/autoria e os filtros são aplicados no aplicativo aos livros carregados. Esta versão não implementa paginação nem busca textual no servidor.

### Consultar detalhes ou carregar a edição

`getBook(id)` devolve um `Future<Book?>`. Um `null` indica que o documento não existe. Uma exceção representa uma falha de acesso, configuração, conexão ou dados.

Os detalhes usam `FutureBuilder`. O formulário de edição carrega os dados de forma assíncrona e preenche os controladores. As verificações de estado impedem aplicar resultados depois que a tela foi descartada ou quando outra carga já a substituiu.

### Editar

O formulário envia o ID e os novos campos a `updateBook`. O service usa `update`, atualiza o timestamp de modificação e omite `createdAt`, preservando a criação. Após concluir, a tela abre novamente os detalhes pelo ID.

O mesmo fluxo salva a capa opcional em `coverUrl`. Alterar o link troca a imagem; salvar o campo vazio remove a capa remota. Não é necessário regravar manualmente todos os livros antigos: a leitura aceita a ausência desse campo e uma edição posterior grava o valor correspondente.

### Excluir

A tela pede confirmação. Se o usuário confirmar, espera `deleteBook(id)` e retorna à biblioteca. Durante a operação, bloqueia ações que poderiam repetir o envio. Uma falha mantém a mensagem disponível para o usuário.

## 7. O que async/await, Future e Stream resolvem?

Uma consulta remota leva tempo. `Future<T>` representa um resultado que chegará depois; `await` espera esse resultado sem transformar a operação de rede em uma chamada síncrona que bloqueia a interface. `try/catch` trata falhas.

`Stream<List<Book>>` representa vários resultados ao longo do tempo. É apropriado para uma listagem que deve reagir às alterações do Firestore. `StreamBuilder` acompanha os eventos e reconstrói o conteúdo relevante.

Depois de um `await`, a tela pode já ter sido fechada. Por isso o código confere `mounted` antes de executar alterações de estado ou navegar. A edição também distingue cargas antigas de uma solicitação mais recente.

As operações têm limites de espera. Um timeout informa que o cliente deixou de esperar; não garante cancelamento de uma escrita já enviada. Por isso a mensagem orienta consultar a biblioteca antes de repetir.

## 8. Qual é o papel dos validadores e das regras?

Os validadores ajudam o usuário a corrigir o formulário. As regras do Firestore protegem os dados mesmo quando a chamada não vem desse formulário.

| Campo/regra | Limite |
| --- | --- |
| Título | Obrigatório, até 120 caracteres, sem espaços nas pontas |
| Autoria | Obrigatória, até 100 caracteres, sem espaços nas pontas |
| Gênero | Até 60 caracteres |
| Link da capa | Opcional; HTTPS, até 2.048 caracteres, host válido, sem credenciais ou espaços internos |
| Total de páginas | Inteiro de 1 a 20.000 |
| Página atual | Inteiro de zero ao total de páginas |
| Quero ler | Página atual igual a zero |
| Concluído | Página atual igual ao total |
| Notas | Até 2.000 caracteres |
| Datas | Timestamps; criação preservada e alteração gerada pelo servidor |
| Proprietário | `request.auth.uid` igual ao UID da biblioteca no caminho |

As regras permitem somente as chaves previstas. Nas criações, os timestamps precisam corresponder ao instante da requisição; na edição, a criação não pode mudar. O service usa `FieldValue.serverTimestamp()` para atender a essas condições.

O acesso anônimo oferece um UID verificável. Ele não implementa recuperação de conta. Limpar os dados locais pode impedir que o usuário volte à biblioteca anterior; essa limitação aparece na tela Sobre e no README.

### Como funciona a prévia da capa?

O formulário acompanha os controladores de título, autoria e URL para montar um `Book` provisório. A prévia reutiliza `BookCover`, o mesmo componente da biblioteca e dos detalhes. Um endereço inválido não inicia o carregamento da imagem. Os listeners são removidos quando a tela é descartada.

`BookCover` verifica o link e usa `Image.network` com recorte proporcional, indicação discreta de carregamento e tratamento de erro. Enquanto não há imagem disponível, ou quando ela falha, utiliza a capa decorativa. No web, `WebHtmlElementStrategy.fallback` permite que o Flutter tente um elemento de imagem da plataforma quando a busca normal é bloqueada por CORS.

O documento do Firestore guarda o endereço, não os bytes da imagem. A imagem permanece no servidor apontado pelo link; não há upload nem integração com Firebase Storage. Validar o formato da URL não garante que ela devolverá uma imagem, por isso o tratamento de falha continua necessário. As regras atualizadas aceitam documentos antigos sem `coverUrl` e validam o campo quando ele está presente.

## 9. Como verificar o trabalho?

```shell
dart format .
flutter analyze
flutter test
```

Em 12/11/2026, foram aprovados 33 testes locais: 6 de model, 5 de arquitetura, 17 de validadores e 5 de widgets. Os testes de model verificam conversão, cópia e compatibilidade do campo de capa. Os de validação exercitam campos obrigatórios, limites e links HTTPS. Os de arquitetura verificam imports/exports proibidos entre camadas e convenções dos widgets. Os de interface exercitam o CRUD mobile, estados de carregamento/erro e os casos de capa com um service controlado; essa simulação isola a interface e não substitui o teste do back-end.

O script abaixo também foi aprovado contra os emuladores reais de Auth/Firestore:

```shell
node tools/test_emulator_rules.mjs
```

Com Node.js 22 ou superior e os emuladores iniciados, ele envia requisições REST, verifica CRUD persistido, timestamps, capa opcional, documentos antigos, validação e isolamento por usuário, e remove seu registro de teste. A rodada de 12/11/2026 foi aprovada. Consulte os resultados consolidados no README.

O teste de integração depende dos emuladores: usa o `FirestoreBookService` real, cria um livro, lê os dados, altera o registro, recebe a atualização pela stream e exclui o documento. Consulte o README para o comando web com ChromeDriver.

O cenário de captura cadastra três exemplos no emulador pelo service e os remove ao terminar. Eles são dados de teste persistidos no servidor local; não são uma lista fixa carregada pela aplicação.

Na rodada de 12/11/2026, a captura das cinco telas foi concluída, sem depender de imagens externas. O cenário de CRUD no Chrome parou por timeout na inicialização do Firebase, antes do cadastro; isso não comprova uma falha do CRUD nem permite declarar a integração completa aprovada. Os testes de widgets e o script REST continuam aprovados. Confira os detalhes no registro de verificação.

A prévia de uma capa do OpenLibrary também foi conferida manualmente no formulário web; o livro permaneceu como rascunho, sem ser salvo nessa conferência.

Além dos testes, execute o CRUD manualmente, recarregue o aplicativo para conferir persistência e inspecione o documento no Firestore. Distinga os resultados obtidos no emulador daqueles obtidos no seu projeto na nuvem.

## 10. Perguntas para praticar com o código aberto

1. Onde você alteraria a quantidade máxima de caracteres do título? Quais camadas precisam manter esse limite coerente?
2. Por que `Book` não importa `cloud_firestore`?
3. Qual é a diferença entre `BookService` e `FirestoreBookService`?
4. Como `app.dart` entrega o service às telas? Como entrega os builders ao roteador?
5. Qual consulta alimenta os totais da página inicial?
6. Por que a biblioteca usa uma stream e os detalhes usam um future?
7. O que acontece se o registro for excluído antes de abrir seus detalhes?
8. Por que verificar `mounted` após esperar uma chamada?
9. Como a atualização mantém a data original de criação?
10. O que impede um usuário de acessar `users/UID_DE_OUTRA_PESSOA/books/...`?
11. Por que validar no formulário e também no servidor?
12. O que significa um timeout de escrita? Ele cancela a operação no servidor?
13. Como as rotas com IDs permitem abrir um livro por link?
14. O que seria necessário para recuperar a mesma biblioteca em outro dispositivo?
15. Quais verificações foram realizadas no emulador e quais foram realizadas na nuvem?
16. Onde `coverUrl` é validado, armazenado e transformado em uma imagem? Por que essas responsabilidades estão separadas?
17. O que acontece ao abrir um livro antigo sem `coverUrl`, remover o link de uma capa ou carregar uma imagem indisponível?

Para cada resposta, localize o arquivo, a chamada e o estado de interface correspondente. Evite decorar uma definição sem conseguir seguir o fluxo real.

## 11. Uso de IA e autoria responsável

O enunciado permite IA como apoio e exige compreensão do código. O projeto foi desenvolvido com esse apoio. Revise os arquivos, execute as verificações, faça adaptações que compreenda e registre os resultados reais.

Seja transparente ao explicar as decisões e os limites da solução. Antes da apresentação, pratique uma pequena mudança, como acrescentar um campo ao livro: identifique o que mudaria no model, formulário, service, regras e testes. Isso ajuda a demonstrar que você entende a integração completa.

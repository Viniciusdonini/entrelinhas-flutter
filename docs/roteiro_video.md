# Roteiro de demonstração — Entrelinhas

**Aluno:** Vinicius Donini Santos Machado

**Duração sugerida:** de dois a quatro minutos

**Tema:** biblioteca pessoal com Flutter e Firebase Firestore, opção B.

A rubrica de avaliação menciona vídeo, embora a seção de entregáveis não detalhe o formato. Confirme com o professor como enviar o arquivo ou o link. Este roteiro organiza uma demonstração curta do trabalho.

## Preparação

- Configure o projeto Firebase da entrega e habilite a sessão anônima.
- Disponibilize o aplicativo e o Firestore Console em janelas que possam ser alternadas.
- Use livros e anotações próprios para a demonstração. Os dados devem ser cadastrados no back-end.
- Separe um link HTTPS direto para uma imagem de capa e confira sua disponibilidade antes da gravação.
- Confira os comandos de qualidade e seus resultados antes de gravar.
- Evite mostrar arquivos locais de configuração, tokens ou credenciais.
- Deixe o repositório e os arquivos principais acessíveis para explicar a arquitetura.

Se a gravação utilizar os emuladores, informe isso durante a apresentação e mostre a interface local do Firestore. Não apresente o emulador como um projeto em produção.

## Sequência sugerida

| Tempo | Ação na tela | Explicação sugerida |
| --- | --- | --- |
| 0:00–0:20 | Mostrar o início e abrir a biblioteca | Apresentar nome, tema, opção B e resumo do CRUD. Os totais vêm dos livros cadastrados. |
| 0:20–0:45 | Abrir cadastro e tentar salvar sem os campos obrigatórios | Mostrar que título, autoria e páginas são validados em `core/utils/validators.dart`. |
| 0:45–1:15 | Cadastrar um livro, preencher o link HTTPS opcional e observar a prévia antes de salvar | Explicar que a capa acompanha o título e a autoria. O service grava os dados e `coverUrl` no Firestore; a tela abre os detalhes com o ID retornado. |
| 1:15–1:40 | Mostrar o documento no Firestore e recarregar o app | Confirmar persistência fora da memória da tela. Mostrar os campos e o caminho da biblioteca do usuário. |
| 1:40–2:05 | Editar status para “Em leitura”, informar uma página e limpar ou trocar o link da capa | Mostrar a alteração nos detalhes e no documento. Campo vazio restaura a capa decorativa; `createdAt` é preservado. |
| 2:05–2:25 | Buscar o livro e aplicar o filtro de status | Demonstrar a listagem com registros reais e a navegação entre início, biblioteca, formulário, detalhes e Sobre. |
| 2:25–2:45 | Excluir o livro com confirmação | Confirmar que o documento desaparece do Firestore e a biblioteca reflete a exclusão. Se estiver vazia, mostrar esse estado. |
| 2:45–3:10 | Mostrar uma falha controlada e a nova tentativa | Em ambiente de desenvolvimento, interromper o acesso ao serviço e repetir uma consulta. Explicar o erro apresentado; depois restabelecer o serviço. |
| 3:10–3:45 | Abrir rapidamente a estrutura de `lib/` e os resultados dos checks | Mostrar model puro, service, tela, core e builders injetados em `app.dart`. Informar os resultados realmente obtidos. |

Para uma versão de aproximadamente dois minutos, reduza a exploração visual e mostre apenas os trechos centrais de cada fluxo. Preserve a demonstração de criar, listar, editar, excluir e persistir os dados.

## Como demonstrar erro sem depender de uma gravação longa

A sessão anônima e o Firestore podem manter dados em cache na nuvem. Desligar a internet nem sempre produz uma falha imediata na listagem. Prepare a demonstração antes de gravar.

Uma opção controlada é iniciar o app em modo de emuladores com o serviço parado: a inicialização apresenta o erro de conexão após o limite de espera. Em seguida, inicie os emuladores e use “Tentar novamente”. Avise que esse trecho usa o ambiente local de desenvolvimento.

Também mostre a validação com total de páginas zero ou, no status “Em leitura”, uma página atual maior que o total. Isso demonstra erro de entrada; explique separadamente a falha de conexão.

Para explicar a capa, mostre que um link sem HTTPS é recusado e que limpar o campo restaura a composição decorativa. Uma imagem indisponível também usa essa composição, sem impedir a consulta ao livro. O Firestore guarda somente `coverUrl`; a imagem é carregada do endereço informado. Livros antigos sem esse campo continuam abrindo normalmente.

## Resultados que já podem ser apresentados

Em 12/11/2026, os 33 testes locais foram aprovados: 6 de model, 5 de arquitetura, 17 de validadores e 5 de widgets. O script `node tools/test_emulator_rules.mjs` também foi aprovado contra Auth/Firestore Emulator, verificando CRUD persistido, capa opcional, registros antigos, rejeições e isolamento por usuário. A análise de código não encontrou problemas e os 36 arquivos Dart conferidos já estavam formatados.

A captura das cinco telas foi concluída em 12/11/2026. O cenário de CRUD no Chrome parou por timeout na inicialização, antes de criar um livro; a integração completa desta rodada não está aprovada. Esse resultado não comprova um defeito no CRUD. Antes de gravar, confira o README e execute a demonstração no seu projeto Firebase. Diferencie a simulação da interface, os testes com emuladores e o acesso à nuvem.

A prévia com uma imagem do OpenLibrary foi conferida manualmente em um rascunho não salvo; a gravação ainda deve demonstrar o cadastro e a alteração dos dados.

## Pontos para falar com suas próprias palavras

- “As telas recebem um `BookService`; não fazem consultas diretas ao Firestore.”
- “O model converte mapas e não depende de Flutter ou Firebase.”
- “O roteador recebe os builders de `app.dart`, por isso core não precisa importar as telas.”
- “A biblioteca acompanha uma stream; gravações e consultas individuais usam async/await.”
- “As regras validam o proprietário e os campos mesmo se alguém tentar gravar fora do formulário.”
- “A capa é opcional: o Firestore armazena o link e o componente compartilhado carrega a imagem. Sem link ou em caso de falha, usamos a capa decorativa.”
- “A autenticação é anônima e vinculada à sessão deste dispositivo; ainda não há recuperação ou acesso à mesma identidade em outro dispositivo.”

Não é necessário ler essas frases literalmente. Mostre no código o trecho que sustenta cada explicação.

## Conferência final

- O vídeo mostra as cinco telas e o CRUD completo.
- A recarga e o documento no Firestore comprovam persistência.
- Há exemplo de validação, estado vazio e tratamento de falha.
- A prévia e a edição ou remoção do link da capa foram demonstradas.
- Os resultados informados correspondem aos checks executados.
- O nome, o repositório e a opção de back-end estão no README.
- A explicação reconhece o apoio de IA e demonstra entendimento da solução.

**Link do vídeo, se solicitado:** [PREENCHER LINK DO VÍDEO]

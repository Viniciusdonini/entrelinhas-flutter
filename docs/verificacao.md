# Registro de verificação

Verificações locais e REST atualizadas em **12/11/2026**, com Flutter 3.47.1, Dart 3.13.1 e os emuladores Firebase Authentication e Firestore, no projeto fictício `demo-entrelinhas`. A rodada web concluiu a captura das cinco telas, mas o cenário separado de CRUD parou na inicialização. A execução anterior, em 09/11/2026, aprovou dois testes com Chrome/ChromeDriver 157.0.8103.38 e não substitui a validação das alterações atuais.

| Verificação | Resultado |
| --- | --- |
| `dart format .` | 36 arquivos conferidos, sem alterações necessárias |
| `flutter analyze` | Nenhum problema encontrado |
| `flutter test` | 33 testes aprovados |
| Script REST de CRUD e regras | Aprovado, incluindo capa opcional, registros antigos, rejeições e isolamento |
| Integração Flutter no Chrome | Cenário de CRUD interrompido por timeout na inicialização, antes do cadastro |
| Prints | Cinco PNGs atualizados em 12/11/2026, sem imagens externas de capa |
| Prévia manual da capa | Imagem do OpenLibrary carregada no formulário; rascunho não salvo |

Os 33 testes locais abrangem 6 testes do model, 5 de arquitetura, 17 de validadores e 5 de widgets. Os testes cobrem também o campo `coverUrl`, os limites do link HTTPS e a compatibilidade com livros antigos. Os testes de widgets executam o fluxo de cadastro, edição e exclusão em uma janela de 390 × 844, além de carregamento, erro com nova tentativa, preservação do formulário após falha e os casos de capa. Apenas esses testes de interface usam um service controlado em memória.

O cenário de integração de CRUD usa `FirebaseBootstrap` e `FirestoreBookService` reais e foi preparado para criar, reler, alterar, acompanhar a stream e excluir um livro. Nas duas tentativas de 12/11/2026, ele parou por timeout em `FirebaseBootstrap.initialize()`, antes de iniciar a criação. A inicialização do ambiente de teste ainda está sendo investigada; esse resultado não comprova um defeito no CRUD e não permite aprovar a integração completa desta rodada.

O cenário separado de captura concluiu o cadastro de três registros apenas no emulador, a abertura das cinco telas, a gravação dos PNGs e a limpeza dos registros. Ele utilizou capas decorativas, sem links externos de imagem. Os testes de widgets e as verificações REST do CRUD e das regras foram aprovados separadamente.

O script `tools/test_emulator_rules.mjs` verifica também a recusa de dados inválidos, de acesso sem autenticação e de acesso por outro usuário. A rodada REST de 12/11/2026 aprovou o uso opcional de `coverUrl`, a compatibilidade com documentos que não possuem esse campo e as rejeições de links inválidos. Os comandos reproduzíveis estão no README. Na execução automatizada anterior no Windows, foi usado um perfil temporário do Chrome em caminho curto para evitar travamento do IndexedDB em diretórios temporários longos.

As imagens estão em `docs/screenshots/`. O aviso vermelho no rodapé é inserido pelo SDK de autenticação para identificar o uso do emulador; ele não aparece na conexão ao Firebase da nuvem.

## Capa por link e publicação

A funcionalidade de capa permite preencher um link HTTPS opcional, visualizar a imagem no formulário, trocar o endereço ou removê-lo salvando o campo vazio. `BookCover` apresenta uma composição decorativa sem link ou quando o carregamento falha. O Firestore guarda apenas `coverUrl`; o model aceita documentos antigos sem o campo, sem exigir migração em lote.

A prévia foi conferida manualmente no Flutter web em `http://localhost:8642`: uma imagem do OpenLibrary apareceu no formulário. O cadastro permaneceu como rascunho e não foi salvo nessa conferência.

O código, os testes, o README, os prints e os guias estão disponíveis no repositório [Viniciusdonini/entrelinhas-flutter](https://github.com/Viniciusdonini/entrelinhas-flutter). Os resultados registrados descrevem as verificações efetivamente realizadas, com as limitações indicadas acima.

## O que depende da configuração de entrega

- Criar ou selecionar o projeto Firebase, preencher o arquivo local da plataforma, habilitar autenticação anônima e publicar as regras.
- Executar o CRUD contra esse projeto na nuvem. Os testes em emulador não comprovam uma conexão à nuvem já configurada.
- Compilar e testar em um dispositivo Android ou iOS. As pastas de plataforma foram geradas, mas esta verificação não incluiu APK, dispositivo físico nem build iOS.
- Gravar o vídeo e enviar o link do repositório pelo Moodle.

A configuração e o CRUD de um projeto Firebase na nuvem, os builds mobile e o envio ao Moodle não foram validados nesta execução. Os resultados acima descrevem os testes locais e os emuladores.

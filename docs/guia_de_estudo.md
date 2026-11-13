# Guia de estudo — Entrelinhas integrado

**Aluno:** Vinicius Donini Santos Machado

**Tema:** biblioteca pessoal. **Back-end:** opção A — API Laravel.

Use este guia com o código aberto. Identifique uma chamada real de cada camada e explique com suas próprias palavras.

## O problema e os recursos

O usuário organiza seus livros, acompanha o progresso e guarda notas. Os quatro recursos da API são livros, autores, gêneros e estantes. Login e cadastro são funções de autenticação e não substituem um desses quatro recursos.

Um livro contém título, autor, gênero, total de páginas, página atual, estado de leitura, notas, capa opcional e uma estante opcional. O servidor vincula as informações ao usuário autenticado.

## Responsabilidade de cada camada

| Camada | Responsabilidade | Exemplo para explicar |
| --- | --- | --- |
| Flutter Model | Dados e conversão de Map/JSON | `Book`, estado de leitura e datas |
| Flutter Screen | Interação e apresentação | Validar o formulário, aguardar e mostrar erros |
| Flutter Service | Coordenar regras e operações | `LibraryBookService` depende do contrato do repository |
| Flutter Repository | Encapsular persistência remota | `ApiBookRepository` converte dados da API |
| Flutter ApiClient | HTTP e cabeçalhos da sessão | Token Bearer e tratamento de respostas |
| Flutter Core | Tema, textos, rotas e utilitários | Validadores e nomes das rotas |
| Laravel Controller | Receber a chamada e devolver a resposta | Delegar a operação ao service |
| Laravel Form Request | Validar entrada e autorização | Campos, limites e relações permitidas |
| Laravel Service | Aplicar regras de negócio | Compatibilidade entre estado e página atual |
| Laravel Repository | Concentrar consultas e persistência | Consultar registros do proprietário |
| Laravel Model | Representar tabelas e relações | Livro, autor, gênero, estante e usuário |

O fluxo de uma criação é:

```text
Formulário → Service Flutter → Repository Flutter → HTTP
→ rota Laravel → Request/Controller → Service Laravel
→ Repository Laravel → Eloquent/banco → JSON → tela
```

Repository e Service têm responsabilidades diferentes. A consulta ao banco ou ao endpoint fica no Repository; a decisão de negócio fica no Service. Não basta criar pastas vazias ou classes que nunca são utilizadas.

## O que mudou no back-end?

A versão integrada consome Laravel por `http`, pois o trabalho também é avaliado em Programação Orientada a Objetos para Web. Os resultados da versão Firestore são históricos e não comprovam esta integração.

No Laravel, migrations descrevem a estrutura do banco; models representam os dados e seus relacionamentos; factories geram dados de desenvolvimento/teste; seeders coordenam sua inserção. A biblioteca do app continua vindo do servidor, e não de uma lista fixa nas telas.

O `DatabaseSeeder` utiliza o seeder da biblioteca. A conta de demonstração usa `DEMO_NAME`, `DEMO_EMAIL` e `DEMO_PASSWORD` do `.env` local. Sem uma senha de demonstração preenchida, o seeder não cria essa conta. A senha não deve estar no repositório.

## Login e restrição de acesso

O usuário informa e-mail e senha. A API valida as credenciais e retorna um token Sanctum. Esse token é enviado nos próximos pedidos como Bearer; não é uma senha e não deve ser chamado de JWT sem que a implementação utilize JWT.

O Flutter guarda a sessão em memória. Recarregar o app solicita login novamente; isso não apaga os livros, pois os dados estão no banco e são associados à conta. Logout encerra o token da sessão.

As consultas precisam considerar o proprietário do recurso. Um ID válido de outro usuário não autoriza sua leitura ou alteração. Também é preciso validar se uma estante referenciada pertence à mesma conta. O cliente não deve escolher o proprietário por um campo `user_id`.

O arquivo `rest.http` permite demonstrar chamadas autenticadas e o bloqueio sem autenticação. Os testes de segurança devem verificar o isolamento entre dois usuários.

## Criar, listar, editar e excluir

1. O formulário verifica os campos e monta os dados do livro.
2. O service chama o repository, que envia a requisição.
3. A API valida, aplica suas regras e persiste no banco.
4. A resposta contém os dados do registro, incluindo ID e datas.
5. A tela abre os detalhes por uma rota nomeada.
6. Ao editar ou excluir, a biblioteca é atualizada a partir da API.

Autores e gêneros podem ser resolvidos pelo nome recebido no cadastro do livro. Os endpoints próprios de autores, gêneros e estantes também oferecem CRUD completo.

Para excluir um catálogo usado por um livro, observe a resposta de conflito e a regra implementada. No roteiro do `rest.http`, o livro criado pelo teste é excluído antes dos catálogos para não deixar referências pendentes.

## Regras de leitura e capa

| Regra | Comportamento |
| --- | --- |
| Total de páginas | Inteiro entre 1 e 20.000 |
| Página atual | Entre zero e o total |
| Quero ler | Página atual igual a zero |
| Concluído | Página atual igual ao total |
| Em leitura na última página | O service pode normalizar para concluído |
| Título/autoria | Obrigatórios, com limites validados |
| Capa | Link HTTPS opcional, até 2.048 caracteres, sem credenciais |
| Criação | Preservada durante edição |

A capa não é armazenada como arquivo no banco. `coverUrl` aponta para uma imagem remota; `BookCover` concentra a renderização e o fallback decorativo. Um endereço sintaticamente válido pode falhar ao carregar, por isso a interface também trata esse caso.

## Assincronismo e estados

Uma requisição HTTP não termina imediatamente: a interface aguarda um Future e apresenta carregamento. Falha, ausência de resultados e registro inexistente são situações diferentes.

Os dados da listagem são recarregados após operações e pela ação de atualizar. HTTP não oferece automaticamente o mesmo push de um listener do Firestore. Observe no código como o service/repository publica o resultado da nova consulta para a tela.

Após `await`, telas que alteram seu estado precisam conferir se continuam montadas. Um timeout informa que a resposta não chegou no limite esperado; ele não prova que o servidor deixou de gravar. Consulte os dados antes de repetir uma criação.

## Reuso e dependências

Identifique onde aparecem `BookCover`, `BookCard`, `BookCollection`, `AsyncStateView` e `AppScaffold`. Os componentes compartilhados ficam em `widgets/`; textos, cores, espaçamentos e validações ficam em `core/`.

Model não importa Flutter. Screens não importam HTTP diretamente. Services e Repositories não montam widgets. Core não importa Screens ou Services. As rotas têm nomes centralizados e são chamadas com `goNamed`.

## Como verificar

Na API, execute migrations/seeders em uma base local e rode `php artisan test`. Os testes precisam cobrir autenticação, os quatro recursos, validação, associação entre usuários e regras de negócio. `rest.http` é uma demonstração executável, não substitui testes automatizados.

No Flutter, execute `dart format .`, `flutter analyze` e `flutter test`. Depois faça o login e o CRUD contra a API real. Consulte o [registro de verificação](verificacao.md); só informe como aprovado o que realmente foi executado nesta versão.

## Perguntas para praticar

1. Qual diferença prática existe entre Service e Repository neste projeto?
2. Que arquivo executa HTTP? Que arquivo consulta Eloquent?
3. Como o usuário autenticado limita as consultas?
4. O que acontece ao enviar uma estante de outro usuário?
5. Onde a API valida uma entrada enviada fora do Flutter?
6. Como as migrations e os relacionamentos impedem referências inválidas?
7. Por que as factories e os seeders não são uma lista fixa da tela?
8. Como o token chega a `Authorization`? O que acontece após logout?
9. Por que reiniciar o app exige login e não apaga a biblioteca?
10. Como o formulário mantém a data original de criação?
11. Que teste comprova o bloqueio de outro usuário?
12. Como acrescentar um campo ao livro sem misturar responsabilidades?
13. Por que um erro de carregamento não deve aparecer como lista vazia?
14. Quais recursos da API podem ser demonstrados pelo `rest.http`?
15. Quais verificações foram executadas e quais continuam pendentes?

Faça uma alteração pequena, execute seus testes e acompanhe uma operação de ponta a ponta antes da apresentação. Revise o código e pratique a explicação com suas próprias palavras.

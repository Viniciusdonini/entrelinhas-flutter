# Apresentação presencial — Entrelinhas

**Aluno:** Vinicius Donini Santos Machado

**Duração:** cinco minutos. **Ordem:** tema verbal → sistema → código.

Não são necessários slides ou vídeo. A apresentação envolve Mobile, Paradigmas e Programação Orientada a Objetos para Web.

## Preparação

- Inicie a API e confira `GET /api/health`.
- Prepare a conta de demonstração pelo `.env` local e pelo seeder.
- Abra o Flutter, o `rest.http` e os arquivos de código que serão explicados.
- Execute a sequência completa antes da aula, incluindo login e a limpeza dos dados de teste.
- Deixe os resultados reais dos testes disponíveis. Evite abrir arquivos com senhas ou tokens durante a explicação.
- Use um livro de demonstração cadastrado pela API; não acrescente dados fixos nas telas.

## Sequência de cinco minutos

| Tempo | O que mostrar | O que explicar |
| --- | --- | --- |
| 0:00–0:20 | Tema, verbalmente | “Entrelinhas é uma biblioteca pessoal para organizar livros e acompanhar leituras. Flutter consome uma API Laravel.” |
| 0:20–0:40 | Login no app | A mesma conta identifica a biblioteca. As rotas da API exigem autenticação Sanctum. |
| 0:40–1:35 | Criar livro, abrir detalhes e editar progresso | Os dados vão ao servidor; validação, capa opcional e regra de páginas são tratadas pelas camadas. |
| 1:35–2:00 | Voltar à listagem, atualizar e excluir | Mostrar o CRUD e o estado vazio ou os outros registros; exclusão pede confirmação. |
| 2:00–2:40 | `rest.http` | Mostrar os quatro recursos e executar exemplos autenticados. Apontar os blocos de criação, consulta, edição e exclusão e a chamada sem token. |
| 2:40–3:35 | Request → Controller → Service → Repository → Model no Laravel | Seguir uma operação de livro. Explicar validação, regra de negócio, consulta restrita ao dono e persistência. |
| 3:35–4:20 | Screen → Service → Repository → ApiClient no Flutter | Mostrar que a tela não faz HTTP e que o model não importa Flutter. Apontar um widget reutilizado e os validadores do core. |
| 4:20–4:45 | Migrations, factories e seeders | Estrutura do banco, geração de dados de desenvolvimento e conta configurada localmente. |
| 4:45–5:00 | Resultados e entrega | Informar somente os checks executados e deixar os dois repositórios acessíveis. |

Não tente executar todos os pedidos dos quatro CRUDs durante os cinco minutos. O arquivo deve oferecer todos eles para avaliação; na fala, escolha exemplos e mostre que o restante está disponível.

## Arquivos para deixar abertos

- API: `routes/api.php`, `app/Http/Requests/UpsertBookRequest.php` e `app/Http/Controllers/Api/BookController.php`.
- API: `app/Services/BookService.php`, `app/Repositories/Contracts/BookRepositoryInterface.php` e `app/Repositories/Eloquent/BookRepository.php`.
- API: migration de livros, uma factory e o seeder de demonstração.
- Flutter: `lib/screens/books/book_form_screen.dart`, `lib/services/library_book_service.dart`, `lib/repositories/api_book_repository.dart`, `lib/core/network/api_client.dart` e um componente de `widgets/`.
- `rest.http` e o registro dos checks.

Use arquivos reais da versão final. Pratique a troca entre abas, sem procurar arquivos pela primeira vez durante a apresentação.

## Perguntas prováveis

- O que diferencia um Service de um Repository?
- Onde o sistema impede acesso a registros de outro usuário?
- Como a API valida uma requisição que não veio do aplicativo?
- Como os quatro recursos se relacionam?
- O que as factories e os seeders fazem?
- Onde o token é guardado e como o logout funciona?
- Por que há validação na tela e também no servidor?
- Como os widgets e funções são reutilizados?

## Entrega

Para Paradigmas, use **texto online contendo apenas os dois links dos repositórios finais**. Não anexe ZIP ou código-fonte nesse campo. Os repositórios devem estar acessíveis e corresponder ao sistema apresentado.

A próxima terça após 13/11/2026 é **17/11/2026**. O prazo anterior no Moodle era **15/11/2026 às 23h59**; confirme se ele permanece, sem presumir uma prorrogação.

A versão Laravel foi verificada em 13/11/2026: 51 testes Flutter, 41 testes/435 asserções da API e dois testes de integração Flutter/Chrome aprovados. As sete telas foram capturadas com dados da API. Consulte [verificacao.md](verificacao.md) para apresentar os resultados e seus limites; não é necessário navegar pelas sete telas durante os cinco minutos.

# Registro de verificação — versão integrada Laravel

Verificações de **13/11/2026**, após a mudança para a opção A: Flutter/Dart consome a API Laravel por HTTP, com Services e Repositories nas duas aplicações.

| Verificação | Resultado |
| --- | --- |
| API e banco local | Laravel 13.42, Sanctum 4.4, SQLite; migrations e seeder executados |
| Testes da API | **41 testes e 435 asserções aprovados** com PHPUnit 12.5.44 e SQLite em memória |
| Estilo PHP | Pint aprovado em toda a API |
| Composer | Manifesto válido e requisitos da plataforma conferidos; PHP mínimo 8.4.1 |
| Análise Flutter | Nenhum problema encontrado |
| Formatação Dart | 53 arquivos conferidos, sem alterações |
| Testes Flutter | **51 testes aprovados** |
| Integração Flutter/Chrome | **Dois testes aprovados contra a API Laravel real** |
| Prints | Sete PNGs atualizados: login, cadastro de conta, início, biblioteca, formulário, detalhes e Sobre |

A suíte da API cobre os quatro CRUDs, autenticação, token expirado e revogado, limitação de tentativas, campos inválidos, proteção do proprietário, isolamento entre usuários, relações de estante, conflito na exclusão de catálogos, progresso de leitura, capa, factories e seeder idempotente.

Os testes Flutter cobrem models, validadores, regras entre camadas, HTTP/JSON, autenticação, estados da interface, CRUD, concorrência e cancelamento das leituras. Os testes de widgets usam repositórios/services controlados e não substituem o teste do servidor.

A integração executou o cadastro de uma conta de teste local, o CRUD de livros pelos services/repositories reais e a captura das sete telas. Os livros criados pelo cenário foram excluídos ao terminar; registros de outras contas não foram alterados. A conta e os catálogos dessa execução são exclusivos da base local de teste.

## Reprodução

Na API, com PHP, extensões e `.env` preparados conforme o README:

```shell
php artisan migrate --seed
php artisan test
php vendor/bin/pint --test
composer check-platform-reqs
php artisan serve --host=127.0.0.1 --port=8000
```

No Flutter:

```shell
dart format .
flutter analyze
flutter test
```

Para repetir a integração web, inicie um ChromeDriver compatível com o Chrome em `chromedriver --port=4444` e execute:

```shell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/laravel_crud_test.dart -d web-server --headless --browser-name=chrome --browser-dimension=430x1100 --dart-define-from-file=config/api.local.json --no-web-resources-cdn
```

Na execução protegida do Windows, o PHP informou metadados incorretos de leitura/gravação embora as operações reais funcionassem. Um runner privado carregou o autoload diretamente e preservou os testes e a configuração de SQLite em memória. Nenhum arquivo de `vendor/` ou configuração pública do PHPUnit foi alterado para isso. O ambiente de referência foi PHP 8.5.9, Flutter 3.47.1, Dart 3.13.1 e Chrome/ChromeDriver 157.

## Limites

- A validação foi local, com API Laravel e navegador. Não foi realizado novo build ou teste em dispositivo Android/iOS.
- A API não foi publicada em uma hospedagem de produção; os repositórios contêm as instruções para executá-la.
- Os resultados antigos de Firestore são históricos e não foram utilizados para aprovar a versão Laravel. O projeto e os dados do Firebase não foram apagados.
- As configurações locais, senhas, tokens, banco SQLite e dependências instaladas não são enviados ao GitHub.

A apresentação tem cinco minutos, na ordem tema verbal → sistema → código, sem slides e sem vídeo. Para Paradigmas, a entrega é somente os links dos repositórios finais em texto online.

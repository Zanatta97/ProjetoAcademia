# Planejamento — Projeto Academia

> Atualizado em 2026-10-30

## Domínio

App mobile para o usuário cadastrar os próprios treinos, registrar série a série (carga e
repetições) durante a execução, com timer de descanso que avisa por som e visualmente, e acompanhar
o progresso por treino, por exercício e na semana, incluindo o cardio.

Entidades centrais:

- **UserProfile**: dados do usuário além do Identity (altura, meta semanal de cardio, descanso
  padrão)
- **WeightEntry**: histórico de peso corporal
- **Exercise**: catálogo de exercícios (base global + exercícios do usuário)
- **Workout**: ficha de treino (nome, dias da semana), com **WorkoutExercise** e **PlannedSet**
- **WorkoutSession**: um treino executado, com **SessionSet** (cada série realizada)
- **CardioSession**: cardio cronometrado
- **ApiLog**: registro técnico de requisição, para diagnóstico (não é dado do usuário)

Isolamento: **cada usuário só enxerga os próprios dados.** Não existe espaço compartilhado nem
multi-tenant. As exceções são duas: os exercícios globais (`UserId` nulo), que todos leem e ninguém
edita pela API, e o `ApiLog`, que só o perfil `Admin` lê.

## Stack

| Camada | Escolha |
|---|---|
| Backend | .NET 10 (LTS), ASP.NET Core com controllers |
| Banco | SQL Server (Azure SQL Database em produção) |
| ORM | EF Core + `Microsoft.EntityFrameworkCore.SqlServer`, com `EFCore.NamingConventions` (tabelas e colunas em snake_case) |
| Mapeamento | Manual: extensões `ToResponse()` em classes `...Mappings`, por feature, na `Application` |
| Validação | FluentValidation (validators por request, na `Application`) |
| Auth | ASP.NET Core Identity (`IdentityUser<Guid>` + `IdentityRole<Guid>`) + Identity API endpoints (`MapIdentityApi`), bearer token com refresh |
| Documentação da API | OpenAPI nativo do .NET + Scalar (`Scalar.AspNetCore`), só em Development |
| Logging | `ILogger` no código, com Serilog por trás (`Serilog.AspNetCore`, no projeto `Api`); tabela `api_logs` como mecanismo separado |
| Frontend | React Native + Expo (TypeScript), development build (não Expo Go) |
| Navegação | Expo Router |
| Banco local | `expo-sqlite` |
| Notificação | `expo-notifications` (notificação local agendada) |
| Som / vibração | `expo-audio` + `expo-haptics` |
| Ícones | `lucide-react-native` |
| Testes backend | xUnit + FluentAssertions + NSubstitute; integração com `WebApplicationFactory` + Testcontainers (SQL Server) |
| Testes frontend | Jest (`jest-expo`) + React Native Testing Library |

Detalhes do frontend (estado, data fetching, estrutura de telas) ficam para o `frontend:planejar`,
que grava o planejamento próprio do front.

### Hospedagem

- **API e banco:** Azure pessoal, com a API no Azure App Service e o banco no Azure SQL Database. Se
  o app abrir para outros usuários, a hospedagem é revista.
- **App:** build interno (APK), instalado manualmente no aparelho. Sem loja por enquanto.
- **Atualização do app:** toda versão nova é um APK novo, instalado por cima do anterior. Sem
  atualização pelo ar (EAS Update) por enquanto. O APK novo precisa da **mesma chave de
  assinatura** e de `versionCode` maior; trocar a chave obriga a desinstalar, o que apaga o SQLite
  local e as sessões ainda não sincronizadas.
- **Segredos** (connection string): `dotnet user-secrets` em desenvolvimento, configuração do
  serviço no Azure em produção.
- **Deploy da API:** workflow no repo da API, com build e testes em `ubuntu-latest` (o Testcontainers
  exige Docker Linux) e publicação no App Service.
- **Migration em produção:** script de `dotnet ef migrations script --idempotent`, aplicado
  manualmente. Nunca automática, nem no pipeline nem na subida da API.
- **Chaves do Data Protection** (assinam o bearer token): persistidas pelo App Service.

### Tempo em segundo plano: como funciona

Não existe processo contando o tempo em segundo plano. O timer **guarda o instante de fim**, não um
contador:

1. Ao concluir a série, o app grava `restEndsAt = agora + descanso` no SQLite e **agenda uma
   notificação local** com som para `restEndsAt`.
2. A tela calcula `restEndsAt - agora` a cada tick. Com o app em segundo plano, fechado ou com a
   tela bloqueada, quem avisa é o sistema operacional, pela notificação agendada.
3. Com o app aberto no fim do descanso: tela verde, som e vibração.
4. Pular, somar ou subtrair tempo: cancela a notificação e agenda outra.

O cronômetro de cardio e a duração do treino usam o mesmo princípio: guardam `startedAt` e calculam
o tempo decorrido. Sobrevivem a o app ser morto.

O protótipo HTML usa `setInterval`, que **não** sobrevive ao segundo plano. Ele é referência visual,
não de implementação.

### Offline: o que roda sem internet

| Dado | Comportamento |
|---|---|
| Cadastros (perfil, exercícios, treinos, peso) | Gravação online na API; leitura com cache no SQLite |
| Treino em andamento (`WorkoutSession` + `SessionSet`) | Grava **só no aparelho** enquanto acontece; envia à API ao finalizar |
| Cardio (`CardioSession`) | Mesmo fluxo do treino: local, envia ao finalizar |
| Dashboard e histórico | Lidos da API, com o último resultado em cache |

Sincronização das sessões:

- O app gera um **`ClientId` (GUID)** quando a sessão começa.
- Ao finalizar, envia a sessão inteira num `POST` com o `ClientId`. A API tem índice único em
  `(user_id, client_id)`: um reenvio devolve a sessão já gravada, sem duplicar.
- Até receber o `Id` do servidor, a sessão fica marcada como pendente no SQLite e o app tenta de
  novo quando a conexão volta.

## Arquitetura

- **Estilo:** Clean Architecture
- **Separação:** projetos (um `.csproj` por camada)
- **Padrões:** um caso de uso por classe (`...UseCase`), repositório por agregado, `SaveChanges` do
  `DbContext` como unidade de trabalho (atrás de `IUnitOfWork`), mapeamento manual por extensão,
  validação de entrada com FluentValidation, sem MediatR

### Camadas e regra de dependência

Ordem, de dentro para fora: `Domain` → `Application` → `Infra` → `Api`.

- `ProjetoAcademiaAPI.Domain` não referencia nenhum outro projeto da solução nem pacote de
  infraestrutura (EF Core, Identity, ASP.NET).
- `ProjetoAcademiaAPI.Application` referencia somente `Domain`.
- `ProjetoAcademiaAPI.Application` não referencia EF Core, o provedor SQL Server, Identity nem
  ASP.NET Core. Os pacotes externos permitidos nela são `FluentValidation` e
  `FluentValidation.DependencyInjectionExtensions`, que traz as abstrações de DI.
- `ProjetoAcademiaAPI.Infra` referencia `Application` e `Domain`.
- `ProjetoAcademiaAPI.Api` referencia `Application` e `Infra`.
- `ProjetoAcademiaAPI.Api` usa `Infra` **somente** para registrar serviços (`Program.cs` e extensões
  de configuração). Controllers não usam `DbContext` nem repositórios: chamam casos de uso. O worker
  de log fala com `IApiLogRepository` e `IUnitOfWork`, nunca com o `DbContext`.
- Mapeamento: entidade → response por extensão `ToResponse()`; request → entidade pelo construtor e
  pelos métodos da entidade.
- Entidades do `Domain` guardam `UserId` (Guid) sem navegação para o usuário do Identity. A FK para
  `asp_net_users` é configurada só na `Infra`.
- Nenhum caso de uso recebe `UserId` do corpo ou da rota da requisição: o `UserId` vem de
  `ICurrentUser` (Application), implementado na Api a partir do token.
- Todo repositório de dado de usuário filtra por `UserId`. No `DbContext`, um filtro global por
  usuário cobre as entidades de usuário, e `Exercise` aceita `UserId == atual || UserId == null`.
  `ApiLog` fica fora do filtro: quem barra o acesso é a policy `AdminOnly`.
- Como a `Application` não enxerga EF Core, a `Infra` traduz violação de índice único em
  `ConflictException`. É com ela que o caso de uso trata envio simultâneo do mesmo `ClientId`.

### Estrutura de diretórios

Raiz (repo pai, só documentação). **Trabalhar sempre a partir desta pasta**: é aqui que as skills
acham o `Planejamento.md`.

```
ProjetoAcademia/
├── Planejamento.md
├── CLAUDE.md
├── docs/
├── prot_tipo_app_de_academia_for_a_foco.html   (protótipo visual)
├── ProjetoAcademiaAPI/      (submodule)
└── ProjetoAcademiaFront/    (submodule)
```

O repo pai é criado e atualizado manualmente, sem `dependabot.yml`.

Backend:

```
ProjetoAcademiaAPI/
├── ProjetoAcademiaAPI.slnx
├── src/
│   ├── ProjetoAcademiaAPI.Domain/
│   │   ├── Entities/
│   │   ├── Enums/
│   │   ├── Exceptions/        (DomainException, NotFoundException, ConflictException)
│   │   └── Common/            (EntityBase, IUserOwned)
│   ├── ProjetoAcademiaAPI.Application/
│   │   ├── Abstractions/      (ICurrentUser, IUnitOfWork, IApiLogSwitch, I...Repository)
│   │   ├── Common/            (PaginationParameters, PagedResponse<T>)
│   │   └── Features/
│   │       └── <Feature>/     (UseCases, Requests, Responses, Validators, Mappings)
│   ├── ProjetoAcademiaAPI.Infra/
│   │   ├── Persistence/       (AppDbContext, Configurations, Migrations, Repositories, Seed)
│   │   └── Identity/
│   └── ProjetoAcademiaAPI.Api/
│       ├── Controllers/
│       ├── Configuration/     (extensões de registro, Options, transformer do OpenAPI)
│       ├── Errors/            (GlobalExceptionHandler)
│       ├── Logging/           (RequestLoggingMiddleware, fila, worker, switch, Options)
│       ├── Services/          (CurrentUser)
│       └── Program.cs
└── tests/
    ├── ProjetoAcademiaAPI.UnitTests/
    └── ProjetoAcademiaAPI.IntegrationTest/
```

Frontend: definido no `frontend:planejar`.

## Configuração ASP.NET

Exemplos completos ficam em `docs/backend-base.md`. Aqui, o contrato.

Ordem do pipeline:

```
UseForwardedHeaders → UseSerilogRequestLogging → RequestLoggingMiddleware → UseExceptionHandler
→ UseHsts → UseHttpsRedirection → UseCors → UseRateLimiter → UseAuthentication → UseAuthorization
→ endpoints
```

`UseCors` vem antes do rate limiter para a resposta 429 levar os headers. O log vem por fora do
exception handler para capturar a resposta de erro.

| Assunto | Regra |
|---|---|
| CORS | Política `AllowFrontend`, origens de `Cors:AllowedOrigins`, `AllowAnyHeader`, `AllowAnyMethod`. Sem `AllowCredentials` (a auth é bearer, não cookie) e sem `WithExposedHeaders`. Lista vazia na base; `http://localhost:8081` (Expo Web) em Development; em produção, `Cors__AllowedOrigins__0` só se existir cliente web. CORS é regra de navegador: não afeta o APK e não protege a API |
| Proxy | `UseForwardedHeaders` com `XForwardedFor` e `XForwardedProto`, `KnownIPNetworks` e `KnownProxies` limpos. Risco aceito: confia em qualquer proxy, o que só é seguro porque o App Service é a única entrada |
| Rate limit | Por IP, janela fixa, `RateLimiting:Auth` (10 por 60 s), no grupo `/api/auth` com `RequireRateLimiting`. Rejeição responde `ProblemDetails` com `Retry-After` |
| EF Core | `EnableRetryOnFailure(10, 15 s, null)` por causa do Azure SQL com auto-pause. Nada de acesso ao banco na subida. `IUnitOfWork` sem transação manual |
| JSON | `JsonStringEnumConverter` em `AddControllers().AddJsonOptions` e em `ConfigureHttpJsonOptions` (o OpenAPI lê desta). Enums como texto na API |
| OpenAPI / Scalar | Só em Development. Document transformer com esquema bearer, para autenticar no Scalar. `GenerateDocumentationFile` com `NoWarn` `CS1591` no projeto `Api` |
| Autorização | `app.MapControllers().RequireAuthorization()` + `[AllowAnonymous]` onde preciso. Sem `FallbackPolicy`: ela bloquearia `/login` e `/register` do `MapIdentityApi`, que não declaram `AllowAnonymous` |
| Identity | Senha mínima de 8 caracteres, sem exigência de complexidade. `RequireUniqueEmail`. Expiração de bearer e refresh por configuração (`BearerTokenOptions` em `IdentityConstants.BearerScheme`). Refresh expirado sem internet não perde a sessão local |
| Health | `AddHealthChecks` + `MapHealthChecks("/health").AllowAnonymous()`, sem checar o banco, para não acordar o banco pausado |
| HTTPS | `UseHsts` e `UseHttpsRedirection` só fora de Development: o celular acessa a API local por http na rede |
| Options | Classes tipadas com `AddOptions<T>().BindConfiguration().ValidateDataAnnotations().ValidateOnStart()` para `ApiLogging`, `Cors` e `RateLimiting` |
| FluentValidation | `ValidatorOptions.Global.LanguageManager.Culture` = `pt-BR` |
| Hosts | `AllowedHosts` restrito em produção |
| Segredos e variáveis | `dotnet user-secrets` em desenvolvimento, configuração do App Service em produção. `Logs/` fica fora do git |

### Perfil Admin

- `.AddRoles<IdentityRole<Guid>>()` antes de `AddEntityFrameworkStores`: sem isso a claim de role não
  entra no token.
- Role `Admin` criada por `HasData`, com `Id` e `ConcurrencyStamp` fixos.
- Vínculo com o usuário: manual, por SQL documentado. **Sem seed na subida**, para não ir ao banco ao
  iniciar a API.
- Policy `AdminOnly` com `AddAuthorizationBuilder`.
- Role alterada vale a partir do próximo refresh do token.

### Log de requisições em banco

Mecanismo separado do Serilog, para diagnóstico consultável pela API. Sem tela no app na liberação
inicial.

- **Toggle:** só `Admin`, por endpoint, em memória (singleton com `volatile bool`). Desligado grava
  só erro (status >= 400), sem corpo. Ligado grava tudo. Sempre inicia desligado, e a API volta a
  esse estado ao reiniciar. Por ser memória, vale para **uma instância**.
- **Gravação fora da requisição:** o middleware publica num `Channel` limitado
  (`System.Threading.Channels`, modo `DropOldest`) e um `BackgroundService` grava em lote, em escopo
  próprio. Gravar dentro da requisição, somado ao `EnableRetryOnFailure`, seguraria a resposta por
  minutos com o banco fora do ar.
- **Camadas:** entidade `ApiLog` no `Domain`; `IApiLogRepository`, `IApiLogSwitch` e a feature
  `ApiLogs` na `Application`; `ApiLogRepository` e `ApiLogConfiguration` na `Infra`; middleware,
  canal, worker, switch e Options na `Api`. O worker fica na `Api` porque é assunto do host e a
  `Infra` não é Web SDK.
- **Segurança:** `/api/auth/*` nunca grava corpo nem query string (senha e tokens). Header
  `Authorization` nunca é gravado. Corpo truncado em `MaxBodyLength`. Buffer de request e response só
  com o detalhado ligado.
- **Retenção:** a limpeza roda no próprio worker, depois de um flush, se passaram 24 h da última. Sem
  timer, para não acordar o banco pausado.
- **Exceção:** chega ao middleware por `context.Items`, gravada pelo `GlobalExceptionHandler`.
- **Endpoints** (`AdminLogsController`, policy `AdminOnly` em todas as ações): `GET /api/admin/logs`,
  `GET /api/admin/logs/{id}`, `GET /api/admin/logs/settings`, `PUT /api/admin/logs/settings`. A lista
  é paginada, sem corpo, com os filtros `from`, `to`, `userId`, `path`, `statusCode` e `onlyErrors`.
- **Configuração** (seção `ApiLogging`): `RetentionDays` (30), `MaxBodyLength` (4000), `IgnoredPaths`
  (`/health`, `/openapi`, `/scalar`), `BodyExcludedPaths` (`/api/auth`).

## Modelo de dados

Regras gerais:

- `Id` das entidades: `long`, sequencial (`bigint IDENTITY` no SQL Server).
- Usuário: `Guid` do Identity. `UserProfile` usa o próprio `UserId` como chave (1:1).
- Toda entidade de usuário tem `UserId`.
- Datas e horas: `DateTimeOffset` em UTC, `datetimeoffset` no banco, ISO 8601 na API. Datas sem hora
  (`WeightEntry.RecordedOn`): `DateOnly` (`date` no banco).
- Peso e carga: `decimal(6,2)` em kg.
- `Exercise` e `Workout` não são apagados de verdade: são arquivados (`IsArchived`), para o
  histórico continuar com o nome.
- O histórico **não depende da ficha**: `SessionSet` guarda exercício, tipo, carga e repetições no
  momento da execução. Editar o treino depois não altera o passado.
- `SessionSet.PlannedSetId` é referência informativa, **sem FK**: remontar a ficha apaga `PlannedSet`,
  e uma FK quebraria o histórico e as sessões offline ainda não enviadas.
- O `/register` do `MapIdentityApi` não cria `UserProfile`. `GET /api/profile` devolve valores padrão
  até o primeiro `PUT`. Sugestão de padrão: `DefaultRestSeconds` 90, `WeeklyCardioGoalMinutes` 0.
- `ApiLog` não é entidade de usuário: não implementa `IUserOwned`, não tem filtro global nem FK para
  o usuário, porque o log sobrevive ao usuário e pode ser anônimo. Tabela `api_logs`, índice em
  `occurred_at`.

| Entidade | Campos |
|---|---|
| `UserProfile` | `UserId` (PK), `HeightCm`, `WeeklyCardioGoalMinutes`, `DefaultRestSeconds`, `TimeZone` (IANA, ex.: `America/Sao_Paulo`) |
| `WeightEntry` | `Id`, `UserId`, `RecordedOn`, `WeightKg` |
| `Exercise` | `Id`, `UserId` (nulo = global), `Name`, `MuscleGroup`, `IsArchived` |
| `Workout` | `Id`, `UserId`, `Name`, `DaysOfWeek` (flags), `IsArchived` |
| `WorkoutExercise` | `Id`, `UserId`, `WorkoutId`, `ExerciseId`, `Order`, `RestSeconds` (opcional, sobrepõe o padrão do perfil) |
| `PlannedSet` | `Id`, `UserId`, `WorkoutExerciseId`, `Order`, `Quantity`, `SetType`, `TargetRepsMin`, `TargetRepsMax` (nulo = número único) |
| `WorkoutSession` | `Id`, `UserId`, `ClientId`, `WorkoutId`, `StartedAt`, `FinishedAt`, `DurationSeconds`, `TotalVolumeKg` |
| `SessionSet` | `Id`, `UserId`, `WorkoutSessionId`, `ExerciseId`, `PlannedSetId` (nulo = série extra; sem FK), `Order`, `SetType`, `WeightKg`, `Reps`, `CompletedAt`, `IsPersonalRecord` |
| `CardioSession` | `Id`, `UserId`, `ClientId`, `StartedAt`, `FinishedAt`, `DurationSeconds` |
| `ApiLog` | `Id`, `TraceId`, `OccurredAt`, `Method`, `Path`, `QueryString`, `StatusCode`, `ElapsedMs`, `UserId` (nulo = anônimo; sem FK), `RequestBody`, `ResponseBody`, `ExceptionMessage`, `StackTrace`, `IsError` |

Enums (gravados como texto no banco e expostos como texto na API):

- `SetType`: `WarmUp` (Aquecimento), `Feeder` (Preparação), `Working` (Trabalho), `Drop`. Outros
  tipos entram conforme a necessidade.
- `MuscleGroup`: lista fixa (peito, costas, ombros, bíceps, tríceps, antebraço, quadríceps,
  posterior, glúteos, panturrilha, abdômen, corpo inteiro)
- `DaysOfWeek`: flags de segunda a domingo

Repetições alvo (`PlannedSet`): o usuário escolhe entre número único e faixa.

- Número único: `TargetRepsMin` preenchido, `TargetRepsMax` nulo (ex.: 10).
- Faixa: os dois preenchidos, com `TargetRepsMax > TargetRepsMin` (ex.: 6–8).

Calculados, não gravados:

- **IMC** = peso atual ÷ (altura em m)²
- **Peso atual** = `WeightEntry` mais recente. O perfil não tem campo próprio de peso.

Calculados ao finalizar e gravados na sessão (para o dashboard não somar série por série):

- `DurationSeconds` = `FinishedAt - StartedAt`
- `TotalVolumeKg` = soma de `WeightKg × Reps` das séries que contam como volume: `Working` e
  `Drop`. `WarmUp` e `Feeder` ficam fora.
- `SessionSet.IsPersonalRecord`: calculado pela API ao receber a sessão (regra em **Recorde
  pessoal**, abaixo).

### Recorde pessoal (PR)

- Conta como PR a série de `Working` ou `Drop` com carga maior que qualquer série anterior do mesmo
  exercício; com a mesma carga, mais repetições que a melhor anterior nessa carga.
- A primeira vez que o exercício é feito não gera PR.
- A resposta do `POST /api/workout-sessions` traz os PRs do dia, e o app os mostra no resumo do fim
  do treino. Sem conexão, o aviso aparece quando a sessão for sincronizada.

### Semana do dashboard

De segunda a domingo, no fuso (`TimeZone`) do perfil. O cardio entra como minutos da semana ×
`WeeklyCardioGoalMinutes`.

### Endpoints e paginação

Endpoints (prefixo `/api`, recurso no plural em kebab-case): `profile`, `weight-entries`,
`exercises`, `workouts`, `workout-sessions`, `cardio-sessions`, `dashboard/weekly`,
`exercises/{id}/progress`, `admin/logs`. Autenticação em `/api/auth` (`MapIdentityApi`). Fora do
prefixo: `/health`.

| Paginam (`GET`) | Ordem fixa | Não paginam (`GET`) |
|---|---|---|
| `exercises` | `Name`, `Id` | `workouts` |
| `weight-entries` | `RecordedOn` desc, `Id` desc | `exercises/{id}/progress` |
| `workout-sessions` | `StartedAt` desc, `Id` desc | `dashboard/weekly` |
| `cardio-sessions` | `StartedAt` desc, `Id` desc | |
| `admin/logs` | `OccurredAt` desc, `Id` desc | |

- Query: `page` e `pageSize` (padrão 20, máximo 100, mínimos 1), em `PaginationParameters`, classe
  cujo setter limita o valor. Zero ou negativo não pode chegar ao `Skip`.
- Na `Infra`, a extensão `ToPagedResponseAsync` em `IQueryable` faz `Count` + `Skip`/`Take`. A
  ordenação é estável e aplicada pelo repositório antes dela.
- `exercises` aceita os filtros `search` e `muscleGroup`. A coluna `Name` usa collation que ignora
  acento (ex.: `Latin1_General_CI_AI`), para `biceps` achar `bíceps`.
- **Risco:** o máximo de 100 por página obriga o app a buscar várias páginas para montar o cache
  offline do catálogo.

## Escopo por liberação

### Liberação inicial

- Cadastro e login (Identity) e perfil: altura, meta semanal de cardio, descanso padrão
- Histórico de peso e IMC
- Catálogo de exercícios: base global + do usuário
- Fichas de treino: exercícios, séries planejadas (quantidade, tipo, repetições únicas ou em faixa)
  e dias da semana
- Execução do treino: registro série a série, timer de descanso com notificação sonora e visual,
  funcionando offline
- Cronômetro de cardio
- Soma de carga (volume) ao final do treino
- Recorde pessoal: aviso no fim do treino quando houver PR no dia
- Dashboard semanal: treinos feitos × planejados, volume da semana, minutos de cardio × meta
- Histórico de carga por exercício com relatório de progresso, incluindo os PRs
- Log de requisições em banco e perfil `Admin`, operados pela API, sem tela no app

### Futuro

- Distância estimada no cardio a partir de uma velocidade média definida pelo usuário
- Cadastro de alimentos (carboidratos e proteínas por g, nutrição em geral)
- Dieta (nome, dias da semana, alimento, quantidade) e dieta no dashboard
- Novos tipos de série, conforme a necessidade

### Talvez

- Vídeos ou fotos dos exercícios

## Design

Referência: `prot_tipo_app_de_academia_for_a_foco.html`, paleta "Força & Foco". Só tema escuro.

| Token | Hex | Uso |
|---|---|---|
| `bg` | `#0F1016` | Fundo principal (evita preto puro) |
| `card` | `#1C1E26` | Superfícies e cards |
| `border` | `#2A2D3A` | Bordas sutis |
| `primary` | `#0066FF` | Ação principal, navegação ativa |
| `royal` | `#2563EB` | Fim do gradiente primário |
| `amber` | `#F59E0B` | Timer de descanso rodando, recorde pessoal |
| `textMain` | `#F3F4F6` | Texto principal |
| `textMuted` | `#9CA3AF` | Texto secundário |
| `success` | `#22C55E` | Série concluída, descanso terminado |
| `warmup` | `#EAB308` | Série de aquecimento |
| `failure` | `#EF4444` | Drop-set, finalizar treino |
| `pr` | `#3B82F6` | Recorde pessoal (detalhe) |
| `biset` | `#8B5CF6` | Reservado (bi-set, fora do escopo atual) |

- Gradiente primário: `#0066FF → #2563EB`, 135°. Gradiente de recorde: `#F59E0B → #D97706`, 135°.
- Fontes: **Inter** para texto e **JetBrains Mono** para números (carga, repetições, timer), para os
  dígitos não pularem de lugar.
- As cores semânticas (verde, amarelo, vermelho) são exclusivas de feedback do treino. Navegação usa
  só o azul.

## Convenções

- **Idioma:** identificadores, tabelas, rotas e enums em inglês. Texto de interface, mensagens de
  erro, comentários e documentação em português.
- **Sufixos:** entidades sem sufixo (`Workout`); `...UseCase`; `...Request` (entrada) e
  `...Response` (saída); `...Validator` (FluentValidation, um por request); `...Mappings` (classe
  estática com extensões `ToResponse()`, em `Features/<Feature>/Mappings/<Entidade>Mappings.cs`);
  `I...Repository` / `...Repository`; `...Configuration` (EF); `...Controller`; `...Options`
  (configuração tipada).
- **Banco:** tabelas e colunas em snake_case, tabela no plural (`workout_sessions`).
- **Resposta da API:** sucesso devolve o DTO direto; erro devolve `ProblemDetails` (RFC 9457) com
  `traceId`; lista paginada devolve `PagedResponse<T>` no corpo, com `items`, `page`, `pageSize`,
  `totalCount`, `totalPages` e `hasNextPage`. Sem envelope de resposta e sem paginação em header.
- **Frontend:** TypeScript estrito; o restante fica no planejamento do front.

## Qualidade

- **Testes:** backend com xUnit + FluentAssertions + NSubstitute; unitários em `Domain` e
  `Application`, integração dos endpoints com `WebApplicationFactory` + Testcontainers com SQL Server
  (exige Docker). Frontend com Jest + React Native Testing Library, priorizando a lógica do timer, o
  cálculo de volume e a fila de sincronização.
- **Logging:** o código usa `ILogger`. Por trás, Serilog lendo da configuração, com
  `UseSerilogRequestLogging`: console em todos os ambientes (JSON em produção) e arquivo só em
  Development. A tabela `api_logs` é mecanismo separado (ver **Log de requisições em banco**).
- **Validação:** o caso de uso roda o validator do request antes de qualquer regra de negócio.
  Falha de validação vira 400 com `ValidationProblemDetails` (erros por campo, mensagens em
  português).
- **Erros:** handler global (`IExceptionHandler`) converte exceção em `ProblemDetails`. Regra de
  negócio violada lança exceção de domínio (`Domain/Exceptions`), que vira 400/409/404;
  `UnauthorizedAccessException` vira 401; cancelamento pelo cliente não registra erro 500; erro
  inesperado vira 500, sem detalhe interno na resposta. O envio simultâneo do mesmo `ClientId` devolve
  a sessão já gravada, sem 500.

## Decisões tomadas

Registradas em 2026-10-29:

- **Banco:** SQL Server no lugar de PostgreSQL, por causa da hospedagem no Azure. ORM com o provedor
  SQL Server do EF Core.
- **Mapeamento:** decisão revista em 2026-10-30 (ver abaixo).
- **Tipos de série:** `WarmUp`, `Feeder`, `Working`, `Drop`. O tipo `Normal` saiu.
- **Volume:** conta `Working` e `Drop`; `WarmUp` e `Feeder` ficam fora.
- **Cardio:** meta semanal em minutos.
- **Peso atual:** sempre o último `WeightEntry`, sem campo no perfil.
- **Repetições alvo:** número único ou faixa, à escolha do usuário.
- **Semana do dashboard:** segunda a domingo, no fuso do perfil.
- **Recorde pessoal:** entra na liberação inicial, com aviso no fim do treino.
- **Validação:** FluentValidation.
- **Hospedagem:** Azure pessoal, com Azure App Service e Azure SQL Database.
- **Distribuição do app:** build interno, instalado manualmente. Atualização só por APK novo, sem
  EAS Update.
- **Local de trabalho:** sempre a partir da pasta pai.
- **Repo pai:** criado e mantido manualmente, sem dependabot.

Registradas em 2026-10-30:

- **Mapeamento:** volta ao mapeamento manual por extensão (`...Mappings`, com `ToResponse()`), no
  lugar do AutoMapper adotado em 2026-10-29. Motivo: receio com a licença paga do AutoMapper e com
  ficar preso a uma versão antiga.
- **Logging:** Serilog na stack, com `ILogger` no código e a tabela `api_logs` como mecanismo
  separado.
- **Contrato da API:** mantido. Sucesso devolve o DTO direto, erro devolve `ProblemDetails`, lista
  paginada devolve `PagedResponse<T>` no corpo.
- **Log detalhado:** liga e desliga só por `Admin`, em memória. Volta a desligado quando a API
  reinicia.
- **Gravação do log:** `Channel` limitado com worker próprio, para o banco fora do ar não segurar a
  resposta.
- **CORS:** sem credenciais, porque a auth é bearer.
- **`SessionSet.PlannedSetId`:** sem FK, para remontar a ficha não quebrar o histórico nem as sessões
  offline pendentes.
- **Exceções:** `DomainException`, `NotFoundException` e `ConflictException` em `Domain/Exceptions`.
- **Mock nos testes:** NSubstitute.

## Decisões em aberto

- [ ] **Skill de teste do front:** a skill `frontend:criar-testes` assume Vitest (React web); o
  projeto usa Jest. Ao chegar a hora de testar o front, confirmar a criação de uma skill nova para
  React Native.
- [ ] **PR dentro da mesma sessão:** as séries da mesma sessão contam como anteriores? O exemplo em
  `docs/backend-base.md` diz que sim (100 kg e depois 105 kg são dois PRs). A alternativa é marcar só
  a melhor série do exercício no dia.
- [ ] **`DaysOfWeek` como texto:** com `[Flags]`, o texto vira `"Monday, Wednesday"`. Funciona, mas
  dificulta filtrar no SQL por dia. Se o dashboard precisar disso no banco, `int` resolve melhor para
  este enum.
- [ ] **`/register` público:** mantido aberto, só com rate limit. Rever se o app abrir para outros
  usuários.
- [ ] **"Esqueci a senha":** depende de um `IEmailSender` real. O padrão não envia e-mail.
- [ ] **FluentAssertions:** fica por enquanto (8.11, no projeto `UnitTests`). A licença é Xceed
  Community: só uso não comercial, e revogável. Reuso comercial exige rever; a alternativa é
  AwesomeAssertions (Apache 2.0).

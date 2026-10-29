# Planejamento — Projeto Academia

> Atualizado em 2026-10-29

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

Isolamento: **cada usuário só enxerga os próprios dados.** Não existe espaço compartilhado nem
multi-tenant. A única exceção são os exercícios globais (`UserId` nulo), que todos leem e ninguém
edita pela API.

## Stack

| Camada | Escolha |
|---|---|
| Backend | .NET 10 (LTS), ASP.NET Core com controllers |
| Banco | SQL Server (Azure SQL Database em produção) |
| ORM | EF Core + `Microsoft.EntityFrameworkCore.SqlServer`, com `EFCore.NamingConventions` (tabelas e colunas em snake_case) |
| Mapeamento | AutoMapper (profiles por feature, na `Application`) |
| Validação | FluentValidation (validators por request, na `Application`) |
| Auth | ASP.NET Core Identity (`IdentityUser<Guid>`) + Identity API endpoints (`MapIdentityApi`), bearer token com refresh |
| Documentação da API | OpenAPI nativo do .NET + Scalar (`Scalar.AspNetCore`) |
| Frontend | React Native + Expo (TypeScript), development build (não Expo Go) |
| Navegação | Expo Router |
| Banco local | `expo-sqlite` |
| Notificação | `expo-notifications` (notificação local agendada) |
| Som / vibração | `expo-audio` + `expo-haptics` |
| Ícones | `lucide-react-native` |
| Testes backend | xUnit; integração com `WebApplicationFactory` + Testcontainers (SQL Server) |
| Testes frontend | Jest (`jest-expo`) + React Native Testing Library |

Detalhes do frontend (estado, data fetching, estrutura de telas) ficam para o `frontend:planejar`,
que grava o planejamento próprio do front.

AutoMapper a partir da v15 tem licença comercial, com licença **Community** gratuita para uso
pessoal. Usar a versão atual com a chave Community, guardada como segredo de configuração (nunca no
repositório).

### Hospedagem

- **API e banco:** Azure pessoal, com a API no Azure App Service e o banco no Azure SQL Database. Se
  o app abrir para outros usuários, a hospedagem é revista.
- **App:** build interno (APK), instalado manualmente no aparelho. Sem loja por enquanto.
- **Atualização do app:** toda versão nova é um APK novo, instalado por cima do anterior. Sem
  atualização pelo ar (EAS Update) por enquanto. O APK novo precisa da **mesma chave de
  assinatura** e de `versionCode` maior; trocar a chave obriga a desinstalar, o que apaga o SQLite
  local e as sessões ainda não sincronizadas.
- **Segredos** (connection string, chave do AutoMapper): `dotnet user-secrets` em desenvolvimento,
  configuração do serviço no Azure em produção.

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
  `DbContext` como unidade de trabalho (atrás de `IUnitOfWork`), mapeamento com AutoMapper (um
  `Profile` por feature), validação de entrada com FluentValidation, sem MediatR

### Camadas e regra de dependência

Ordem, de dentro para fora: `Domain` → `Application` → `Infrastructure` → `Api`.

- `ProjetoAcademia.Domain` não referencia nenhum outro projeto da solução nem pacote de
  infraestrutura (EF Core, Identity, ASP.NET).
- `ProjetoAcademia.Application` referencia somente `Domain`.
- `ProjetoAcademia.Application` não referencia EF Core, o provedor SQL Server, Identity nem ASP.NET
  Core. Os pacotes externos permitidos nela são AutoMapper e FluentValidation.
- `ProjetoAcademia.Infrastructure` referencia `Application` e `Domain`.
- `ProjetoAcademia.Api` referencia `Application` e `Infrastructure`.
- `ProjetoAcademia.Api` usa `Infrastructure` **somente** para registrar serviços no `Program.cs`.
  Controllers não usam `DbContext` nem repositórios: chamam casos de uso.
- Entidades do `Domain` guardam `UserId` (Guid) sem navegação para o usuário do Identity. A FK para
  `AspNetUsers` é configurada só na `Infrastructure`.
- Nenhum caso de uso recebe `UserId` do corpo ou da rota da requisição: o `UserId` vem de
  `ICurrentUser` (Application), implementado na Api a partir do token.
- Todo repositório filtra por `UserId`. No `DbContext`, um filtro global por usuário cobre as
  entidades de usuário, e `Exercise` aceita `UserId == atual || UserId == null`.

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
├── ProjetoAcademia.slnx
├── src/
│   ├── ProjetoAcademia.Domain/
│   │   ├── Entities/
│   │   ├── Enums/
│   │   └── Common/            (EntityBase, IUserOwned)
│   ├── ProjetoAcademia.Application/
│   │   ├── Abstractions/      (ICurrentUser, IUnitOfWork, I...Repository)
│   │   └── Features/
│   │       └── <Feature>/     (UseCases, Requests, Responses, Validators, Mappings)
│   ├── ProjetoAcademia.Infrastructure/
│   │   ├── Persistence/       (AppDbContext, Configurations, Migrations, Repositories, Seed)
│   │   └── Identity/
│   └── ProjetoAcademia.Api/
│       ├── Controllers/
│       └── Program.cs
└── tests/
    ├── ProjetoAcademia.UnitTests/
    └── ProjetoAcademia.IntegrationTests/
```

Frontend: definido no `frontend:planejar`.

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

| Entidade | Campos |
|---|---|
| `UserProfile` | `UserId` (PK), `HeightCm`, `WeeklyCardioGoalMinutes`, `DefaultRestSeconds`, `TimeZone` (IANA, ex.: `America/Sao_Paulo`) |
| `WeightEntry` | `Id`, `UserId`, `RecordedOn`, `WeightKg` |
| `Exercise` | `Id`, `UserId` (nulo = global), `Name`, `MuscleGroup`, `IsArchived` |
| `Workout` | `Id`, `UserId`, `Name`, `DaysOfWeek` (flags), `IsArchived` |
| `WorkoutExercise` | `Id`, `UserId`, `WorkoutId`, `ExerciseId`, `Order`, `RestSeconds` (opcional, sobrepõe o padrão do perfil) |
| `PlannedSet` | `Id`, `UserId`, `WorkoutExerciseId`, `Order`, `Quantity`, `SetType`, `TargetRepsMin`, `TargetRepsMax` (nulo = número único) |
| `WorkoutSession` | `Id`, `UserId`, `ClientId`, `WorkoutId`, `StartedAt`, `FinishedAt`, `DurationSeconds`, `TotalVolumeKg` |
| `SessionSet` | `Id`, `UserId`, `WorkoutSessionId`, `ExerciseId`, `PlannedSetId` (nulo = série extra), `Order`, `SetType`, `WeightKg`, `Reps`, `CompletedAt`, `IsPersonalRecord` |
| `CardioSession` | `Id`, `UserId`, `ClientId`, `StartedAt`, `FinishedAt`, `DurationSeconds` |

Enums (gravados como texto no banco):

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

Endpoints (prefixo `/api`, recurso no plural em kebab-case): `profile`, `weight-entries`,
`exercises`, `workouts`, `workout-sessions`, `cardio-sessions`, `dashboard/weekly`,
`exercises/{id}/progress`. Autenticação em `/api/auth` (`MapIdentityApi`).

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
  `...Response` (saída); `...Validator` (FluentValidation, um por request); `...Profile`
  (AutoMapper, um por feature, na pasta `Mappings`); `I...Repository` / `...Repository`;
  `...Configuration` (EF); `...Controller`.
- **Banco:** tabelas e colunas em snake_case, tabela no plural (`workout_sessions`).
- **Resposta da API:** sucesso devolve o DTO direto; erro devolve `ProblemDetails` (RFC 9457); lista
  paginada devolve `PagedResponse<T>` com `items`, `page`, `pageSize`, `totalCount`.
- **Frontend:** TypeScript estrito; o restante fica no planejamento do front.

## Qualidade

- **Testes:** backend com xUnit; unitários em `Domain` e `Application`, integração dos endpoints com
  `WebApplicationFactory` + Testcontainers com SQL Server (exige Docker). Frontend com Jest + React
  Native Testing Library, priorizando a lógica do timer, o cálculo de volume e a fila de
  sincronização.
- **Logging:** `ILogger` nativo, saída estruturada em JSON no console.
- **Validação:** o caso de uso roda o validator do request antes de qualquer regra de negócio.
  Falha de validação vira 400 com `ValidationProblemDetails` (erros por campo, mensagens em
  português).
- **Erros:** handler global (`IExceptionHandler`) converte exceção em `ProblemDetails`. Regra de
  negócio violada lança exceção de domínio, que vira 400/409/404; erro inesperado vira 500, sem
  detalhe interno na resposta.

## Decisões tomadas

Registradas em 2026-10-29:

- **Banco:** SQL Server no lugar de PostgreSQL, por causa da hospedagem no Azure. ORM com o provedor
  SQL Server do EF Core.
- **Mapeamento:** AutoMapper no lugar do mapeamento manual por extensão.
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

## Decisões em aberto

- [ ] **Skill de teste do front:** a skill `frontend:criar-testes` assume Vitest (React web); o
  projeto usa Jest. Ao chegar a hora de testar o front, confirmar a criação de uma skill nova para
  React Native.

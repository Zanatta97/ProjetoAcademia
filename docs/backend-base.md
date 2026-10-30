# Backend — base para começar

> **Material de apoio, não oficial.** Sugestões para dar o primeiro passo no backend. Onde este
> documento divergir do `Planejamento.md`, vale o planejamento; onde divergir do código que você
> escrever, vale o código. Os trechos são esqueletos: nome, assinatura e responsabilidade — não
> implementação final.

## Sumário

1. [Estado atual da solução](#1-estado-atual-da-solução)
2. [Estrutura de pastas completa](#2-estrutura-de-pastas-completa)
3. [Domain](#3-domain)
4. [Application](#4-application)
5. [Infra](#5-infra)
6. [Api](#6-api)
7. [Configuração ASP.NET](#7-configuração-aspnet)
8. [Log de requisições em banco](#8-log-de-requisições-em-banco)
9. [Testes](#9-testes)
10. [Deploy](#10-deploy)
11. [Ordem sugerida de desenvolvimento](#11-ordem-sugerida-de-desenvolvimento)
12. [Pontos em aberto](#12-pontos-em-aberto)

---

## 1. Estado atual da solução

A solução já existe em `ProjetoAcademiaAPI/`, então não há nada para criar com `dotnet new`. Esta
seção mostra o que está lá, as referências e o que falta adicionar.

```
ProjetoAcademiaAPI/
├── ProjetoAcademiaAPI.slnx
├── src/
│   ├── ProjetoAcademiaAPI.Domain/
│   ├── ProjetoAcademiaAPI.Application/
│   ├── ProjetoAcademiaAPI.Infra/
│   └── ProjetoAcademiaAPI.Api/            (http://localhost:5290, Program.cs ainda do template)
└── tests/
    ├── ProjetoAcademiaAPI.UnitTests/
    └── ProjetoAcademiaAPI.IntegrationTest/
```

### Referências entre projetos

A regra de dependência do planejamento vira referência de projeto, e o compilador passa a barrar a
violação.

```
Domain          ← (nada)
Application     → Domain
Infra           → Application, Domain
Api             → Application, Infra
UnitTests       → Domain, Application
IntegrationTest → Api
```

> **Corrigir antes de compilar os testes.** Os dois `.csproj` de `tests/` apontam para
> `..\ProjetoAcademiaAPI.Application\...`, `..\ProjetoAcademiaAPI.Domain\...` e
> `..\ProjetoAcademiaAPI.Api\...`. A partir de `tests/<projeto>/`, esse caminho cai em `tests/`, onde
> esses projetos não existem. O caminho certo sobe mais um nível e entra em `src`:

```xml
<!-- tests/ProjetoAcademiaAPI.UnitTests/ProjetoAcademiaAPI.UnitTests.csproj -->
<ProjectReference Include="..\..\src\ProjetoAcademiaAPI.Application\ProjetoAcademiaAPI.Application.csproj" />
<ProjectReference Include="..\..\src\ProjetoAcademiaAPI.Domain\ProjetoAcademiaAPI.Domain.csproj" />

<!-- tests/ProjetoAcademiaAPI.IntegrationTest/ProjetoAcademiaAPI.IntegrationTest.csproj -->
<ProjectReference Include="..\..\src\ProjetoAcademiaAPI.Api\ProjetoAcademiaAPI.Api.csproj" />
```

### Pacotes por projeto

| Projeto | Já instalado | Falta adicionar |
|---|---|---|
| `Domain` | nenhum | |
| `Application` | `FluentValidation`, `FluentValidation.DependencyInjectionExtensions` | |
| `Infra` | `Microsoft.EntityFrameworkCore`, `Microsoft.EntityFrameworkCore.SqlServer`, `EFCore.NamingConventions`, `Microsoft.AspNetCore.Identity.EntityFrameworkCore` | |
| `Api` | `Microsoft.AspNetCore.OpenApi`, `Scalar.AspNetCore`, `Microsoft.EntityFrameworkCore.Design` | `Serilog.AspNetCore` |
| `UnitTests` | `xunit`, `FluentAssertions`, `Microsoft.NET.Test.Sdk`, `coverlet.collector` | `NSubstitute` |
| `IntegrationTest` | `xunit`, `Microsoft.AspNetCore.Mvc.Testing`, `Testcontainers.MsSql`, `Microsoft.NET.Test.Sdk`, `coverlet.collector` | |

```bash
# na raiz de ProjetoAcademiaAPI
dotnet add src/ProjetoAcademiaAPI.Api package Serilog.AspNetCore
dotnet add tests/ProjetoAcademiaAPI.UnitTests package NSubstitute
```

`Serilog.AspNetCore` já traz os sinks de console e arquivo, o formatador JSON e a leitura da
configuração, sem pacote extra. O `Channel` do log vem de `System.Threading.Channels`, que faz parte
do .NET.

---

## 2. Estrutura de pastas completa

O planejamento define o primeiro nível. Abaixo, uma sugestão de como ficaria preenchido.

```
ProjetoAcademiaAPI/
├── ProjetoAcademiaAPI.slnx
├── src/
│   ├── ProjetoAcademiaAPI.Domain/
│   │   ├── Common/
│   │   │   ├── EntityBase.cs
│   │   │   └── IUserOwned.cs
│   │   ├── Entities/
│   │   │   ├── UserProfile.cs
│   │   │   ├── WeightEntry.cs
│   │   │   ├── Exercise.cs
│   │   │   ├── Workout.cs
│   │   │   ├── WorkoutExercise.cs
│   │   │   ├── PlannedSet.cs
│   │   │   ├── WorkoutSession.cs
│   │   │   ├── SessionSet.cs
│   │   │   ├── CardioSession.cs
│   │   │   └── ApiLog.cs
│   │   ├── Enums/
│   │   │   ├── SetType.cs
│   │   │   ├── MuscleGroup.cs
│   │   │   └── DaysOfWeek.cs
│   │   └── Exceptions/
│   │       ├── DomainException.cs
│   │       ├── NotFoundException.cs
│   │       └── ConflictException.cs
│   │
│   ├── ProjetoAcademiaAPI.Application/
│   │   ├── Abstractions/
│   │   │   ├── ICurrentUser.cs
│   │   │   ├── IUnitOfWork.cs
│   │   │   ├── IApiLogSwitch.cs
│   │   │   └── Repositories/
│   │   │       ├── IUserProfileRepository.cs
│   │   │       ├── IWeightEntryRepository.cs
│   │   │       ├── IExerciseRepository.cs
│   │   │       ├── IWorkoutRepository.cs
│   │   │       ├── IWorkoutSessionRepository.cs
│   │   │       ├── ICardioSessionRepository.cs
│   │   │       └── IApiLogRepository.cs
│   │   ├── Common/
│   │   │   ├── PaginationParameters.cs
│   │   │   └── PagedResponse.cs
│   │   ├── Features/
│   │   │   ├── Profile/
│   │   │   ├── WeightEntries/
│   │   │   ├── Exercises/
│   │   │   ├── Workouts/
│   │   │   ├── WorkoutSessions/
│   │   │   ├── CardioSessions/
│   │   │   ├── Dashboard/
│   │   │   └── ApiLogs/
│   │   └── DependencyInjection.cs
│   │
│   ├── ProjetoAcademiaAPI.Infra/
│   │   ├── Persistence/
│   │   │   ├── AppDbContext.cs
│   │   │   ├── QueryableExtensions.cs   (ToPagedResponseAsync)
│   │   │   ├── Configurations/          (um ...Configuration por entidade)
│   │   │   ├── Migrations/
│   │   │   ├── Repositories/            (um ...Repository por interface)
│   │   │   └── Seed/
│   │   │       └── GlobalExercises.cs
│   │   ├── Identity/
│   │   │   └── (configuração do Identity, se crescer)
│   │   └── DependencyInjection.cs
│   │
│   └── ProjetoAcademiaAPI.Api/
│       ├── Configuration/
│       │   ├── ApiConfigurationExtensions.cs
│       │   ├── AppCorsOptions.cs
│       │   ├── AuthRateLimitOptions.cs
│       │   ├── AuthorizationPolicies.cs
│       │   └── BearerSecuritySchemeTransformer.cs
│       ├── Controllers/
│       │   ├── ProfileController.cs
│       │   ├── WeightEntriesController.cs
│       │   ├── ExercisesController.cs
│       │   ├── WorkoutsController.cs
│       │   ├── WorkoutSessionsController.cs
│       │   ├── CardioSessionsController.cs
│       │   ├── DashboardController.cs
│       │   └── AdminLogsController.cs
│       ├── Errors/
│       │   └── GlobalExceptionHandler.cs
│       ├── Logging/
│       │   ├── ApiLoggingOptions.cs
│       │   ├── ApiLogQueue.cs
│       │   ├── ApiLogSwitch.cs
│       │   ├── ApiLogWriter.cs
│       │   ├── HttpContextLogExtensions.cs
│       │   └── RequestLoggingMiddleware.cs
│       ├── Services/
│       │   └── CurrentUser.cs
│       ├── appsettings.json
│       ├── appsettings.Development.json
│       ├── appsettings.Production.json
│       └── Program.cs
│
└── tests/
    ├── ProjetoAcademiaAPI.UnitTests/
    │   ├── Domain/
    │   └── Application/
    └── ProjetoAcademiaAPI.IntegrationTest/
        ├── Fixtures/                (WebApplicationFactory + Testcontainers)
        └── Endpoints/
```

### Dentro de uma feature

Exemplo com `Workouts`. Toda feature segue o mesmo desenho.

```
Features/Workouts/
├── UseCases/
│   ├── CreateWorkoutUseCase.cs
│   ├── UpdateWorkoutUseCase.cs
│   ├── ArchiveWorkoutUseCase.cs
│   ├── GetWorkoutByIdUseCase.cs
│   └── ListWorkoutsUseCase.cs
├── Requests/
│   ├── CreateWorkoutRequest.cs
│   ├── UpdateWorkoutRequest.cs
│   ├── WorkoutExerciseRequest.cs
│   └── PlannedSetRequest.cs
├── Responses/
│   ├── WorkoutResponse.cs
│   ├── WorkoutSummaryResponse.cs
│   ├── WorkoutExerciseResponse.cs
│   └── PlannedSetResponse.cs
├── Validators/
│   ├── CreateWorkoutRequestValidator.cs
│   └── UpdateWorkoutRequestValidator.cs
└── Mappings/
    └── WorkoutMappings.cs
```

### Casos de uso sugeridos por feature

| Feature | Casos de uso | Endpoint | Pagina? |
|---|---|---|---|
| `Profile` | `GetProfileUseCase`, `UpsertProfileUseCase` | `GET/PUT /api/profile` | não |
| `WeightEntries` | `AddWeightEntryUseCase`, `ListWeightEntriesUseCase`, `DeleteWeightEntryUseCase` | `/api/weight-entries` | sim |
| `Exercises` | `CreateExerciseUseCase`, `UpdateExerciseUseCase`, `ArchiveExerciseUseCase`, `ListExercisesUseCase`, `GetExerciseProgressUseCase` | `/api/exercises`, `/api/exercises/{id}/progress` | `exercises` sim; `progress` não |
| `Workouts` | `CreateWorkoutUseCase`, `UpdateWorkoutUseCase`, `ArchiveWorkoutUseCase`, `GetWorkoutByIdUseCase`, `ListWorkoutsUseCase` | `/api/workouts` | não |
| `WorkoutSessions` | `RegisterWorkoutSessionUseCase`, `GetWorkoutSessionByIdUseCase`, `ListWorkoutSessionsUseCase` | `/api/workout-sessions` | sim |
| `CardioSessions` | `RegisterCardioSessionUseCase`, `ListCardioSessionsUseCase` | `/api/cardio-sessions` | sim |
| `Dashboard` | `GetWeeklyDashboardUseCase` | `/api/dashboard/weekly` | não |
| `ApiLogs` | `ListApiLogsUseCase`, `GetApiLogByIdUseCase`, `GetApiLogSettingsUseCase`, `UpdateApiLogSettingsUseCase` | `/api/admin/logs` | a lista sim |

`DeleteWeightEntryUseCase` é sugestão: o planejamento só proíbe apagar `Exercise` e `Workout`.

---

## 3. Domain

Regras que guiam esta camada:

- Sem nenhuma referência externa. Nada de atributo do EF (`[Key]`, `[MaxLength]`) — isso vai nas
  `Configurations`.
- `set` privado: a entidade só muda por método, e o método garante a regra.
- Construtor sem parâmetro `private` (o EF precisa dele); quem cria usa o construtor público ou um
  método de fábrica.
- Coleções expostas como `IReadOnlyCollection`, com uma `List` privada por trás.

### Common

```csharp
namespace ProjetoAcademiaAPI.Domain.Common;

public abstract class EntityBase
{
    public long Id { get; protected set; }
}
```

```csharp
namespace ProjetoAcademiaAPI.Domain.Common;

// Marca as entidades que pertencem a um usuário. O DbContext usa esta interface para aplicar o
// filtro global por usuário de uma vez só.
public interface IUserOwned
{
    Guid UserId { get; }
}
```

### Enums

```csharp
public enum SetType
{
    WarmUp,
    Feeder,
    Working,
    Drop
}

public enum MuscleGroup
{
    Chest,
    Back,
    Shoulders,
    Biceps,
    Triceps,
    Forearms,
    Quadriceps,
    Hamstrings,
    Glutes,
    Calves,
    Abs,
    FullBody
}

[Flags]
public enum DaysOfWeek
{
    None      = 0,
    Monday    = 1 << 0,
    Tuesday   = 1 << 1,
    Wednesday = 1 << 2,
    Thursday  = 1 << 3,
    Friday    = 1 << 4,
    Saturday  = 1 << 5,
    Sunday    = 1 << 6
}
```

Uma extensão pequena ajuda em mais de um lugar (volume e PR):

```csharp
public static class SetTypeExtensions
{
    // Só Working e Drop contam para volume e para recorde pessoal.
    public static bool CountsAsVolume(this SetType type) =>
        type is SetType.Working or SetType.Drop;
}
```

### Exceções de domínio

```csharp
public class DomainException(string message) : Exception(message);        // vira 400
public sealed class NotFoundException(string message) : DomainException(message);  // vira 404
public sealed class ConflictException(string message) : DomainException(message);  // vira 409
```

### Entidades

Abaixo, as que têm comportamento. As mais simples (`WeightEntry`, `CardioSession`) seguem o mesmo
molde, só com menos método.

**UserProfile** — a chave é o próprio `UserId` (1:1 com o Identity), por isso não herda
`EntityBase`. Os valores iniciais são os padrões que o `GET /api/profile` devolve até o primeiro
`PUT` (sugestão: descanso de 90 s e meta de cardio 0, ou seja, sem meta).

```csharp
public sealed class UserProfile : IUserOwned
{
    public Guid UserId { get; private set; }
    public int? HeightCm { get; private set; }
    public int WeeklyCardioGoalMinutes { get; private set; } = 0;
    public int DefaultRestSeconds { get; private set; } = 90;
    public string TimeZone { get; private set; } = "America/Sao_Paulo";

    private UserProfile() { }

    public UserProfile(Guid userId) => UserId = userId;

    public void Update(int? heightCm, int weeklyCardioGoalMinutes, int defaultRestSeconds, string timeZone)
    {
        // regras: descanso positivo, meta não negativa, fuso válido...
    }
}
```

**Exercise** — `UserId` nulo é exercício global. Não implementa `IUserOwned` porque o `UserId` é
opcional; o filtro dele é escrito à parte.

```csharp
public sealed class Exercise : EntityBase
{
    public Guid? UserId { get; private set; }
    public string Name { get; private set; } = null!;
    public MuscleGroup MuscleGroup { get; private set; }
    public bool IsArchived { get; private set; }

    public bool IsGlobal => UserId is null;

    private Exercise() { }

    public Exercise(Guid? userId, string name, MuscleGroup muscleGroup) { /* ... */ }

    public void Rename(string name, MuscleGroup muscleGroup)
    {
        if (IsGlobal)
            throw new DomainException("Exercícios globais não podem ser alterados.");
        // ...
    }

    public void Archive() { /* mesma checagem de IsGlobal */ }
}
```

**Workout** — raiz do agregado `Workout → WorkoutExercise → PlannedSet`. Quem mexe nos filhos é o
`Workout`; ninguém faz `new WorkoutExercise` fora dele.

```csharp
public sealed class Workout : EntityBase, IUserOwned
{
    private readonly List<WorkoutExercise> _exercises = [];

    public Guid UserId { get; private set; }
    public string Name { get; private set; } = null!;
    public DaysOfWeek DaysOfWeek { get; private set; }
    public bool IsArchived { get; private set; }

    public IReadOnlyCollection<WorkoutExercise> Exercises => _exercises;

    private Workout() { }

    public Workout(Guid userId, string name, DaysOfWeek daysOfWeek) { /* ... */ }

    public WorkoutExercise AddExercise(long exerciseId, int? restSeconds)
    {
        var item = new WorkoutExercise(UserId, exerciseId, order: _exercises.Count + 1, restSeconds);
        _exercises.Add(item);
        return item;
    }

    // Para o Update: o jeito mais simples é limpar e remontar a lista de exercícios.
    public void ClearExercises() => _exercises.Clear();

    public void Archive() => IsArchived = true;
}
```

**WorkoutExercise** e **PlannedSet** — construtores `internal`, para só o agregado criá-los. Note o
`UserId` copiado do pai: o planejamento pede `UserId` em toda entidade de usuário.

```csharp
public sealed class WorkoutExercise : EntityBase, IUserOwned
{
    private readonly List<PlannedSet> _plannedSets = [];

    public Guid UserId { get; private set; }
    public long WorkoutId { get; private set; }
    public long ExerciseId { get; private set; }
    public int Order { get; private set; }
    public int? RestSeconds { get; private set; }

    public Exercise Exercise { get; private set; } = null!;   // navegação, para mostrar o nome
    public IReadOnlyCollection<PlannedSet> PlannedSets => _plannedSets;

    private WorkoutExercise() { }

    internal WorkoutExercise(Guid userId, long exerciseId, int order, int? restSeconds) { /* ... */ }

    public void AddPlannedSet(int quantity, SetType setType, int targetRepsMin, int? targetRepsMax)
    {
        _plannedSets.Add(new PlannedSet(UserId, _plannedSets.Count + 1, quantity, setType, targetRepsMin, targetRepsMax));
    }
}
```

```csharp
public sealed class PlannedSet : EntityBase, IUserOwned
{
    public Guid UserId { get; private set; }
    public long WorkoutExerciseId { get; private set; }
    public int Order { get; private set; }
    public int Quantity { get; private set; }
    public SetType SetType { get; private set; }
    public int TargetRepsMin { get; private set; }
    public int? TargetRepsMax { get; private set; }   // nulo = número único

    public bool IsRange => TargetRepsMax is not null;

    private PlannedSet() { }

    internal PlannedSet(Guid userId, int order, int quantity, SetType setType, int targetRepsMin, int? targetRepsMax)
    {
        if (targetRepsMax is not null && targetRepsMax <= targetRepsMin)
            throw new DomainException("O máximo da faixa de repetições deve ser maior que o mínimo.");
        // ...
    }
}
```

> O validator da `Application` também checa a faixa. A checagem aqui não é repetição à toa: o
> validator protege a entrada da API; a entidade protege a regra, venha a chamada de onde vier.

**WorkoutSession** — chega pronta do app (o treino roda offline e é enviado ao finalizar). O
método de fábrica recebe tudo e calcula duração e volume.

```csharp
public sealed class WorkoutSession : EntityBase, IUserOwned
{
    private readonly List<SessionSet> _sets = [];

    public Guid UserId { get; private set; }
    public Guid ClientId { get; private set; }
    public long WorkoutId { get; private set; }
    public DateTimeOffset StartedAt { get; private set; }
    public DateTimeOffset FinishedAt { get; private set; }
    public int DurationSeconds { get; private set; }
    public decimal TotalVolumeKg { get; private set; }

    public IReadOnlyCollection<SessionSet> Sets => _sets;

    private WorkoutSession() { }

    public static WorkoutSession Register(
        Guid userId, Guid clientId, long workoutId,
        DateTimeOffset startedAt, DateTimeOffset finishedAt)
    {
        if (finishedAt <= startedAt)
            throw new DomainException("O fim do treino deve ser depois do início.");

        return new WorkoutSession
        {
            UserId = userId,
            ClientId = clientId,
            WorkoutId = workoutId,
            StartedAt = startedAt,
            FinishedAt = finishedAt,
            DurationSeconds = (int)(finishedAt - startedAt).TotalSeconds
        };
    }

    public SessionSet AddSet(long exerciseId, long? plannedSetId, SetType setType,
                             decimal weightKg, int reps, DateTimeOffset completedAt)
    {
        var set = new SessionSet(UserId, exerciseId, plannedSetId, _sets.Count + 1, setType, weightKg, reps, completedAt);
        _sets.Add(set);

        if (setType.CountsAsVolume())
            TotalVolumeKg += weightKg * reps;

        return set;
    }
}
```

**SessionSet** — guarda o retrato da série no momento da execução (exercício, tipo, carga,
repetições). Editar a ficha depois não muda o passado. Por isso `PlannedSetId` é só uma referência,
sem FK: remontar a ficha apaga `PlannedSet`, e o histórico continua.

```csharp
public sealed class SessionSet : EntityBase, IUserOwned
{
    public Guid UserId { get; private set; }
    public long WorkoutSessionId { get; private set; }
    public long ExerciseId { get; private set; }
    public long? PlannedSetId { get; private set; }   // nulo = série extra; sem FK e sem navegação
    public int Order { get; private set; }
    public SetType SetType { get; private set; }
    public decimal WeightKg { get; private set; }
    public int Reps { get; private set; }
    public DateTimeOffset CompletedAt { get; private set; }
    public bool IsPersonalRecord { get; private set; }

    private SessionSet() { }

    internal SessionSet(/* ... */) { /* ... */ }

    public void MarkAsPersonalRecord() => IsPersonalRecord = true;
}
```

**ApiLog** — registro técnico de uma requisição. Não implementa `IUserOwned` e não tem filtro global
nem FK para o usuário: o log sobrevive ao usuário e pode ser anônimo. O uso está na
[seção 8](#8-log-de-requisições-em-banco).

```csharp
public sealed class ApiLog : EntityBase
{
    public const int MaxTraceIdLength = 128;
    public const int MaxMethodLength = 32;
    public const int MaxUrlPartLength = 2048;

    public string TraceId { get; private set; } = null!;
    public DateTimeOffset OccurredAt { get; private set; }
    public string Method { get; private set; } = null!;
    public string Path { get; private set; } = null!;
    public string? QueryString { get; private set; }
    public int StatusCode { get; private set; }
    public long ElapsedMs { get; private set; }
    public Guid? UserId { get; private set; }
    public string? RequestBody { get; private set; }
    public string? ResponseBody { get; private set; }
    public string? ExceptionMessage { get; private set; }
    public string? StackTrace { get; private set; }
    public bool IsError { get; private set; }

    private ApiLog() { }

    public static ApiLog Create(
        string traceId, DateTimeOffset occurredAt, string method, string path, string? queryString,
        int statusCode, long elapsedMs, Guid? userId, string? requestBody, string? responseBody,
        Exception? exception)
    {
        return new ApiLog
        {
            // URL vem de fora, com qualquer tamanho. Sem o corte, um robô com URL enorme derrubaria
            // o lote inteiro no SaveChanges, junto com os registros bons.
            TraceId = Cut(traceId, MaxTraceIdLength),
            Method = Cut(method, MaxMethodLength),
            Path = Cut(path, MaxUrlPartLength),
            QueryString = queryString is null ? null : Cut(queryString, MaxUrlPartLength),
            OccurredAt = occurredAt,
            StatusCode = statusCode,
            ElapsedMs = elapsedMs,
            UserId = userId,
            RequestBody = requestBody,
            ResponseBody = responseBody,
            ExceptionMessage = exception?.Message,
            StackTrace = exception?.StackTrace,
            IsError = exception is not null || statusCode >= 400
        };
    }

    private static string Cut(string value, int maxLength) =>
        value.Length <= maxLength ? value : value[..maxLength];
}
```

---

## 4. Application

### Abstrações

```csharp
namespace ProjetoAcademiaAPI.Application.Abstractions;

public interface ICurrentUser
{
    Guid UserId { get; }
}

public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
```

### Repositórios

Um por agregado. Repare no que **não** existe: nenhum método recebe `userId`. O filtro global do
`DbContext` já restringe ao usuário atual; o repositório não precisa (nem deve) saber disso.

```csharp
public interface IWorkoutRepository
{
    Task<Workout?> GetByIdAsync(long id, CancellationToken ct);              // com exercícios e séries
    Task<IReadOnlyList<Workout>> ListActiveAsync(CancellationToken ct);
    void Add(Workout workout);
}

public interface IExerciseRepository
{
    Task<Exercise?> GetByIdAsync(long id, CancellationToken ct);
    Task<bool> AllExistAsync(IEnumerable<long> ids, CancellationToken ct);   // valida ids vindos da ficha/sessão
    Task<PagedResponse<Exercise>> ListAsync(string? search, MuscleGroup? muscleGroup, PaginationParameters paging, CancellationToken ct);
    void Add(Exercise exercise);
}

public interface IWorkoutSessionRepository
{
    Task<WorkoutSession?> GetByIdAsync(long id, CancellationToken ct);
    Task<WorkoutSession?> GetByClientIdAsync(Guid clientId, CancellationToken ct);   // idempotência
    Task<IReadOnlyDictionary<long, ExerciseBest>> GetBestSetsAsync(IEnumerable<long> exerciseIds, CancellationToken ct);
    void Add(WorkoutSession session);
}
```

`ExerciseBest` é um modelo de leitura da `Application` (não é entidade):

```csharp
// Melhor série já registrada de um exercício: maior carga e, nessa carga, mais repetições.
public sealed record ExerciseBest(long ExerciseId, decimal WeightKg, int Reps);
```

Os outros (`IUserProfileRepository`, `IWeightEntryRepository`, `ICardioSessionRepository`) seguem o
mesmo molde. `Add` é síncrono de propósito: ele só marca a entidade no `DbContext`; quem vai ao
banco é o `IUnitOfWork.SaveChangesAsync`. `IApiLogRepository` está na
[seção 8](#8-log-de-requisições-em-banco).

### Paginação

Paginam `exercises`, `weight-entries`, `workout-sessions`, `cardio-sessions` e `admin/logs`. Não
paginam `workouts` (são poucas fichas), `exercises/{id}/progress` e `dashboard`.

```csharp
namespace ProjetoAcademiaAPI.Application.Common;

public sealed class PaginationParameters
{
    private const int MaxPageSize = 100;

    // Maior Page cujo (Page - 1) * PageSize ainda cabe em int.
    private const int MaxPage = int.MaxValue / MaxPageSize;

    private int _page = 1;
    private int _pageSize = 20;

    public int Page
    {
        get => _page;
        set => _page = Math.Clamp(value, 1, MaxPage);
    }

    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = Math.Clamp(value, 1, MaxPageSize);
    }
}
```

Parte do `PaginationParameters` dos exemplos, com uma correção: lá o setter só barra o teto, e
`pageSize=0` ou `pageNumber=-1` chegam ao banco. `Skip` negativo vira exceção, e o cliente vê um 500
por um parâmetro de URL. Aqui o setter limita nos dois lados, e o teto de `Page` evita o mesmo
problema por estouro de `int`.

```csharp
public sealed record PagedResponse<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount)
{
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);

    public bool HasNextPage => Page < TotalPages;

    // O repositório devolve entidades; o caso de uso converte sem refazer os totais:
    // page.Map(e => e.ToResponse())
    public PagedResponse<TResult> Map<TResult>(Func<T, TResult> map) =>
        new([.. Items.Select(map)], Page, PageSize, TotalCount);
}
```

A paginação vai no corpo, sem header `X-Pagination` e sem pacote `X.PagedList`, que é o contrato do
planejamento. A extensão que executa a consulta fica na [seção 5](#5-infra).

> **Risco a lembrar no front:** com o máximo de 100 por página, montar o cache offline do catálogo de
> exercícios exige buscar várias páginas, seguindo `hasNextPage`.

### Requests e Responses

`record` com `init` serve bem para os dois: são imutáveis e o model binding funciona.

```csharp
public sealed record CreateWorkoutRequest(
    string Name,
    DaysOfWeek DaysOfWeek,
    IReadOnlyList<WorkoutExerciseRequest> Exercises);

public sealed record WorkoutExerciseRequest(
    long ExerciseId,
    int? RestSeconds,
    IReadOnlyList<PlannedSetRequest> PlannedSets);

public sealed record PlannedSetRequest(
    int Quantity,
    SetType SetType,
    int TargetRepsMin,
    int? TargetRepsMax);
```

```csharp
public sealed record WorkoutResponse(
    long Id,
    string Name,
    DaysOfWeek DaysOfWeek,
    IReadOnlyList<WorkoutExerciseResponse> Exercises);

public sealed record WorkoutExerciseResponse(
    long Id,
    long ExerciseId,
    string ExerciseName,
    int Order,
    int? RestSeconds,
    IReadOnlyList<PlannedSetResponse> PlannedSets);
```

### Validator

```csharp
public sealed class CreateWorkoutRequestValidator : AbstractValidator<CreateWorkoutRequest>
{
    public CreateWorkoutRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Informe o nome do treino.")
            .MaximumLength(100).WithMessage("O nome deve ter no máximo 100 caracteres.");

        RuleFor(x => x.Exercises)
            .NotEmpty().WithMessage("Adicione ao menos um exercício.");

        RuleForEach(x => x.Exercises).ChildRules(exercise =>
        {
            exercise.RuleFor(e => e.RestSeconds)
                .GreaterThan(0).When(e => e.RestSeconds is not null)
                .WithMessage("O descanso deve ser maior que zero.");

            exercise.RuleForEach(e => e.PlannedSets).ChildRules(set =>
            {
                set.RuleFor(s => s.Quantity).GreaterThan(0);
                set.RuleFor(s => s.TargetRepsMin).GreaterThan(0);
                set.RuleFor(s => s.TargetRepsMax)
                    .GreaterThan(s => s.TargetRepsMin)
                    .When(s => s.TargetRepsMax is not null)
                    .WithMessage("O máximo da faixa deve ser maior que o mínimo.");
            });
        });
    }
}
```

### Mapping (manual)

Uma classe estática por entidade principal da feature, em
`Features/<Feature>/Mappings/<Entidade>Mappings.cs`, com extensões `ToResponse()`. É o estilo do
`DTOMapper` do ControleBacklogs, só que por feature, para o arquivo não virar um depósito.

```csharp
namespace ProjetoAcademiaAPI.Application.Features.Workouts.Mappings;

public static class WorkoutMappings
{
    public static WorkoutResponse ToResponse(this Workout workout) => new(
        workout.Id,
        workout.Name,
        workout.DaysOfWeek,
        [.. workout.Exercises.OrderBy(e => e.Order).Select(e => e.ToResponse())]);

    public static WorkoutSummaryResponse ToSummaryResponse(this Workout workout) => new(
        workout.Id,
        workout.Name,
        workout.DaysOfWeek);

    // Exige a navegação Exercise carregada: ver a nota sobre ExerciseName, mais abaixo.
    public static WorkoutExerciseResponse ToResponse(this WorkoutExercise item) => new(
        item.Id,
        item.ExerciseId,
        item.Exercise.Name,
        item.Order,
        item.RestSeconds,
        [.. item.PlannedSets.OrderBy(s => s.Order).Select(s => s.ToResponse())]);

    public static PlannedSetResponse ToResponse(this PlannedSet set) => new(
        set.Id,
        set.Order,
        set.Quantity,
        set.SetType,
        set.TargetRepsMin,
        set.TargetRepsMax);
}
```

Por que à mão: com `record` posicional, um campo novo na response quebra a compilação aqui, em vez
de sair vazio em produção. E não há reflexão nem configuração para investigar quando o valor vem
errado: o mapeamento é código que você lê.

O mapeamento roda em memória, depois da consulta. O EF não traduz uma extensão dessas para SQL, então
consulta que precisa projetar colunas usa `Select` no repositório, como a lista de logs da
[seção 8](#8-log-de-requisições-em-banco).

Mapeie só **entidade → response**. O caminho contrário (request → entidade) fica no caso de uso, pelo
construtor e pelos métodos da entidade, para os `set` privados e as regras continuarem valendo. Um
`ToEntity()` genérico abriria um segundo jeito de criar entidade sem passar por elas.

### Caso de uso — exemplo simples

```csharp
public sealed class CreateWorkoutUseCase(
    IWorkoutRepository workouts,
    IExerciseRepository exercises,
    IUnitOfWork unitOfWork,
    ICurrentUser currentUser,
    IValidator<CreateWorkoutRequest> validator)
{
    public async Task<WorkoutResponse> ExecuteAsync(CreateWorkoutRequest request, CancellationToken ct)
    {
        // 1. Validação de entrada sempre primeiro (lança ValidationException → 400)
        await validator.ValidateAndThrowAsync(request, ct);

        // 2. Regras que dependem do banco
        var exerciseIds = request.Exercises.Select(e => e.ExerciseId).Distinct();
        if (!await exercises.AllExistAsync(exerciseIds, ct))
            throw new NotFoundException("Um ou mais exercícios não foram encontrados.");

        // 3. Monta o agregado pela entidade
        var workout = new Workout(currentUser.UserId, request.Name, request.DaysOfWeek);
        foreach (var item in request.Exercises)
        {
            var workoutExercise = workout.AddExercise(item.ExerciseId, item.RestSeconds);
            foreach (var set in item.PlannedSets)
                workoutExercise.AddPlannedSet(set.Quantity, set.SetType, set.TargetRepsMin, set.TargetRepsMax);
        }

        // 4. Persiste
        workouts.Add(workout);
        await unitOfWork.SaveChangesAsync(ct);

        // 5. Recarrega antes de mapear, para a navegação Exercise vir preenchida
        var saved = await workouts.GetByIdAsync(workout.Id, ct);
        return saved!.ToResponse();
    }
}
```

> Atenção ao `ExerciseName` na resposta: logo após o `Add`, a navegação `Exercise` dos itens está
> vazia. Como ela é declarada com `= null!`, o compilador não avisa, e `ToResponse()` daria
> `NullReferenceException` ao ler `item.Exercise.Name`. Por isso o caso de uso recarrega o treino com
> `GetByIdAsync` antes de mapear.

### Caso de uso — perfil com valores padrão

O `/register` do `MapIdentityApi` cria só o usuário do Identity, não o `UserProfile`. Até o primeiro
`PUT`, não existe linha no banco, e o `GET` devolve os padrões sem gravar nada. Quem cria a linha é o
`UpsertProfileUseCase`.

```csharp
public sealed class GetProfileUseCase(IUserProfileRepository profiles, ICurrentUser currentUser)
{
    public async Task<UserProfileResponse> ExecuteAsync(CancellationToken ct)
    {
        var profile = await profiles.GetAsync(ct) ?? new UserProfile(currentUser.UserId);
        return profile.ToResponse();
    }
}
```

### Caso de uso — o mais interessante: registrar a sessão

`RegisterWorkoutSessionUseCase` junta três regras do planejamento: idempotência pelo `ClientId`,
cálculo de volume (na entidade) e recorde pessoal.

```csharp
public sealed class RegisterWorkoutSessionUseCase(/* repositórios, uow, currentUser, validator */)
{
    public async Task<WorkoutSessionResponse> ExecuteAsync(RegisterWorkoutSessionRequest request, CancellationToken ct)
    {
        await validator.ValidateAndThrowAsync(request, ct);

        // Idempotência: reenvio do mesmo ClientId devolve o que já foi gravado.
        var existing = await sessions.GetByClientIdAsync(request.ClientId, ct);
        if (existing is not null)
            return existing.ToResponse();

        // (checar se o treino e os exercícios existem; PlannedSetId não se checa, ver a nota abaixo)

        var session = WorkoutSession.Register(
            currentUser.UserId, request.ClientId, request.WorkoutId,
            request.StartedAt, request.FinishedAt);

        foreach (var s in request.Sets.OrderBy(s => s.CompletedAt))
            session.AddSet(s.ExerciseId, s.PlannedSetId, s.SetType, s.WeightKg, s.Reps, s.CompletedAt);

        // Recorde pessoal: busca o melhor histórico ANTES de gravar esta sessão.
        var exerciseIds = session.Sets.Select(s => s.ExerciseId).Distinct();
        var bests = await sessions.GetBestSetsAsync(exerciseIds, ct);
        PersonalRecordCalculator.Apply(session, bests);

        sessions.Add(session);

        try
        {
            await unitOfWork.SaveChangesAsync(ct);
        }
        catch (ConflictException)
        {
            // Dois envios simultâneos passaram juntos pela checagem acima, e o índice único barrou
            // o segundo. Para o app é um reenvio normal: devolve a sessão que ganhou a corrida.
            var saved = await sessions.GetByClientIdAsync(request.ClientId, ct);
            if (saved is null)
                throw;

            return saved.ToResponse();
        }

        return session.ToResponse();   // a resposta traz os PRs do dia
    }
}
```

> O `GetByClientIdAsync` precisa trazer as séries, porque `ToResponse()` lê `session.Sets`.

> `ConflictException` aqui, e não `DbUpdateException`, porque a `Application` não enxerga EF Core. Quem
> faz a tradução é o `SaveChangesAsync` do `AppDbContext`, na [seção 5](#5-infra).

> **`PlannedSetId` não é validado.** Ele não tem FK: remontar a ficha apaga `PlannedSet`, e uma sessão
> feita offline pode chegar depois disso com um id que já não existe. Recusar o envio perderia o
> treino do usuário. O valor fica guardado como referência informativa.

O cálculo do PR merece uma classe própria, sem dependência nenhuma — fica fácil de testar:

```csharp
public static class PersonalRecordCalculator
{
    public static void Apply(WorkoutSession session, IReadOnlyDictionary<long, ExerciseBest> history)
    {
        // Cópia mutável: uma série que bate o recorde vira a nova referência para as seguintes.
        var bests = history.ToDictionary(kv => kv.Key, kv => kv.Value);

        foreach (var set in session.Sets.Where(s => s.SetType.CountsAsVolume()))
        {
            if (!bests.TryGetValue(set.ExerciseId, out var best))
            {
                // Primeira vez do exercício: não é PR, mas passa a ser a referência.
                bests[set.ExerciseId] = new ExerciseBest(set.ExerciseId, set.WeightKg, set.Reps);
                continue;
            }

            var isRecord = set.WeightKg > best.WeightKg
                        || (set.WeightKg == best.WeightKg && set.Reps > best.Reps);

            if (isRecord)
            {
                set.MarkAsPersonalRecord();
                bests[set.ExerciseId] = new ExerciseBest(set.ExerciseId, set.WeightKg, set.Reps);
            }
        }
    }
}
```

> Esta versão considera também as séries anteriores **da mesma sessão** (ver [ponto 12.1](#121-pr-dentro-da-mesma-sessão)).
> Ela poderia morar no `Domain` (é regra pura); na `Application` fica perto do caso de uso. Escolha
> sua.

### DependencyInjection.cs da Application

```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        // Mensagens padrão do FluentValidation em português. As que você escreve com WithMessage
        // já estão; esta linha cobre o resto (NotEmpty sem mensagem, por exemplo).
        ValidatorOptions.Global.LanguageManager.Culture = new CultureInfo("pt-BR");

        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        // Casos de uso: um por linha. Sem MediatR, o registro é explícito.
        services.AddScoped<CreateWorkoutUseCase>();
        services.AddScoped<RegisterWorkoutSessionUseCase>();
        // ...

        return services;
    }
}
```

`IServiceCollection` chega pelo pacote `FluentValidation.DependencyInjectionExtensions`, que a
`Application` já referencia. Não precisa de pacote de DI separado.

---

## 5. Infra

### AppDbContext

Herdando de `IdentityDbContext` com `Guid` como chave, as tabelas do Identity e as suas ficam no
mesmo contexto (e na mesma migration).

```csharp
public sealed class AppDbContext(DbContextOptions<AppDbContext> options, ICurrentUser currentUser)
    : IdentityDbContext<IdentityUser<Guid>, IdentityRole<Guid>, Guid>(options), IUnitOfWork
{
    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<WeightEntry> WeightEntries => Set<WeightEntry>();
    public DbSet<Exercise> Exercises => Set<Exercise>();
    public DbSet<Workout> Workouts => Set<Workout>();
    public DbSet<WorkoutSession> WorkoutSessions => Set<WorkoutSession>();
    public DbSet<SessionSet> SessionSets => Set<SessionSet>();
    public DbSet<CardioSession> CardioSessions => Set<CardioSession>();
    public DbSet<ApiLog> ApiLogs => Set<ApiLog>();

    // O filtro precisa ler uma propriedade do próprio DbContext: assim o EF reavalia o valor a cada
    // consulta. Se capturasse o Guid direto, o primeiro usuário ficaria "congelado" no modelo.
    private Guid CurrentUserId => currentUser.UserId;

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);   // obrigatório: configura as tabelas do Identity

        builder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // Filtro por usuário em toda entidade IUserOwned
        foreach (var entityType in builder.Model.GetEntityTypes()
                     .Where(t => typeof(IUserOwned).IsAssignableFrom(t.ClrType)))
        {
            GetType()
                .GetMethod(nameof(ApplyUserFilter), BindingFlags.NonPublic | BindingFlags.Instance)!
                .MakeGenericMethod(entityType.ClrType)
                .Invoke(this, [builder]);
        }

        // Exercise: os do usuário + os globais
        builder.Entity<Exercise>()
            .HasQueryFilter(e => e.UserId == CurrentUserId || e.UserId == null);
    }

    private void ApplyUserFilter<T>(ModelBuilder builder) where T : class, IUserOwned =>
        builder.Entity<T>().HasQueryFilter(e => e.UserId == CurrentUserId);

    // A Application não enxerga EF Core, então a violação de índice único sai daqui como uma
    // exceção de domínio. 2601 e 2627 são os códigos do SQL Server para chave duplicada.
    // É este overload que o SaveChangesAsync(CancellationToken) chama por dentro.
    public override async Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        try
        {
            return await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
        }
        catch (DbUpdateException ex) when (ex.InnerException is SqlException { Number: 2601 or 2627 })
        {
            throw new ConflictException("Registro duplicado.");
        }
    }
}
```

> Se a reflexão incomodar, a alternativa é escrever um `HasQueryFilter` por entidade — são sete
> linhas, e fica explícito.

`ApiLog` não implementa `IUserOwned`, então fica fora do filtro. É isso que permite ao worker do log
gravar num escopo sem usuário.

### Uma Configuration

```csharp
public sealed class WorkoutConfiguration : IEntityTypeConfiguration<Workout>
{
    public void Configure(EntityTypeBuilder<Workout> builder)
    {
        builder.ToTable("workouts");   // com NamingConventions isso já sairia sozinho
        builder.HasKey(w => w.Id);

        builder.Property(w => w.Name).HasMaxLength(100).IsRequired();
        builder.Property(w => w.DaysOfWeek).HasConversion<string>().HasMaxLength(100);

        builder.HasMany(w => w.Exercises)
            .WithOne()
            .HasForeignKey(e => e.WorkoutId)
            .OnDelete(DeleteBehavior.Cascade);

        // FK para o usuário do Identity sem navegação no Domain
        builder.HasOne<IdentityUser<Guid>>()
            .WithMany()
            .HasForeignKey(w => w.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
```

Outras configurações que valem lembrar:

| Entidade | Detalhe |
|---|---|
| `UserProfile` | `HasKey(p => p.UserId)` |
| `WeightEntry` | `RecordedOn` é `DateOnly` → `date`; `WeightKg` com `HasPrecision(6, 2)`; índice único em `(UserId, RecordedOn)` se for um peso por dia |
| `WorkoutSession` / `CardioSession` | `HasIndex(s => new { s.UserId, s.ClientId }).IsUnique()` — é o que garante a idempotência |
| `Exercise` | `Name` com `.UseCollation("Latin1_General_CI_AI")`, para `search=biceps` achar `Bíceps` |
| `SessionSet` | `WeightKg` com `HasPrecision(6, 2)`; índice em `(UserId, ExerciseId)` para o histórico e o PR; `PlannedSetId` como coluna simples, sem `HasOne` |
| `ApiLog` | tabela `api_logs`, índice em `OccurredAt`, sem FK; detalhes na [seção 8](#8-log-de-requisições-em-banco) |
| enums | `HasConversion<string>()` com `HasMaxLength` |
| FKs para `Exercise` | `DeleteBehavior.Restrict` — exercício nunca é apagado, só arquivado |

> **Cascata múltipla no SQL Server:** `SessionSet` chega em `asp_net_users` por dois caminhos (direto
> e via `WorkoutSession`). O SQL Server recusa dois caminhos de cascata até a mesma tabela. Nas
> entidades filhas, deixe a FK do usuário com `DeleteBehavior.NoAction` (ou `Restrict`) e a cascata
> só pela raiz.

> **`SessionSet.PlannedSetId` fica fora dessa conta, porque não tem FK.** Remontar a ficha apaga
> `PlannedSet`. Com FK, isso falharia (ou apagaria histórico, com cascata) e quebraria o envio de uma
> sessão offline que ainda aponta para a série antiga. Sem FK, o id antigo só deixa de ter
> correspondente, e o histórico não depende dele.

### Um Repository

```csharp
public sealed class WorkoutRepository(AppDbContext context) : IWorkoutRepository
{
    public Task<Workout?> GetByIdAsync(long id, CancellationToken ct) =>
        context.Workouts
            .Include(w => w.Exercises.OrderBy(e => e.Order))
                .ThenInclude(e => e.PlannedSets.OrderBy(s => s.Order))
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Exercise)
            .AsSplitQuery()
            .FirstOrDefaultAsync(w => w.Id == id, ct);

    public async Task<IReadOnlyList<Workout>> ListActiveAsync(CancellationToken ct) =>
        await context.Workouts
            .AsNoTracking()
            .Where(w => !w.IsArchived)
            .OrderBy(w => w.Name)
            .ToListAsync(ct);

    public void Add(Workout workout) => context.Workouts.Add(workout);
}
```

Repare: nenhum `Where(w => w.UserId == ...)`. O filtro global já faz isso.

### Paginação na consulta

Uma extensão, usada por todo repositório que pagina. Mesma receita do `BacklogRepository`: `Count`
primeiro e `Skip`/`Take` depois, sem pacote externo.

```csharp
// Persistence/QueryableExtensions.cs
internal static class QueryableExtensions
{
    public static async Task<PagedResponse<T>> ToPagedResponseAsync<T>(
        this IQueryable<T> query, PaginationParameters paging, CancellationToken ct)
    {
        var totalCount = await query.CountAsync(ct);

        var items = await query
            .Skip((paging.Page - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .ToListAsync(ct);

        return new PagedResponse<T>(items, paging.Page, paging.PageSize, totalCount);
    }
}
```

A ordenação vem do repositório, fixa por endpoint:

```csharp
public sealed class ExerciseRepository(AppDbContext context) : IExerciseRepository
{
    public Task<PagedResponse<Exercise>> ListAsync(
        string? search, MuscleGroup? muscleGroup, PaginationParameters paging, CancellationToken ct)
    {
        var query = context.Exercises.AsNoTracking().Where(e => !e.IsArchived);

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(e => e.Name.Contains(search));

        if (muscleGroup is not null)
            query = query.Where(e => e.MuscleGroup == muscleGroup);

        return query
            .OrderBy(e => e.Name)
            .ThenBy(e => e.Id)
            .ToPagedResponseAsync(paging, ct);
    }

    // ...
}
```

O `ThenBy(e => e.Id)` é o que torna a ordem estável. Com dois exercícios de mesmo nome, o SQL Server
pode devolvê-los em ordem diferente a cada consulta, e um item apareceria em duas páginas ou em
nenhuma.

| Endpoint | Ordem |
|---|---|
| `exercises` | `Name`, `Id` |
| `weight-entries` | `RecordedOn` desc, `Id` desc |
| `workout-sessions` | `StartedAt` desc, `Id` desc |
| `cardio-sessions` | `StartedAt` desc, `Id` desc |
| `admin/logs` | `OccurredAt` desc, `Id` desc |

### Seed dos exercícios globais

O catálogo global é fixo e versionado junto com o código — `HasData` encaixa bem:

```csharp
// Persistence/Seed/GlobalExercises.cs
internal static class GlobalExercises
{
    public static readonly object[] Data =
    [
        new { Id = 1L, UserId = (Guid?)null, Name = "Supino reto", MuscleGroup = MuscleGroup.Chest, IsArchived = false },
        new { Id = 2L, UserId = (Guid?)null, Name = "Agachamento livre", MuscleGroup = MuscleGroup.Quadriceps, IsArchived = false },
        // ...
    ];
}

// Na ExerciseConfiguration:
builder.HasData(GlobalExercises.Data);
```

Objetos anônimos evitam abrir um construtor público só para o seed. Cada mudança na lista gera uma
migration.

### DependencyInjection.cs da Infra

```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddInfra(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<AppDbContext>(options => options
            .UseSqlServer(
                configuration.GetConnectionString("Default"),
                sql => sql.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null))
            .UseSnakeCaseNamingConvention());

        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<AppDbContext>());

        services.AddScoped<IWorkoutRepository, WorkoutRepository>();
        services.AddScoped<IExerciseRepository, ExerciseRepository>();
        services.AddScoped<IApiLogRepository, ApiLogRepository>();
        // ...

        return services;
    }
}
```

`IUnitOfWork` aponta para a **mesma instância** de `AppDbContext` do escopo — por isso a fábrica, e
não `AddScoped<IUnitOfWork, AppDbContext>()` (que criaria um segundo contexto).

O motivo do `EnableRetryOnFailure` está na [seção 7](#ef-core-e-azure-sql).

---

## 6. Api

### CurrentUser

```csharp
public sealed class CurrentUser(IHttpContextAccessor accessor) : ICurrentUser
{
    public Guid UserId
    {
        get
        {
            var value = accessor.HttpContext?.User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("Usuário não autenticado.");
            return Guid.Parse(value);
        }
    }
}
```

O valor só é lido quando uma consulta usa o filtro. Nos endpoints do Identity (login, registro), que
não tocam nas suas entidades, ele nunca é chamado.

### Controller

Fino: recebe, chama o caso de uso, devolve. Nenhuma regra aqui. Não precisa de `[Authorize]`: o
`RequireAuthorization()` do `Program.cs` já exige autenticação em todos os controllers.

```csharp
[ApiController]
[Route("api/workouts")]
public sealed class WorkoutsController : ControllerBase
{
    [HttpPost]
    [ProducesResponseType<WorkoutResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(
        [FromBody] CreateWorkoutRequest request,
        [FromServices] CreateWorkoutUseCase useCase,
        CancellationToken ct)
    {
        var response = await useCase.ExecuteAsync(request, ct);
        return CreatedAtAction(nameof(GetById), new { id = response.Id }, response);
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<WorkoutResponse>> GetById(
        long id,
        [FromServices] GetWorkoutByIdUseCase useCase,
        CancellationToken ct) =>
        await useCase.ExecuteAsync(id, ct);
}
```

> `[FromServices]` por ação evita um construtor com dez casos de uso, onde cada requisição criaria
> todos mesmo usando um só.

Uma lista paginada recebe os filtros e a paginação pela query:

```csharp
[HttpGet]
public async Task<ActionResult<PagedResponse<ExerciseResponse>>> List(
    [FromQuery] string? search,
    [FromQuery] MuscleGroup? muscleGroup,
    [FromQuery] PaginationParameters paging,
    [FromServices] ListExercisesUseCase useCase,
    CancellationToken ct) =>
    await useCase.ExecuteAsync(search, muscleGroup, paging, ct);
```

### GlobalExceptionHandler

Faz o papel que o `ErrorHandlingMiddleware` faz nos projetos de exemplo, usando o `IExceptionHandler`
do próprio ASP.NET.

```csharp
internal sealed class GlobalExceptionHandler(
    IProblemDetailsService problemDetailsService,
    ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken ct)
    {
        // Cliente desistiu (o app perdeu sinal, por exemplo). Não é falha do servidor: sem log de
        // erro, sem corpo, e nada para o log em banco registrar como exceção. O RequestAborted separa
        // isso de um cancelamento interno, que é erro de verdade e precisa continuar virando 500.
        if (exception is OperationCanceledException && context.RequestAborted.IsCancellationRequested)
        {
            context.Response.StatusCode = StatusCodes.Status499ClientClosedRequest;
            return true;
        }

        // O RequestLoggingMiddleware fica por fora deste handler e lê a exceção daqui.
        context.SetLoggedException(exception);

        ProblemDetails problem = exception switch
        {
            ValidationException ex => new ValidationProblemDetails(
                ex.Errors
                  .GroupBy(e => e.PropertyName)
                  .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray()))
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Dados inválidos."
            },
            UnauthorizedAccessException => new() { Status = StatusCodes.Status401Unauthorized, Title = "Não autenticado." },
            NotFoundException ex => new() { Status = StatusCodes.Status404NotFound, Title = "Não encontrado.", Detail = ex.Message },
            ConflictException ex => new() { Status = StatusCodes.Status409Conflict, Title = "Conflito.", Detail = ex.Message },
            DomainException ex   => new() { Status = StatusCodes.Status400BadRequest, Title = "Regra violada.", Detail = ex.Message },
            _                    => new() { Status = StatusCodes.Status500InternalServerError, Title = "Erro inesperado." }
        };

        if (problem.Status == StatusCodes.Status500InternalServerError)
            logger.LogError(exception, "Erro não tratado");

        context.Response.StatusCode = problem.Status!.Value;

        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = context,
            ProblemDetails = problem,
            Exception = exception
        });
    }
}
```

Ordem do `switch` importa: `NotFoundException` e `ConflictException` herdam de `DomainException`,
então vêm antes dela.

- **`UnauthorizedAccessException`:** é o que o `CurrentUser` lança sem usuário autenticado. Sem esse
  caso viraria 500.
- **`DbUpdateException`:** não aparece aqui. Violação de índice único chega como `ConflictException`,
  e o envio simultâneo do mesmo `ClientId` nem sobe até o handler: o caso de uso trata e devolve a
  sessão já gravada.
- **`traceId`:** entra uma vez só, em `CustomizeProblemDetails`
  ([seção 7](#7-configuração-aspnet)). Assim vale também para a 429 do rate limiter e para os erros
  gerados pelo `[ApiController]`, e é o mesmo valor gravado em `api_logs`, o que liga o erro que o
  app recebeu ao registro do log.

### Program.cs

As configurações saíram para `AddApiConfiguration` ([seção 7](#7-configuração-aspnet)). No
`Program.cs` fica o que importa ler de uma vez: a ordem do pipeline.

```csharp
var builder = WebApplication.CreateBuilder(args);

// O código continua usando ILogger. O Serilog só assume a saída, lendo a seção "Serilog".
builder.Services.AddSerilog((services, cfg) => cfg
    .ReadFrom.Configuration(builder.Configuration)
    .ReadFrom.Services(services));

// Camadas
builder.Services.AddApplication();
builder.Services.AddInfra(builder.Configuration);

// Assuntos do host: Options, JSON, erros, OpenAPI, Identity, CORS, rate limit, log em banco
builder.Services.AddApiConfiguration(builder.Configuration);

var app = builder.Build();

// 1. Antes de tudo. Atrás do proxy do App Service, a requisição chega como http e com o IP do
//    proxy. Redirecionamento, rate limit por IP e log dependem do valor real.
app.UseForwardedHeaders();

// 2. Por fora de quase tudo, para medir a requisição inteira e registrar o status final.
app.UseSerilogRequestLogging();

// 3. Por fora do exception handler, para enxergar a resposta de erro já formatada. Por dentro,
//    a exceção passaria direto e o middleware não saberia o status.
app.UseMiddleware<RequestLoggingMiddleware>();

// 4. Pega exceção de qualquer ponto abaixo dele.
app.UseExceptionHandler();

// 5. Só fora de Development: em casa o celular acessa a API por http, pela rede local.
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

// 6. Antes do rate limiter, para a 429 levar os headers de CORS. Sem eles o navegador esconde a
//    resposta do front web. Também responde o preflight, que não leva token.
app.UseCors(ApiConfigurationExtensions.CorsPolicy);

// 7. Antes da autenticação, para barrar cedo, sem gastar trabalho com quem já passou do limite.
app.UseRateLimiter();

// 8. Quem é o usuário; depois, o que ele pode fazer.
app.UseAuthentication();
app.UseAuthorization();

// 9. Endpoints
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.MapHealthChecks("/health").AllowAnonymous();

app.MapGroup("/api/auth")
    .RequireRateLimiting(ApiConfigurationExtensions.AuthRateLimitPolicy)
    .MapIdentityApi<IdentityUser<Guid>>();

app.MapControllers().RequireAuthorization();

app.Run();

public partial class Program;   // para o WebApplicationFactory dos testes de integração enxergar
```

O `WebApplication` coloca um `UseRouting` implícito no começo do pipeline. É por isso que
`UseCors`, `UseRateLimiter` e `UseAuthorization` enxergam a política de cada endpoint sem `UseRouting`
explícito.

### Segredos e migrations

```bash
# dentro de src/ProjetoAcademiaAPI.Api
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:Default" "Server=localhost;Database=ProjetoAcademia;..."
```

```bash
# na raiz de ProjetoAcademiaAPI
dotnet ef migrations add Initial -p src/ProjetoAcademiaAPI.Infra -s src/ProjetoAcademiaAPI.Api -o Persistence/Migrations
dotnet ef database update      -p src/ProjetoAcademiaAPI.Infra -s src/ProjetoAcademiaAPI.Api
```

`database update` é só para o banco local. Em produção, ver a [seção 10](#10-deploy).

---

## 7. Configuração ASP.NET

Tudo que é assunto do host mora em `Configuration/ApiConfigurationExtensions.cs`. O método público
chama um método privado por tema, e cada um aparece abaixo com o seu motivo.

```csharp
namespace ProjetoAcademiaAPI.Api.Configuration;

public static class ApiConfigurationExtensions
{
    public const string CorsPolicy = "AllowFrontend";
    public const string AuthRateLimitPolicy = "auth";

    public static IServiceCollection AddApiConfiguration(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddValidatedOptions<ApiLoggingOptions>(ApiLoggingOptions.SectionName);
        services.AddValidatedOptions<AppCorsOptions>(AppCorsOptions.SectionName);
        services.AddValidatedOptions<AuthRateLimitOptions>(AuthRateLimitOptions.SectionName);

        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUser, CurrentUser>();
        services.AddHealthChecks();

        services.AddApiWeb();
        services.AddApiIdentity(configuration);
        services.AddApiCors(configuration);
        services.AddApiForwardedHeaders();
        services.AddApiRateLimiter();
        services.AddApiRequestLogging();

        return services;
    }

    // Os métodos privados estão nas subseções abaixo.
}
```

### Options tipadas

Falha cedo: configuração inválida derruba a API **na subida**, com uma mensagem clara, e não na
primeira requisição que usar o valor.

```csharp
private static void AddValidatedOptions<T>(this IServiceCollection services, string section) where T : class =>
    services.AddOptions<T>()
        .BindConfiguration(section)
        .ValidateDataAnnotations()
        .ValidateOnStart();
```

```csharp
// "Cors" e não "CorsOptions": esse nome já existe no ASP.NET.
public sealed class AppCorsOptions
{
    public const string SectionName = "Cors";

    public string[] AllowedOrigins { get; init; } = [];
}

public sealed class AuthRateLimitOptions
{
    public const string SectionName = "RateLimiting:Auth";

    [Range(1, 10_000)]
    public int PermitLimit { get; init; } = 10;

    [Range(1, 3_600)]
    public int WindowSeconds { get; init; } = 60;
}

public sealed class ApiLoggingOptions
{
    public const string SectionName = "ApiLogging";

    [Range(1, 3_650)]
    public int RetentionDays { get; init; } = 30;

    [Range(1, 1_000_000)]
    public int MaxBodyLength { get; init; } = 4_000;

    public string[] IgnoredPaths { get; init; } = [];

    // Lista vazia gravaria senha e token: melhor a API não subir.
    [MinLength(1)]
    public string[] BodyExcludedPaths { get; init; } = [];
}
```

> `RateLimiting:Auth` é ligada direto à classe porque `ValidateDataAnnotations` não entra em objeto
> aninhado. Com uma classe `RateLimiting` contendo `Auth`, o `[Range]` seria ignorado sem aviso.

### JSON, erros e OpenAPI

```csharp
private static void AddApiWeb(this IServiceCollection services)
{
    // Os dois registros são necessários: AddJsonOptions vale para os controllers, e
    // ConfigureHttpJsonOptions vale para o MapIdentityApi e é o que o OpenAPI lê para descrever
    // os schemas. Só com o primeiro, a API responde "Working" e a documentação diz número.
    services.AddControllers()
        .AddJsonOptions(options => options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

    services.ConfigureHttpJsonOptions(options =>
        options.SerializerOptions.Converters.Add(new JsonStringEnumConverter()));

    services.AddProblemDetails(options => options.CustomizeProblemDetails = context =>
        context.ProblemDetails.Extensions["traceId"] = context.HttpContext.GetTraceId());

    services.AddExceptionHandler<GlobalExceptionHandler>();

    services.AddOpenApi(options => options.AddDocumentTransformer<BearerSecuritySchemeTransformer>());
}
```

Sem o transformer, o Scalar não sabe que a API usa bearer e não oferece onde colar o token. O nome
do esquema no documento é só um rótulo, independente do esquema interno do Identity. Não declare
`BearerFormat = "JWT"`: o token do Identity é opaco, não é JWT.

```csharp
internal sealed class BearerSecuritySchemeTransformer : IOpenApiDocumentTransformer
{
    private const string SchemeName = "Bearer";

    public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken ct)
    {
        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
        document.Components.SecuritySchemes[SchemeName] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer"
        };

        foreach (var operation in document.Paths.Values.SelectMany(path => path.Operations!.Values))
        {
            operation.Security ??= [];
            operation.Security.Add(new OpenApiSecurityRequirement
            {
                [new OpenApiSecuritySchemeReference(SchemeName, document)] = []
            });
        }

        return Task.CompletedTask;
    }
}
```

Para os comentários `///` dos controllers irem para o OpenAPI, no `ProjetoAcademiaAPI.Api.csproj`:

```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
  <NoWarn>$(NoWarn);CS1591</NoWarn>   <!-- sem isso, todo membro público sem /// gera aviso -->
</PropertyGroup>
```

OpenAPI e Scalar só existem em Development: em produção, a API não publica o próprio mapa.

### CORS

```csharp
private static void AddApiCors(this IServiceCollection services, IConfiguration configuration)
{
    var origins = configuration.GetSection(AppCorsOptions.SectionName).Get<AppCorsOptions>()?.AllowedOrigins ?? [];

    services.AddCors(options => options.AddPolicy(CorsPolicy, policy => policy
        .WithOrigins(origins)
        .AllowAnyHeader()
        .AllowAnyMethod()));
}
```

**CORS é regra de navegador.** Quem bloqueia é o navegador, ao ler a resposta. O APK não passa por
ele, então essa política não afeta o app, e também não protege a API: `curl` ou um app qualquer
chama igual. Só serve para o Expo Web e para um eventual cliente web.

- **Sem `AllowCredentials`:** isso existe para cookie. Aqui a auth é bearer, no header
  `Authorization`.
- **Sem `WithExposedHeaders`:** a paginação vai no corpo, não em header. O ControleBacklogs precisa
  dele por causa do `X-Pagination`.
- **Origens:** vazia na base, `http://localhost:8081` (Expo Web) em Development. Em produção, só se
  existir cliente web, por `Cors__AllowedOrigins__0`.

### ForwardedHeaders

```csharp
private static void AddApiForwardedHeaders(this IServiceCollection services) =>
    services.Configure<ForwardedHeadersOptions>(options =>
    {
        options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;

        // Por padrão só proxies em loopback são confiáveis, e o proxy do App Service não é um deles.
        options.KnownIPNetworks.Clear();
        options.KnownProxies.Clear();
    });
```

**Risco:** com as listas limpas, a API confia em qualquer proxy. Se alguém alcançar a API sem passar
pelo App Service, pode forjar o `X-Forwarded-For` e fugir do rate limit por IP. Hoje o App Service é a
única entrada, então o risco é aceitável. Se a hospedagem mudar, reveja.

### Rate limit

```csharp
private static void AddApiRateLimiter(this IServiceCollection services) =>
    services.AddRateLimiter(options =>
    {
        options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

        // Uma janela por IP. Só funciona com o UseForwardedHeaders antes: sem ele, todo mundo
        // teria o IP do proxy e dividiria o mesmo limite.
        options.AddPolicy(AuthRateLimitPolicy, context =>
        {
            var limit = context.RequestServices.GetRequiredService<IOptions<AuthRateLimitOptions>>().Value;

            return RateLimitPartition.GetFixedWindowLimiter(
                partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                factory: _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = limit.PermitLimit,
                    Window = TimeSpan.FromSeconds(limit.WindowSeconds),
                    QueueLimit = 0
                });
        });

        options.OnRejected = async (context, ct) =>
        {
            var http = context.HttpContext;

            if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
                http.Response.Headers.RetryAfter = ((int)retryAfter.TotalSeconds).ToString();

            var problemDetails = http.RequestServices.GetRequiredService<IProblemDetailsService>();
            await problemDetails.TryWriteAsync(new ProblemDetailsContext
            {
                HttpContext = http,
                ProblemDetails = new()
                {
                    Status = StatusCodes.Status429TooManyRequests,
                    Title = "Muitas tentativas.",
                    Detail = "Tente novamente em alguns instantes."
                }
            });
        };
    });
```

A política vale para o grupo `/api/auth` inteiro, inclusive `/refresh`. O limite de 10 por minuto por
IP atende o app com folga: cada aparelho faz um refresh por hora, no máximo.

### EF Core e Azure SQL

O código está em [`DependencyInjection.cs` da Infra](#dependencyinjectioncs-da-infra). Os motivos:

- **`EnableRetryOnFailure(10, 15 s, null)`:** o Azure SQL com auto-pause desliga quando fica ocioso e
  leva de 30 a 60 s para acordar. Enquanto acorda, toda conexão falha. O retry espera, em vez de
  devolver 500 no primeiro acesso do dia.
- **Nada de acesso ao banco na subida:** sem `Migrate()` e sem seed no `Program.cs`. O ControleBacklogs
  tirou o seed do start por afetar a inicialização, e o mesmo vale aqui.
- **`IUnitOfWork` sem transação manual:** com o retry ligado, um `BeginTransaction` solto quebra. Um
  `SaveChanges` já é transacional e o retry sabe repeti-lo. Se um dia precisar de transação explícita,
  ela vai dentro de `CreateExecutionStrategy().ExecuteAsync(...)`.

### Autorização

`app.MapControllers().RequireAuthorization()` exige autenticação em todos os controllers, sem precisar
lembrar de `[Authorize]` em cada um. A exceção se declara com `[AllowAnonymous]`.

**Não use `FallbackPolicy`.** Ela pegaria todo endpoint sem política, inclusive `/login` e `/register`
do `MapIdentityApi`, que não declaram `AllowAnonymous`, e ninguém conseguiria entrar. Por isso a regra
fica só nos controllers.

### Identity

```csharp
private static void AddApiIdentity(this IServiceCollection services, IConfiguration configuration)
{
    services
        .AddIdentityApiEndpoints<IdentityUser<Guid>>(options =>
        {
            // Mínimo de 8, sem exigir maiúscula, número nem símbolo.
            options.Password.RequiredLength = 8;
            options.Password.RequireDigit = false;
            options.Password.RequireLowercase = false;
            options.Password.RequireUppercase = false;
            options.Password.RequireNonAlphanumeric = false;

            options.User.RequireUniqueEmail = true;
        })
        .AddRoles<IdentityRole<Guid>>()   // antes do AddEntityFrameworkStores
        .AddEntityFrameworkStores<AppDbContext>();

    services.Configure<BearerTokenOptions>(IdentityConstants.BearerScheme, options =>
    {
        options.BearerTokenExpiration = TimeSpan.FromMinutes(configuration.GetValue("Auth:BearerTokenMinutes", 60));
        options.RefreshTokenExpiration = TimeSpan.FromDays(configuration.GetValue("Auth:RefreshTokenDays", 30));
    });

    services.AddAuthorizationBuilder()
        .AddPolicy(AuthorizationPolicies.AdminOnly, policy => policy.RequireRole("Admin"));
}
```

```csharp
public static class AuthorizationPolicies
{
    public const string AdminOnly = "AdminOnly";
}
```

**Refresh expirado sem internet não perde a sessão local.** O treino em andamento e as sessões
pendentes estão no SQLite e não dependem do token. Quando a conexão voltar, o app pede login e envia o
que ficou pendente. Por isso 30 dias, e não os 14 do padrão: quem passa duas semanas sem abrir o app
não precisa logar de novo.

### Perfil Admin

`AddRoles` já aparece acima. Sem ele, o Identity não carrega as roles do usuário e a claim não entra
no token, ou seja, `RequireRole("Admin")` nunca passaria.

A role nasce por `HasData`. `Id` e `ConcurrencyStamp` fixos são obrigatórios: sem eles, cada migration
geraria valores novos e tentaria alterar a linha. Gere os seus GUIDs e deixe-os fixos no código.

```csharp
// Persistence/Configurations/IdentityRoleConfiguration.cs
public sealed class IdentityRoleConfiguration : IEntityTypeConfiguration<IdentityRole<Guid>>
{
    public void Configure(EntityTypeBuilder<IdentityRole<Guid>> builder) =>
        builder.HasData(new IdentityRole<Guid>
        {
            Id = new Guid("1f0c3a7e-6f41-4d7a-9c39-0a7e2c5d8b11"),
            Name = "Admin",
            NormalizedName = "ADMIN",
            ConcurrencyStamp = "7d9b1c52-3e0a-4b68-8f21-5c6a4e9d0f37"
        });
}
```

O vínculo com o usuário é manual, por SQL, sem seed na subida. Rode uma vez, depois de se registrar
no app:

```sql
-- Com snake_case, as tabelas do Identity viram asp_net_users, asp_net_user_roles.
-- Confira os nomes na migration gerada antes de rodar.
INSERT INTO asp_net_user_roles (user_id, role_id)
SELECT u.id, '1f0c3a7e-6f41-4d7a-9c39-0a7e2c5d8b11'
FROM asp_net_users u
WHERE u.normalized_email = 'SEU@EMAIL.COM';
```

A role muda no **próximo refresh do token**: é nele que o Identity remonta as claims a partir do
banco. Até lá, o token atual continua sem a claim, então faça login de novo ou espere o refresh.

### Health check

`AddHealthChecks()` sem nenhuma checagem de banco, de propósito: `/health` serve para o App Service
saber que o processo está vivo. Se fosse ao banco, cada verificação acordaria o Azure SQL pausado, que
nunca dormiria. `AllowAnonymous` deixa a rota clara, e `IgnoredPaths` tira a rota do log em banco.

### HTTPS e acesso pelo celular

`UseHsts` e `UseHttpsRedirection` só rodam fora de Development porque o celular acessa a API local por
http, pela rede. Em produção, ative também o **HTTPS Only** do App Service.

O perfil `http` do `launchSettings.json` escuta só em `http://localhost:5290`, e o celular não alcança
`localhost` da sua máquina. Para testar no aparelho, suba escutando em todas as interfaces e aponte
o app para o IP do computador (o firewall do Windows precisa liberar a porta):

```bash
dotnet run --project src/ProjetoAcademiaAPI.Api --urls http://0.0.0.0:5290
```

### Serilog

`AddSerilog` lê tudo da seção `Serilog`, e `UseSerilogRequestLogging` troca as várias linhas de log
por requisição do ASP.NET por uma só, com método, rota, status e tempo. O código não muda: continua
injetando `ILogger<T>`.

A seção `Logging` do `appsettings.json` deixa de ter efeito com o Serilog no lugar. Pode apagar.

Console em todos os ambientes (é o que o App Service captura), JSON em produção e arquivo só em
Development. A pasta `Logs/` já está no `.gitignore` do repo da API.

**Serilog e a tabela `api_logs` são mecanismos separados.** O Serilog é o log operacional, em texto
corrido. A tabela é o diagnóstico consultável pela API ([seção 8](#8-log-de-requisições-em-banco)).

### appsettings

A connection string não aparece em nenhum dos três: ela é segredo.

`appsettings.json`:

```json
{
  "AllowedHosts": "*",
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft.AspNetCore": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" }
    ],
    "Enrich": [ "FromLogContext" ]
  },
  "Cors": {
    "AllowedOrigins": []
  },
  "RateLimiting": {
    "Auth": {
      "PermitLimit": 10,
      "WindowSeconds": 60
    }
  },
  "Auth": {
    "BearerTokenMinutes": 60,
    "RefreshTokenDays": 30
  },
  "ApiLogging": {
    "RetentionDays": 30,
    "MaxBodyLength": 4000,
    "IgnoredPaths": [ "/health", "/openapi", "/scalar" ],
    "BodyExcludedPaths": [ "/api/auth" ]
  }
}
```

`appsettings.Development.json`:

```json
{
  "Serilog": {
    "WriteTo": [
      { "Name": "Console" },
      {
        "Name": "File",
        "Args": {
          "path": "Logs/projeto-academia-.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 7
        }
      }
    ]
  },
  "Cors": {
    "AllowedOrigins": [ "http://localhost:8081" ]
  }
}
```

`appsettings.Production.json`:

```json
{
  "AllowedHosts": "<nome-do-app>.azurewebsites.net",
  "Serilog": {
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "formatter": "Serilog.Formatting.Compact.CompactJsonFormatter, Serilog.Formatting.Compact"
        }
      }
    ]
  }
}
```

> Arrays do `appsettings` se mesclam **por índice**, não por substituição. O `WriteTo[0]` de produção
> completa o `Console` da base, e é por isso que os três arquivos mantêm o `Console` na posição 0.

`AllowedHosts` restrito faz a API recusar requisição com `Host` desconhecido. Se você apontar um
domínio próprio, ele entra nesse valor, separado por `;`.

### Variáveis e segredos

| Configuração | Desenvolvimento | Produção (App Service) | Segredo? |
|---|---|---|---|
| `ConnectionStrings:Default` | `dotnet user-secrets` | connection string `Default` ou `ConnectionStrings__Default` | sim |
| `ASPNETCORE_ENVIRONMENT` | `launchSettings.json` | `Production` (padrão) | não |
| `Cors:AllowedOrigins` | `appsettings.Development.json` | `Cors__AllowedOrigins__0`, só com cliente web | não |
| `RateLimiting:Auth:*` | `appsettings.json` | `RateLimiting__Auth__PermitLimit`, se precisar ajustar | não |
| `Auth:*` | `appsettings.json` | `Auth__RefreshTokenDays`, se precisar ajustar | não |
| `ApiLogging:*` | `appsettings.json` | `ApiLogging__RetentionDays`, se precisar ajustar | não |

Nas variáveis de ambiente, `__` faz o papel do `:`.

---

## 8. Log de requisições em banco

Um segundo mecanismo, separado do Serilog: uma tabela `api_logs` que o `Admin` consulta pela API
para diagnosticar um problema, sem acessar o App Service. Sem tela no app na liberação inicial.

| Toggle | O que grava | Corpo |
|---|---|---|
| Desligado (padrão) | Só erro (status >= 400): método, rota, status, tempo e exceção | Não, e nem faz buffer |
| Ligado | Tudo | Sim, truncado em `MaxBodyLength`, exceto em `BodyExcludedPaths` |

### O que muda em relação ao ControleFinanceiro

A ideia vem de lá. Estes pontos foram corrigidos de propósito, e o motivo importa:

| No ControleFinanceiro | Aqui | Por quê |
|---|---|---|
| Log completo grava o corpo de toda requisição, inclusive do login | `/api/auth/*` nunca grava corpo nem query string | **O log ligado grava a senha** em texto puro na tabela |
| `ativar` e `desativar` sem `[Authorize]` | Policy `AdminOnly` em todas as ações | Qualquer anônimo poderia ligar o log completo |
| `EnableBuffering` e `MemoryStream` em toda requisição | Buffer só com o toggle ligado | O custo era pago até nas requisições que não geravam log |
| `await LogAsync` dentro da requisição | `Channel` + worker | Ver abaixo |
| Controller acessa o `DbContext` | Controller chama casos de uso | É a regra de camadas do projeto |
| `DateTime.Now` | `DateTimeOffset.UtcNow` | É a regra de datas do planejamento |

### Por que um Channel

Gravar dentro da requisição parece mais simples, mas some isso ao `EnableRetryOnFailure`: com o banco
pausado ou fora do ar, o retry tenta por minutos, e a resposta fica presa esperando o **log**. Uma
requisição que nem precisava do banco passaria a depender dele.

Com o `Channel`, o middleware só publica e segue:

```
Requisição → RequestLoggingMiddleware → Channel limitado → ApiLogWriter → api_logs
                     (não espera)        (em memória)      (escopo próprio, em lote)
```

O modo `DropOldest` decide o que acontece se o banco ficar fora por muito tempo: a fila não cresce
sem limite e a requisição nunca bloqueia. Quando encher, perde o registro mais antigo.

### Application

```csharp
public interface IApiLogSwitch
{
    bool IsEnabled { get; }
    void Set(bool enabled);
}

public interface IApiLogRepository
{
    void AddRange(IEnumerable<ApiLog> logs);
    Task<ApiLog?> GetByIdAsync(long id, CancellationToken ct);
    Task<PagedResponse<ApiLogSummaryResponse>> ListAsync(ListApiLogsRequest filter, PaginationParameters paging, CancellationToken ct);
    Task<int> DeleteOlderThanAsync(DateTimeOffset cutoff, CancellationToken ct);
}
```

```csharp
public sealed record ListApiLogsRequest(
    DateTimeOffset? From = null,
    DateTimeOffset? To = null,
    Guid? UserId = null,
    string? Path = null,
    int? StatusCode = null,
    bool OnlyErrors = false);

public sealed record ApiLogSummaryResponse(
    long Id, string TraceId, DateTimeOffset OccurredAt, string Method, string Path,
    int StatusCode, long ElapsedMs, Guid? UserId, bool IsError);

public sealed record ApiLogResponse(
    long Id, string TraceId, DateTimeOffset OccurredAt, string Method, string Path, string? QueryString,
    int StatusCode, long ElapsedMs, Guid? UserId, bool IsError,
    string? RequestBody, string? ResponseBody, string? ExceptionMessage, string? StackTrace);

public sealed record ApiLogSettingsResponse(bool DetailedLoggingEnabled);

public sealed record UpdateApiLogSettingsRequest(bool DetailedLoggingEnabled);
```

```csharp
public sealed class ListApiLogsUseCase(IApiLogRepository logs, IValidator<ListApiLogsRequest> validator)
{
    public async Task<PagedResponse<ApiLogSummaryResponse>> ExecuteAsync(
        ListApiLogsRequest request, PaginationParameters paging, CancellationToken ct)
    {
        await validator.ValidateAndThrowAsync(request, ct);   // ex.: From <= To
        return await logs.ListAsync(request, paging, ct);
    }
}

public sealed class GetApiLogByIdUseCase(IApiLogRepository logs)
{
    public async Task<ApiLogResponse> ExecuteAsync(long id, CancellationToken ct)
    {
        var log = await logs.GetByIdAsync(id, ct)
            ?? throw new NotFoundException("Registro de log não encontrado.");

        return log.ToResponse();
    }
}

public sealed class GetApiLogSettingsUseCase(IApiLogSwitch logSwitch)
{
    public ApiLogSettingsResponse Execute() => new(logSwitch.IsEnabled);
}

public sealed class UpdateApiLogSettingsUseCase(IApiLogSwitch logSwitch)
{
    public ApiLogSettingsResponse Execute(UpdateApiLogSettingsRequest request)
    {
        logSwitch.Set(request.DetailedLoggingEnabled);
        return new(logSwitch.IsEnabled);
    }
}
```

O `ToResponse()` do `GetApiLogByIdUseCase` fica em `Features/ApiLogs/Mappings/ApiLogMappings.cs`. A
lista não usa mapping: o repositório já projeta direto para `ApiLogSummaryResponse`.

### Infra

```csharp
public sealed class ApiLogConfiguration : IEntityTypeConfiguration<ApiLog>
{
    public void Configure(EntityTypeBuilder<ApiLog> builder)
    {
        builder.ToTable("api_logs");
        builder.HasKey(l => l.Id);

        builder.Property(l => l.TraceId).HasMaxLength(ApiLog.MaxTraceIdLength).IsRequired();
        builder.Property(l => l.Method).HasMaxLength(ApiLog.MaxMethodLength).IsRequired();
        builder.Property(l => l.Path).HasMaxLength(ApiLog.MaxUrlPartLength).IsRequired();
        builder.Property(l => l.QueryString).HasMaxLength(ApiLog.MaxUrlPartLength);

        // Consulta por período e limpeza por retenção.
        builder.HasIndex(l => l.OccurredAt);

        // De propósito, sem FK para o usuário: o log sobrevive a ele e pode ser anônimo.
    }
}
```

```csharp
public sealed class ApiLogRepository(AppDbContext context) : IApiLogRepository
{
    public void AddRange(IEnumerable<ApiLog> logs) => context.ApiLogs.AddRange(logs);

    public Task<ApiLog?> GetByIdAsync(long id, CancellationToken ct) =>
        context.ApiLogs.AsNoTracking().FirstOrDefaultAsync(l => l.Id == id, ct);

    public Task<PagedResponse<ApiLogSummaryResponse>> ListAsync(
        ListApiLogsRequest filter, PaginationParameters paging, CancellationToken ct)
    {
        var query = context.ApiLogs.AsNoTracking();

        if (filter.From is not null)
            query = query.Where(l => l.OccurredAt >= filter.From);
        if (filter.To is not null)
            query = query.Where(l => l.OccurredAt <= filter.To);
        if (filter.UserId is not null)
            query = query.Where(l => l.UserId == filter.UserId);
        if (!string.IsNullOrWhiteSpace(filter.Path))
            query = query.Where(l => l.Path.Contains(filter.Path));
        if (filter.StatusCode is not null)
            query = query.Where(l => l.StatusCode == filter.StatusCode);
        if (filter.OnlyErrors)
            query = query.Where(l => l.IsError);

        // O Select evita trazer corpos e stack trace, que são nvarchar(max), só para listar.
        return query
            .OrderByDescending(l => l.OccurredAt)
            .ThenByDescending(l => l.Id)
            .Select(l => new ApiLogSummaryResponse(
                l.Id, l.TraceId, l.OccurredAt, l.Method, l.Path,
                l.StatusCode, l.ElapsedMs, l.UserId, l.IsError))
            .ToPagedResponseAsync(paging, ct);
    }

    // ExecuteDeleteAsync vai direto ao banco, em um único DELETE, sem carregar as linhas.
    public Task<int> DeleteOlderThanAsync(DateTimeOffset cutoff, CancellationToken ct) =>
        context.ApiLogs.Where(l => l.OccurredAt < cutoff).ExecuteDeleteAsync(ct);
}
```

### Api

Tudo em `Logging/`. Ficam na `Api` porque são assunto do host, e o projeto `Infra` não é Web SDK.

```csharp
// Singleton: a mesma instância é lida pelo middleware e alterada pelo caso de uso.
internal sealed class ApiLogSwitch : IApiLogSwitch
{
    // volatile: uma thread que escreve fica visível para as outras, sem cache de CPU.
    // Campo sem valor inicial: a API sempre sobe com o detalhado desligado.
    private volatile bool _isEnabled;

    public bool IsEnabled => _isEnabled;

    public void Set(bool enabled) => _isEnabled = enabled;
}
```

```csharp
internal sealed class ApiLogQueue
{
    private const int Capacity = 1_000;

    private readonly Channel<ApiLog> _channel = Channel.CreateBounded<ApiLog>(new BoundedChannelOptions(Capacity)
    {
        FullMode = BoundedChannelFullMode.DropOldest,
        SingleReader = true
    });

    public ChannelReader<ApiLog> Reader => _channel.Reader;

    // Com DropOldest, TryWrite nunca falha e nunca espera.
    public void Enqueue(ApiLog log) => _channel.Writer.TryWrite(log);
}
```

```csharp
internal static class HttpContextLogExtensions
{
    private const string ExceptionKey = "ApiLog.Exception";

    // Um só jeito de obter o id: é ele que liga o ProblemDetails ao registro em api_logs.
    public static string GetTraceId(this HttpContext context) =>
        Activity.Current?.Id ?? context.TraceIdentifier;

    public static void SetLoggedException(this HttpContext context, Exception exception) =>
        context.Items[ExceptionKey] = exception;

    public static Exception? GetLoggedException(this HttpContext context) =>
        context.Items[ExceptionKey] as Exception;
}
```

```csharp
internal sealed class RequestLoggingMiddleware(
    RequestDelegate next,
    IApiLogSwitch logSwitch,
    ApiLogQueue queue,
    IOptions<ApiLoggingOptions> options)
{
    private readonly ApiLoggingOptions _options = options.Value;

    public async Task InvokeAsync(HttpContext context)
    {
        if (Matches(context.Request.Path, _options.IgnoredPaths))
        {
            await next(context);
            return;
        }

        var detailed = logSwitch.IsEnabled;

        // /api/auth/* nunca grava corpo nem query string: login leva a senha no corpo, e os links
        // de confirmação levam token na URL. O header Authorization não é gravado em lugar nenhum.
        var captureDetails = detailed && !Matches(context.Request.Path, _options.BodyExcludedPaths);

        var requestBody = captureDetails ? await ReadRequestBodyAsync(context.Request) : null;

        // O stream de resposta só escreve. Para ler o que saiu, troca por um MemoryStream e copia
        // de volta no fim. Só acontece com o detalhado ligado.
        var originalResponseBody = context.Response.Body;
        using var responseBuffer = captureDetails ? new MemoryStream() : null;
        if (responseBuffer is not null)
            context.Response.Body = responseBuffer;

        var stopwatch = Stopwatch.StartNew();

        try
        {
            await next(context);
        }
        finally
        {
            stopwatch.Stop();

            var responseBody = responseBuffer is null
                ? null
                : await CopyResponseBackAsync(context, responseBuffer, originalResponseBody);

            var exception = context.GetLoggedException();

            if (detailed || exception is not null || context.Response.StatusCode >= 400)
            {
                queue.Enqueue(ApiLog.Create(
                    traceId: context.GetTraceId(),
                    occurredAt: DateTimeOffset.UtcNow,
                    method: context.Request.Method,
                    path: context.Request.Path,
                    queryString: captureDetails ? context.Request.QueryString.Value : null,
                    statusCode: context.Response.StatusCode,
                    elapsedMs: stopwatch.ElapsedMilliseconds,
                    userId: GetUserId(context),
                    requestBody: Truncate(requestBody),
                    responseBody: Truncate(responseBody),
                    exception: exception));
            }
        }
    }

    // StartsWithSegments: "/api/auth" casa com "/api/auth/login", mas não com "/api/authors".
    private static bool Matches(PathString path, string[] prefixes) =>
        prefixes.Any(prefix => path.StartsWithSegments(prefix, StringComparison.OrdinalIgnoreCase));

    private static async Task<string> ReadRequestBodyAsync(HttpRequest request)
    {
        // Sem EnableBuffering o corpo só pode ser lido uma vez, e o controller receberia vazio.
        request.EnableBuffering();

        using var reader = new StreamReader(request.Body, Encoding.UTF8, leaveOpen: true);
        var body = await reader.ReadToEndAsync(request.HttpContext.RequestAborted);
        request.Body.Position = 0;

        return body;
    }

    private static async Task<string> CopyResponseBackAsync(HttpContext context, MemoryStream buffer, Stream original)
    {
        buffer.Position = 0;
        using var reader = new StreamReader(buffer, Encoding.UTF8, leaveOpen: true);
        var body = await reader.ReadToEndAsync();

        buffer.Position = 0;
        await buffer.CopyToAsync(original);
        context.Response.Body = original;

        return body;
    }

    private static Guid? GetUserId(HttpContext context) =>
        Guid.TryParse(context.User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;

    private string? Truncate(string? value) =>
        value is null || value.Length <= _options.MaxBodyLength ? value : value[.._options.MaxBodyLength];
}
```

O usuário é lido no `finally`, depois do `next`: o middleware roda antes da autenticação, mas no fim
da requisição o `HttpContext` já tem o usuário preenchido.

```csharp
internal sealed class ApiLogWriter(
    ApiLogQueue queue,
    IServiceScopeFactory scopeFactory,
    IOptions<ApiLoggingOptions> options,
    ILogger<ApiLogWriter> logger) : BackgroundService
{
    private const int BatchSize = 100;
    private static readonly TimeSpan CleanupInterval = TimeSpan.FromHours(24);

    // Valor mínimo: o primeiro flush depois da subida já faz a limpeza. Assim, reinícios frequentes
    // do App Service não adiam a retenção para sempre.
    private DateTimeOffset _lastCleanup = DateTimeOffset.MinValue;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var batch = new List<ApiLog>(BatchSize);

        try
        {
            while (await queue.Reader.WaitToReadAsync(stoppingToken))
            {
                batch.Clear();

                while (batch.Count < BatchSize && queue.Reader.TryRead(out var log))
                    batch.Add(log);

                await FlushAsync(batch, stoppingToken);
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Encerramento normal. O que ainda estava na fila se perde.
        }
    }

    private async Task FlushAsync(List<ApiLog> batch, CancellationToken ct)
    {
        try
        {
            // Escopo próprio: o worker é singleton e o DbContext é scoped. E o escopo é limpo:
            // se o erro registrado veio do banco, o DbContext da requisição pode estar inválido.
            using var scope = scopeFactory.CreateScope();
            var logs = scope.ServiceProvider.GetRequiredService<IApiLogRepository>();
            var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

            logs.AddRange(batch);
            await unitOfWork.SaveChangesAsync(ct);

            // A limpeza pega carona no flush, sem timer próprio. Um timer acordaria o banco
            // pausado todo dia, mesmo sem ninguém usando o app.
            if (DateTimeOffset.UtcNow - _lastCleanup >= CleanupInterval)
            {
                var cutoff = DateTimeOffset.UtcNow.AddDays(-options.Value.RetentionDays);
                await logs.DeleteOlderThanAsync(cutoff, ct);
                _lastCleanup = DateTimeOffset.UtcNow;
            }
        }
        catch (Exception ex) when (!ct.IsCancellationRequested)
        {
            // Falha no log não pode derrubar a API: exceção que escapa de um BackgroundService
            // encerra a aplicação. Perde o lote e segue.
            logger.LogError(ex, "Falha ao gravar {Count} registros de log em banco", batch.Count);
        }
    }
}
```

> O escopo do worker não tem `HttpContext`, e o `CurrentUser` lançaria exceção se fosse lido. Não
> acontece porque `ApiLog` não tem filtro global: o `AppDbContext` só lê o usuário atual em consulta
> de entidade filtrada.

Registro, em `ApiConfigurationExtensions`:

```csharp
private static void AddApiRequestLogging(this IServiceCollection services)
{
    services.AddSingleton<IApiLogSwitch, ApiLogSwitch>();
    services.AddSingleton<ApiLogQueue>();
    services.AddHostedService<ApiLogWriter>();
}
```

### Controller

Chama casos de uso, como qualquer outro. A policy na classe vale para todas as ações.

```csharp
[ApiController]
[Route("api/admin/logs")]
[Authorize(Policy = AuthorizationPolicies.AdminOnly)]
public sealed class AdminLogsController : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResponse<ApiLogSummaryResponse>>> List(
        [FromQuery] ListApiLogsRequest request,
        [FromQuery] PaginationParameters paging,
        [FromServices] ListApiLogsUseCase useCase,
        CancellationToken ct) =>
        await useCase.ExecuteAsync(request, paging, ct);

    [HttpGet("{id:long}")]
    public async Task<ActionResult<ApiLogResponse>> GetById(
        long id,
        [FromServices] GetApiLogByIdUseCase useCase,
        CancellationToken ct) =>
        await useCase.ExecuteAsync(id, ct);

    [HttpGet("settings")]
    public ActionResult<ApiLogSettingsResponse> GetSettings(
        [FromServices] GetApiLogSettingsUseCase useCase) =>
        useCase.Execute();

    [HttpPut("settings")]
    public ActionResult<ApiLogSettingsResponse> UpdateSettings(
        [FromBody] UpdateApiLogSettingsRequest request,
        [FromServices] UpdateApiLogSettingsUseCase useCase) =>
        useCase.Execute(request);
}
```

### Limites

- **Estado em memória vale para uma instância.** Com duas instâncias no App Service, o `PUT` ligaria
  o detalhado só na que recebeu a chamada. Hoje é uma só.
- **Não é auditoria.** A fila aceita perder registro: até 1.000 em memória, descartados no
  encerramento da API ou quando o banco ficar fora por muito tempo.
- **Erro anônimo também grava.** Um robô varrendo a URL gera 401 e 404, e cada lote acorda o banco
  pausado. É uma consequência de "desligado grava status >= 400". Se o custo do banco aparecer,
  reveja o critério, por exemplo gravando só 5xx para requisição sem usuário.

---

## 9. Testes

Stack: xUnit, FluentAssertions e NSubstitute nos unitários; `WebApplicationFactory` + Testcontainers
na integração. FluentAssertions está só no `UnitTests`, por isso os exemplos de integração usam o
`Assert` do xUnit. Licença: ver "Decisões em aberto" do planejamento.

### Unitários — o que vale testar primeiro

| Alvo | Casos |
|---|---|
| `WorkoutSession.Register` / `AddSet` | duração; volume só com `Working` e `Drop`; fim antes do início lança exceção |
| `PlannedSet` | faixa com máximo ≤ mínimo lança exceção; número único aceito |
| `PersonalRecordCalculator` | primeira vez não é PR; carga maior é PR; mesma carga com mais reps é PR; aquecimento nunca é PR |
| `Exercise` | global não pode ser renomeado nem arquivado |
| Validators | um teste por regra, conferindo a mensagem em português |
| `PaginationParameters` | zero e negativo viram 1; `pageSize` acima de 100 vira 100; `page` gigante não estoura o `Skip` |
| `PagedResponse<T>` | `TotalPages`, `HasNextPage` na última página, `Map` preserva os totais |
| Mappings | `ToResponse()` ordena filhos por `Order` |
| `GetProfileUseCase` | sem perfil gravado, devolve os valores padrão |
| `RegisterWorkoutSessionUseCase` | `ConflictException` no `SaveChanges` devolve a sessão já gravada |

```csharp
public sealed class WorkoutSessionTests
{
    [Fact]
    public void AddSet_ShouldIgnoreWarmUpInVolume()
    {
        var session = WorkoutSession.Register(Guid.NewGuid(), Guid.NewGuid(), 1,
            DateTimeOffset.UtcNow.AddHours(-1), DateTimeOffset.UtcNow);

        session.AddSet(1, null, SetType.WarmUp,  40m, 10, DateTimeOffset.UtcNow);
        session.AddSet(1, null, SetType.Working, 80m,  8, DateTimeOffset.UtcNow);

        session.TotalVolumeKg.Should().Be(640m);
    }
}
```

Caso de uso depende de interface, e o NSubstitute troca cada uma por um dublê:

```csharp
public sealed class GetProfileUseCaseTests
{
    [Fact]
    public async Task ExecuteAsync_ShouldReturnDefaults_WhenProfileDoesNotExist()
    {
        var profiles = Substitute.For<IUserProfileRepository>();
        profiles.GetAsync(Arg.Any<CancellationToken>()).Returns((UserProfile?)null);

        var currentUser = Substitute.For<ICurrentUser>();
        currentUser.UserId.Returns(Guid.NewGuid());

        var useCase = new GetProfileUseCase(profiles, currentUser);

        var response = await useCase.ExecuteAsync(CancellationToken.None);

        response.DefaultRestSeconds.Should().Be(90);
        response.WeeklyCardioGoalMinutes.Should().Be(0);
    }
}
```

### Integração

Uma fábrica sobe a API com um SQL Server em container:

```csharp
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _db = new MsSqlBuilder("mcr.microsoft.com/mssql/server:2022-latest").Build();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("ConnectionStrings:Default", _db.GetConnectionString());

        // Sem isso, a suíte estoura o limite de 10 por minuto em /api/auth e os testes
        // passam a falhar com 429, porque todos saem do mesmo IP.
        builder.UseSetting("RateLimiting:Auth:PermitLimit", "10000");
    }

    public async Task InitializeAsync()
    {
        await _db.StartAsync();
        // aplicar migrations aqui (context.Database.MigrateAsync())
    }

    public new async Task DisposeAsync() => await _db.DisposeAsync();
}
```

Os testes mais valiosos aqui:

- **Isolamento:** usuário B não enxerga o treino do usuário A (deve dar 404).
- **Idempotência:** dois `POST` com o mesmo `ClientId` geram uma sessão só, inclusive em paralelo,
  sem 500.
- **Paginação:** `pageSize=0` e `page=-1` respondem 200, nunca 500.
- **Catálogo:** `search=biceps` acha `Bíceps`.
- **Admin:** `/api/admin/logs` responde 401 sem token e 403 sem a role.
- **Log:** com o detalhado ligado, um login não grava corpo nem query string.
- **Autorização:** `/api/auth/login` continua acessível sem token.

---

## 10. Deploy

O workflow fica no repo da API, em `.github/workflows/`. Ele parte do `main_api-controle-financeiro.yml`,
com uma diferença importante: roda em **`ubuntu-latest`**, e não em `windows-latest`, porque o
Testcontainers precisa de Docker com imagem Linux. Os testes rodam antes de publicar.

```yaml
name: Build, testes e deploy da API

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.x'

      - name: Build
        run: dotnet build ProjetoAcademiaAPI.slnx --configuration Release

      - name: Testes
        run: dotnet test ProjetoAcademiaAPI.slnx --configuration Release --no-build

      - name: Publish
        run: dotnet publish src/ProjetoAcademiaAPI.Api/ProjetoAcademiaAPI.Api.csproj -c Release -o "${{ runner.temp }}/api"

      - uses: actions/upload-artifact@v4
        with:
          name: api
          path: ${{ runner.temp }}/api

  deploy:
    runs-on: ubuntu-latest
    needs: build

    steps:
      - uses: actions/download-artifact@v4
        with:
          name: api

      - uses: azure/webapps-deploy@v3
        with:
          app-name: '<nome-do-app>'
          slot-name: 'Production'
          package: .
          publish-profile: ${{ secrets.AZUREAPPSERVICE_PUBLISHPROFILE }}
```

### Migration em produção

Nunca automática: nem no pipeline, nem na subida da API. Migration com perda de dados não tem volta, e
você quer ler o SQL antes.

```bash
# na raiz de ProjetoAcademiaAPI
dotnet ef migrations script --idempotent -p src/ProjetoAcademiaAPI.Infra -s src/ProjetoAcademiaAPI.Api -o migration.sql
```

`--idempotent` gera um script que confere o que já foi aplicado, então serve mesmo sem saber em qual
migration o banco está. Revise e aplique no Azure SQL à mão, **antes** do deploy que depende dela.

### Data Protection

O bearer token do Identity não é JWT: ele é protegido pelas chaves do Data Protection. O App Service
persiste essas chaves, então reiniciar a API não invalida os tokens já emitidos. Se a hospedagem mudar
para um lugar sem esse armazenamento, todo mundo perderá a sessão a cada reinício, e as chaves
precisarão de um armazenamento próprio.

---

## 11. Ordem sugerida de desenvolvimento

Cada passo termina com algo rodando, e cada um apoia o seguinte.

1. **Referências e pacotes** (seção 1). Corrigir os caminhos dos testes. Compila vazia.
2. **Configuração base e Serilog** (seção 7): `appsettings`, Options, Serilog, JSON, `ProblemDetails`,
   health check e pipeline. `/health` responde.
3. **Identity + DbContext + primeira migration.** Inclui OpenAPI com bearer, senha e role `Admin`.
   Registrar e logar pelo Scalar.
4. **`ICurrentUser`, filtro global, `GlobalExceptionHandler`.** A fundação de tudo o que vem depois.
5. **Profile**: a feature mais simples (1:1, sem lista). Valida o caminho inteiro: request →
   validator → caso de uso → repositório → mapping → response.
6. **WeightEntries**: primeiro CRUD e primeira lista paginada (`PaginationParameters`,
   `PagedResponse<T>`, `ToPagedResponseAsync`).
7. **Log em banco** (seção 8): entra aqui porque já há endpoint, paginação e erro para testar, e
   ajuda a diagnosticar tudo o que vem depois.
8. **Exercises**: seed global, filtro com `UserId` nulo, arquivamento, `search` com collation.
9. **Workouts**: primeiro agregado com filhos.
10. **WorkoutSessions**: idempotência, volume e PR. A parte mais rica do domínio.
11. **CardioSessions**: repete o padrão da sessão, mais simples.
12. **Dashboard e progresso por exercício**: só leitura, consultas agregadas.
13. **Deploy** (seção 10): pode vir antes, assim que houver algo para publicar.

Testes de integração de isolamento e idempotência entram junto com os passos 5 e 10.

---

## 12. Pontos em aberto

A lista oficial está em "Decisões em aberto" do `Planejamento.md`, que também traz `/register`
público, "esqueci a senha" e a licença do FluentAssertions. Aqui ficam os dois que afetam os exemplos
deste documento.

### 12.1 PR dentro da mesma sessão

"Carga maior que qualquer série anterior": as séries **da mesma sessão** contam como anteriores?
O exemplo diz que sim: se a 1ª série bate o recorde com 100 kg e a 2ª faz 105 kg, as duas são PR. A
alternativa é marcar só a melhor série do exercício no dia.

### 12.2 `DaysOfWeek` como texto

O planejamento grava enum como texto. Com `[Flags]`, o texto vira `"Monday, Wednesday"`, tanto no
banco quanto na API. Funciona (o `Enum.Parse` entende vírgula), mas não dá para filtrar no SQL por
"treinos de quarta" com facilidade. Se o dashboard precisar disso no banco, `int` resolve melhor para
este enum em particular.

# Backend — base para começar

> **Material de apoio, não oficial.** Sugestões para dar o primeiro passo no backend. Onde este
> documento divergir do `Planejamento.md`, vale o planejamento; onde divergir do código que você
> escrever, vale o código. Os trechos são esqueletos: nome, assinatura e responsabilidade — não
> implementação final.

## Sumário

1. [Criando a solução e as referências](#1-criando-a-solução-e-as-referências)
2. [Estrutura de pastas completa](#2-estrutura-de-pastas-completa)
3. [Domain](#3-domain)
4. [Application](#4-application)
5. [Infrastructure](#5-infrastructure)
6. [Api](#6-api)
7. [Testes](#7-testes)
8. [Ordem sugerida de desenvolvimento](#8-ordem-sugerida-de-desenvolvimento)
9. [Pontos para você decidir](#9-pontos-para-você-decidir)

---

## 1. Criando a solução e as referências

Rodar dentro de `ProjetoAcademiaAPI/`:

```bash
# Solução (.slnx)
dotnet new sln -n ProjetoAcademia --format slnx

# Projetos
dotnet new classlib -n ProjetoAcademia.Domain         -o src/ProjetoAcademia.Domain
dotnet new classlib -n ProjetoAcademia.Application    -o src/ProjetoAcademia.Application
dotnet new classlib -n ProjetoAcademia.Infrastructure -o src/ProjetoAcademia.Infrastructure
dotnet new webapi   -n ProjetoAcademia.Api            -o src/ProjetoAcademia.Api --use-controllers
dotnet new xunit    -n ProjetoAcademia.UnitTests        -o tests/ProjetoAcademia.UnitTests
dotnet new xunit    -n ProjetoAcademia.IntegrationTests -o tests/ProjetoAcademia.IntegrationTests

# Adiciona todos à solução
dotnet sln add src/ProjetoAcademia.Domain src/ProjetoAcademia.Application src/ProjetoAcademia.Infrastructure src/ProjetoAcademia.Api
dotnet sln add tests/ProjetoAcademia.UnitTests tests/ProjetoAcademia.IntegrationTests
```

### Referências entre projetos

A regra de dependência do planejamento vira referência de projeto — o compilador passa a barrar a
violação.

```
Domain          ← (nada)
Application     → Domain
Infrastructure  → Application, Domain
Api             → Application, Infrastructure
UnitTests       → Domain, Application
IntegrationTests→ Api
```

```bash
dotnet add src/ProjetoAcademia.Application    reference src/ProjetoAcademia.Domain
dotnet add src/ProjetoAcademia.Infrastructure reference src/ProjetoAcademia.Application src/ProjetoAcademia.Domain
dotnet add src/ProjetoAcademia.Api            reference src/ProjetoAcademia.Application src/ProjetoAcademia.Infrastructure
dotnet add tests/ProjetoAcademia.UnitTests        reference src/ProjetoAcademia.Domain src/ProjetoAcademia.Application
dotnet add tests/ProjetoAcademia.IntegrationTests reference src/ProjetoAcademia.Api
```

### Pacotes por projeto

| Projeto | Pacotes |
|---|---|
| `Domain` | nenhum |
| `Application` | `AutoMapper`, `FluentValidation` (ver [ponto 9.1](#91-registro-de-di-na-application)) |
| `Infrastructure` | `Microsoft.EntityFrameworkCore.SqlServer`, `EFCore.NamingConventions`, `Microsoft.AspNetCore.Identity.EntityFrameworkCore` |
| `Api` | `Microsoft.AspNetCore.OpenApi` (já vem no template), `Scalar.AspNetCore`, `Microsoft.EntityFrameworkCore.Design` (para o `dotnet ef`) |
| `UnitTests` | o que o template `xunit` traz |
| `IntegrationTests` | `Microsoft.AspNetCore.Mvc.Testing`, `Testcontainers.MsSql` |

Apague o `Class1.cs` dos classlibs e o `WeatherForecast` do template da Api.

---

## 2. Estrutura de pastas completa

O planejamento define o primeiro nível. Abaixo, uma sugestão de como ficaria preenchido.

```
ProjetoAcademiaAPI/
├── ProjetoAcademia.slnx
├── src/
│   ├── ProjetoAcademia.Domain/
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
│   │   │   └── CardioSession.cs
│   │   ├── Enums/
│   │   │   ├── SetType.cs
│   │   │   ├── MuscleGroup.cs
│   │   │   └── DaysOfWeek.cs
│   │   └── Exceptions/              (sugestão — não está no planejamento, ver 9.2)
│   │       ├── DomainException.cs
│   │       ├── NotFoundException.cs
│   │       └── ConflictException.cs
│   │
│   ├── ProjetoAcademia.Application/
│   │   ├── Abstractions/
│   │   │   ├── ICurrentUser.cs
│   │   │   ├── IUnitOfWork.cs
│   │   │   └── Repositories/
│   │   │       ├── IUserProfileRepository.cs
│   │   │       ├── IWeightEntryRepository.cs
│   │   │       ├── IExerciseRepository.cs
│   │   │       ├── IWorkoutRepository.cs
│   │   │       ├── IWorkoutSessionRepository.cs
│   │   │       └── ICardioSessionRepository.cs
│   │   ├── Common/
│   │   │   ├── PagedRequest.cs
│   │   │   └── PagedResponse.cs
│   │   ├── Features/
│   │   │   ├── Profile/
│   │   │   ├── WeightEntries/
│   │   │   ├── Exercises/
│   │   │   ├── Workouts/
│   │   │   ├── WorkoutSessions/
│   │   │   ├── CardioSessions/
│   │   │   └── Dashboard/
│   │   └── DependencyInjection.cs
│   │
│   ├── ProjetoAcademia.Infrastructure/
│   │   ├── Persistence/
│   │   │   ├── AppDbContext.cs
│   │   │   ├── Configurations/      (um ...Configuration por entidade)
│   │   │   ├── Migrations/
│   │   │   ├── Repositories/        (um ...Repository por interface)
│   │   │   └── Seed/
│   │   │       └── GlobalExercises.cs
│   │   ├── Identity/
│   │   │   └── (configuração do Identity, se crescer)
│   │   └── DependencyInjection.cs
│   │
│   └── ProjetoAcademia.Api/
│       ├── Controllers/
│       │   ├── ProfileController.cs
│       │   ├── WeightEntriesController.cs
│       │   ├── ExercisesController.cs
│       │   ├── WorkoutsController.cs
│       │   ├── WorkoutSessionsController.cs
│       │   ├── CardioSessionsController.cs
│       │   └── DashboardController.cs
│       ├── Services/
│       │   └── CurrentUser.cs
│       ├── Errors/
│       │   └── GlobalExceptionHandler.cs
│       ├── appsettings.json
│       └── Program.cs
│
└── tests/
    ├── ProjetoAcademia.UnitTests/
    │   ├── Domain/
    │   └── Application/
    └── ProjetoAcademia.IntegrationTests/
        ├── Infrastructure/          (WebApplicationFactory + Testcontainers)
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
    └── WorkoutProfile.cs
```

### Casos de uso sugeridos por feature

| Feature | Casos de uso | Endpoint |
|---|---|---|
| `Profile` | `GetProfileUseCase`, `UpsertProfileUseCase` | `GET/PUT /api/profile` |
| `WeightEntries` | `AddWeightEntryUseCase`, `ListWeightEntriesUseCase`, `DeleteWeightEntryUseCase` | `/api/weight-entries` |
| `Exercises` | `CreateExerciseUseCase`, `UpdateExerciseUseCase`, `ArchiveExerciseUseCase`, `ListExercisesUseCase`, `GetExerciseProgressUseCase` | `/api/exercises`, `/api/exercises/{id}/progress` |
| `Workouts` | `CreateWorkoutUseCase`, `UpdateWorkoutUseCase`, `ArchiveWorkoutUseCase`, `GetWorkoutByIdUseCase`, `ListWorkoutsUseCase` | `/api/workouts` |
| `WorkoutSessions` | `RegisterWorkoutSessionUseCase`, `GetWorkoutSessionByIdUseCase`, `ListWorkoutSessionsUseCase` | `/api/workout-sessions` |
| `CardioSessions` | `RegisterCardioSessionUseCase`, `ListCardioSessionsUseCase` | `/api/cardio-sessions` |
| `Dashboard` | `GetWeeklyDashboardUseCase` | `/api/dashboard/weekly` |

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
namespace ProjetoAcademia.Domain.Common;

public abstract class EntityBase
{
    public long Id { get; protected set; }
}
```

```csharp
namespace ProjetoAcademia.Domain.Common;

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
`EntityBase`.

```csharp
public sealed class UserProfile : IUserOwned
{
    public Guid UserId { get; private set; }
    public int? HeightCm { get; private set; }
    public int WeeklyCardioGoalMinutes { get; private set; }
    public int DefaultRestSeconds { get; private set; }
    public string TimeZone { get; private set; } = "America/Sao_Paulo";

    private UserProfile() { }

    public UserProfile(Guid userId) => UserId = userId;

    public void Update(int? heightCm, int weeklyCardioGoalMinutes, int defaultRestSeconds, string timeZone)
    {
        // regras: valores positivos, fuso válido...
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
repetições). Editar a ficha depois não muda o passado.

```csharp
public sealed class SessionSet : EntityBase, IUserOwned
{
    public Guid UserId { get; private set; }
    public long WorkoutSessionId { get; private set; }
    public long ExerciseId { get; private set; }
    public long? PlannedSetId { get; private set; }   // nulo = série extra
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

---

## 4. Application

### Abstrações

```csharp
namespace ProjetoAcademia.Application.Abstractions;

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
    Task<PagedResponse<Exercise>> ListAsync(string? search, MuscleGroup? muscleGroup, PagedRequest paging, CancellationToken ct);
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
banco é o `IUnitOfWork.SaveChangesAsync`.

### Paginação

```csharp
public sealed record PagedRequest(int Page = 1, int PageSize = 20);

public sealed record PagedResponse<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount);
```

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

> AutoMapper com `record` posicional: ele mapeia pelo construtor, casando parâmetro com propriedade
> pelo nome. `ExerciseName` ← `Exercise.Name` sai de graça pelo *flattening*.

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

### Mapping (AutoMapper)

```csharp
public sealed class WorkoutProfile : Profile
{
    public WorkoutProfile()
    {
        CreateMap<Workout, WorkoutResponse>();
        CreateMap<Workout, WorkoutSummaryResponse>();
        CreateMap<WorkoutExercise, WorkoutExerciseResponse>();
        CreateMap<PlannedSet, PlannedSetResponse>();
    }
}
```

Mapeie **entidade → response**. O caminho contrário (request → entidade) fica melhor à mão, pelo
construtor e pelos métodos da entidade — senão o AutoMapper passa por cima dos `set` privados e das
regras.

### Caso de uso — exemplo simples

```csharp
public sealed class CreateWorkoutUseCase(
    IWorkoutRepository workouts,
    IExerciseRepository exercises,
    IUnitOfWork unitOfWork,
    ICurrentUser currentUser,
    IValidator<CreateWorkoutRequest> validator,
    IMapper mapper)
{
    public async Task<WorkoutResponse> ExecuteAsync(CreateWorkoutRequest request, CancellationToken ct)
    {
        // 1. Validação de entrada sempre primeiro (lança ValidationException → 400)
        await validator.ValidateAndThrowAsync(request, ct);

        // 2. Regras que dependem do banco
        var exerciseIds = request.Exercises.Select(e => e.ExerciseId).Distinct();
        if (!await exercises.AllExistAsync(exerciseIds, ct))
            throw new NotFoundException("Um ou mais exercícios não foram encontrados.");

        // 3. Monta o agregado pela entidade, não pelo mapper
        var workout = new Workout(currentUser.UserId, request.Name, request.DaysOfWeek);
        foreach (var item in request.Exercises)
        {
            var workoutExercise = workout.AddExercise(item.ExerciseId, item.RestSeconds);
            foreach (var set in item.PlannedSets)
                workoutExercise.AddPlannedSet(set.Quantity, set.SetType, set.TargetRepsMin, set.TargetRepsMax);
        }

        // 4. Persiste e devolve
        workouts.Add(workout);
        await unitOfWork.SaveChangesAsync(ct);

        return mapper.Map<WorkoutResponse>(workout);
    }
}
```

> Atenção ao `ExerciseName` na resposta: logo após o `Add`, a navegação `Exercise` dos itens está
> vazia. Ou você recarrega o treino com `GetByIdAsync` antes de mapear, ou devolve só o `Id` e o
> app busca o detalhe.

### Caso de uso — o mais interessante: registrar a sessão

`RegisterWorkoutSessionUseCase` junta três regras do planejamento: idempotência pelo `ClientId`,
cálculo de volume (na entidade) e recorde pessoal.

```csharp
public sealed class RegisterWorkoutSessionUseCase(/* repositórios, uow, currentUser, validator, mapper */)
{
    public async Task<WorkoutSessionResponse> ExecuteAsync(RegisterWorkoutSessionRequest request, CancellationToken ct)
    {
        await validator.ValidateAndThrowAsync(request, ct);

        // Idempotência: reenvio do mesmo ClientId devolve o que já foi gravado.
        var existing = await sessions.GetByClientIdAsync(request.ClientId, ct);
        if (existing is not null)
            return mapper.Map<WorkoutSessionResponse>(existing);

        // (checar se o treino e os exercícios existem)

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
        await unitOfWork.SaveChangesAsync(ct);

        return mapper.Map<WorkoutSessionResponse>(session);   // a resposta traz os PRs do dia
    }
}
```

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

> Esta versão considera também as séries anteriores **da mesma sessão** (ver [ponto 9.3](#93-pr-dentro-da-mesma-sessão)).
> Ela poderia morar no `Domain` (é regra pura); na `Application` fica perto do caso de uso. Escolha
> sua.

### DependencyInjection.cs da Application

```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services, string autoMapperLicenseKey)
    {
        var assembly = typeof(DependencyInjection).Assembly;

        services.AddAutoMapper(cfg => cfg.LicenseKey = autoMapperLicenseKey, assembly);
        services.AddValidatorsFromAssembly(assembly);   // pacote FluentValidation.DependencyInjectionExtensions

        // Casos de uso: um por linha. Sem MediatR, o registro é explícito.
        services.AddScoped<CreateWorkoutUseCase>();
        services.AddScoped<RegisterWorkoutSessionUseCase>();
        // ...

        return services;
    }
}
```

---

## 5. Infrastructure

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
}
```

> Se a reflexão incomodar, a alternativa é escrever um `HasQueryFilter` por entidade — são sete
> linhas, e fica explícito.

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
| `SessionSet` | `WeightKg` com `HasPrecision(6, 2)`; índice em `(UserId, ExerciseId)` para o histórico e o PR |
| enums | `HasConversion<string>()` com `HasMaxLength` |
| FKs para `Exercise` | `DeleteBehavior.Restrict` — exercício nunca é apagado, só arquivado |

> **Cascata múltipla no SQL Server:** `SessionSet` chega em `AspNetUsers` por dois caminhos (direto
> e via `WorkoutSession`). O SQL Server recusa dois caminhos de cascata até a mesma tabela. Nas
> entidades filhas, deixe a FK do usuário com `DeleteBehavior.NoAction` (ou `Restrict`) e a cascata
> só pela raiz.

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

### DependencyInjection.cs da Infrastructure

```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<AppDbContext>(options => options
            .UseSqlServer(configuration.GetConnectionString("Default"))
            .UseSnakeCaseNamingConvention());

        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<AppDbContext>());

        services.AddScoped<IWorkoutRepository, WorkoutRepository>();
        services.AddScoped<IExerciseRepository, ExerciseRepository>();
        // ...

        return services;
    }
}
```

`IUnitOfWork` aponta para a **mesma instância** de `AppDbContext` do escopo — por isso a fábrica, e
não `AddScoped<IUnitOfWork, AppDbContext>()` (que criaria um segundo contexto).

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

Fino: recebe, chama o caso de uso, devolve. Nenhuma regra aqui.

```csharp
[ApiController]
[Authorize]
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

### GlobalExceptionHandler

```csharp
internal sealed class GlobalExceptionHandler(
    IProblemDetailsService problemDetailsService,
    ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken ct)
    {
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

### Program.cs

```csharp
var builder = WebApplication.CreateBuilder(args);

// Camadas
builder.Services.AddApplication(builder.Configuration["AutoMapper:LicenseKey"]!);
builder.Services.AddInfrastructure(builder.Configuration);

// Usuário atual
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();

// Identity + bearer token
builder.Services.AddAuthorization();
builder.Services
    .AddIdentityApiEndpoints<IdentityUser<Guid>>()
    .AddEntityFrameworkStores<AppDbContext>();

// Erros
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

// API
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// Log em JSON no console
builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapGroup("/api/auth").MapIdentityApi<IdentityUser<Guid>>();
app.MapControllers();

app.Run();

public partial class Program;   // para o WebApplicationFactory dos testes de integração enxergar
```

### Segredos e migrations

```bash
# dentro de src/ProjetoAcademia.Api
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:Default" "Server=localhost;Database=ProjetoAcademia;..."
dotnet user-secrets set "AutoMapper:LicenseKey" "<sua chave>"
```

```bash
# da raiz do ProjetoAcademiaAPI
dotnet ef migrations add Initial -p src/ProjetoAcademia.Infrastructure -s src/ProjetoAcademia.Api -o Persistence/Migrations
dotnet ef database update      -p src/ProjetoAcademia.Infrastructure -s src/ProjetoAcademia.Api
```

---

## 7. Testes

### Unitários — o que vale testar primeiro

| Alvo | Casos |
|---|---|
| `WorkoutSession.Register` / `AddSet` | duração; volume só com `Working` e `Drop`; fim antes do início lança exceção |
| `PlannedSet` | faixa com máximo ≤ mínimo lança exceção; número único aceito |
| `PersonalRecordCalculator` | primeira vez não é PR; carga maior é PR; mesma carga com mais reps é PR; aquecimento nunca é PR |
| `Exercise` | global não pode ser renomeado nem arquivado |
| Validators | um teste por regra, conferindo a mensagem em português |

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

        Assert.Equal(640m, session.TotalVolumeKg);
    }
}
```

### Integração

Uma fábrica sobe a API com um SQL Server em container:

```csharp
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _db = new MsSqlBuilder().Build();

    protected override void ConfigureWebHost(IWebHostBuilder builder) =>
        builder.UseSetting("ConnectionStrings:Default", _db.GetConnectionString());

    public async Task InitializeAsync()
    {
        await _db.StartAsync();
        // aplicar migrations aqui (context.Database.MigrateAsync())
    }

    public new async Task DisposeAsync() => await _db.DisposeAsync();
}
```

Os testes mais valiosos aqui: **isolamento** (usuário B não enxerga o treino do usuário A — deve dar
404) e **idempotência** (dois `POST` com o mesmo `ClientId` geram uma sessão só).

---

## 8. Ordem sugerida de desenvolvimento

Cada passo termina com algo rodando, e cada um apoia o seguinte.

1. **Solução e referências** (seção 1). Compila vazia.
2. **Program.cs mínimo + Identity + DbContext + primeira migration.** Registrar e logar pelo Scalar.
3. **`ICurrentUser`, filtro global, `GlobalExceptionHandler`.** A fundação de tudo o que vem depois.
4. **Profile** — a feature mais simples (1:1, sem lista). Valida o caminho inteiro: request →
   validator → caso de uso → repositório → response.
5. **WeightEntries** — primeira lista paginada.
6. **Exercises** — seed global, filtro com `UserId` nulo, arquivamento.
7. **Workouts** — primeiro agregado com filhos.
8. **WorkoutSessions** — idempotência, volume e PR. A parte mais rica do domínio.
9. **CardioSessions** — repete o padrão da sessão, mais simples.
10. **Dashboard e progresso por exercício** — só leitura, consultas agregadas.

Testes de integração de isolamento e idempotência entram junto com os passos 4 e 8.

---

## 9. Pontos para você decidir

Não estão fechados no planejamento — ou o exemplo acima precisou escolher algo.

### 9.1 Registro de DI na Application

`AddValidatorsFromAssembly` vem do pacote `FluentValidation.DependencyInjectionExtensions`, e
`IServiceCollection` de `Microsoft.Extensions.DependencyInjection.Abstractions` (este já chega
transitivo pelo AutoMapper). O planejamento diz que a `Application` só usa AutoMapper e
FluentValidation. Opções:

- Considerar o pacote de DI como parte da família FluentValidation (o mais comum).
- Deixar o `AddApplication` na `Api` e manter a `Application` sem nada de DI.

### 9.2 Onde ficam as exceções

O planejamento fala em "exceção de domínio" mas não lista a pasta `Domain/Exceptions`. A sugestão
aqui coloca as três no `Domain`. `NotFoundException` é discutível — "não achei no banco" é mais
assunto da `Application`. Pode separar: `DomainException` no `Domain`, `NotFoundException` e
`ConflictException` em `Application/Common/Exceptions`.

### 9.3 PR dentro da mesma sessão

"Carga maior que qualquer série anterior" — as séries **da mesma sessão** contam como anteriores?
O exemplo diz que sim: se a 1ª série bate o recorde com 100 kg e a 2ª faz 105 kg, as duas são PR. A
alternativa é marcar só a melhor série do exercício no dia.

### 9.4 `DaysOfWeek` como texto

O planejamento grava enum como texto. Com `[Flags]`, o texto vira `"Monday, Wednesday"` — funciona
(o `Enum.Parse` entende vírgula), mas não dá para filtrar no SQL por "treinos de quarta" com
facilidade. Se o dashboard precisar disso no banco, `int` resolve melhor para este enum em
particular.

### 9.5 Nome do Profile do AutoMapper para `UserProfile`

Pela convenção, o profile da feature `Profile` seria `UserProfileProfile`. Funciona, mas lê mal.
Talvez `ProfileMappingProfile`, ou aceitar o nome e seguir.

### 9.6 Biblioteca de mock nos testes unitários

O planejamento não define (NSubstitute, Moq, ou fakes escritos à mão). Se os testes ficarem no
domínio e no `PersonalRecordCalculator`, nenhuma é necessária.

# Projeto Academia

App mobile de treino: o usuário cadastra fichas, registra série a série com timer de descanso e
acompanha o progresso (treino, exercício, semana e cardio).

**A fonte da verdade é o [`Planejamento.md`](Planejamento.md)**: domínio, stack, arquitetura, modelo
de dados e convenções. Este arquivo não repete o planejamento; só registra como trabalhar aqui.

## Estrutura

```
ProjetoAcademia/                 (repo pai, só documentação — trabalhar sempre a partir daqui)
├── Planejamento.md
├── CLAUDE.md
├── docs/                        (material de apoio, não oficial)
├── prot_tipo_app_de_academia_for_a_foco.html   (protótipo visual)
├── ProjetoAcademiaAPI/          (submodule — backend .NET 10)
└── ProjetoAcademiaFront/        (submodule — React Native + Expo)
```

## Backend: modo mentoria

**O backend é escrito pelo usuário, à mão, do começo ao fim.** Isso vale para tudo dentro de
`ProjetoAcademiaAPI/`: código, `.csproj`, `.slnx`, testes, migrations e configuração.

Por isso, aqui esta regra **tem precedência sobre o fluxo do CLAUDE.md global**:

- **Todo pedido sobre o backend é uma dúvida.** Responder no chat, sem plano, sem issue, sem
  branch e sem agente de implementação.
- **Nada no backend é criado ou alterado sem pedido explícito** ("altere o arquivo", "crie no
  projeto", "implemente você"). "Como faço X?", "me mostra Y", "cria um exemplo de Z" **não** são
  pedidos explícitos.
- **A resposta padrão é um exemplo em texto** (bloco de código no chat) que o usuário replica no
  projeto. Explicar o porquê das decisões, não só o código.
- O exemplo segue o `Planejamento.md` e, onde já existir código, o padrão do código existente.
- Não usar `@dotnet:dev` nem as skills que escrevem código (`dotnet:criar-feature`,
  `dotnet:criar-endpoint`, `dotnet:criar-migration`, `dotnet:criar-testes`,
  `dotnet:criar-testes-integracao`, `dotnet:scaffold-*`, `dotnet:promover`, `dotnet:documentar-api`)
  para gravar arquivo. Elas podem servir de referência para montar o exemplo no chat.
- Leitura é livre: ler o código, explicar, investigar bug (sem corrigir) e revisar
  (`geral:revisor`, `dotnet:validar-*`, `banco:*`) quando o usuário pedir.
- Comando que **altera** o backend (`dotnet new`, `dotnet add`, `dotnet ef migrations add`,
  `database update`, `git` com escrita) não é executado: vai no chat para o usuário rodar.
  Comando só de leitura (`dotnet build`, `dotnet test`, `git status`, `git log`) pode rodar quando
  ajudar a responder.
- Com pedido explícito de alteração, volta o fluxo normal do CLAUDE.md global (plano → aprovação →
  execução), restrito ao que foi pedido.

Material de partida (não oficial): [`docs/backend-base.md`](docs/backend-base.md).

## Frontend

Segue o fluxo normal do CLAUDE.md global. Detalhes do front ficam no planejamento próprio, gerado
pelo `frontend:planejar`.

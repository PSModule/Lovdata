# Agents

## Main directive

Everything is a work in progress and can be improved.
If you find a problem or improvement, fix if small; otherwise open an issue.

## Repo guidance

`Lovdata` is a PowerShell module for working with Norwegian legal data from [Lovdata](https://lovdata.no).
It is an integration (API) module wrapping the [Lovdata API](https://api.lovdata.no/swagger/index.html),
which authenticates with an API key sent in the `X-API-Key` header.

- [`README.md`](README.md) — what this module is and how it is used.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — how to contribute to this repository.

## PSModule Framework guidance

Regarding repo structure, module source code and how the Process-PSModule workflow works.
For PSModule-specific build, layout, and process guidance:

- [Module types](https://psmodule.github.io/docs/Modules/Module-Types/) — integration (API) module conventions this repository follows.
- [Module bootstrap](https://psmodule.github.io/docs/Modules/Process-PSModule/module-bootstrap/) — the branching pattern used until the first release.
- [Repository defaults](https://psmodule.github.io/docs/Modules/Repository-Defaults/) — the expected repository layout and required files.
- [Module anatomy](https://psmodule.github.io/docs/Modules/Process-PSModule/module-anatomy/) — source layout and framework conventions.
- [Build, test, pack, publish](https://psmodule.github.io/docs/Modules/Process-PSModule/build-test-pack-publish/) — the CI/CD pipeline.
- [Standards](https://psmodule.github.io/docs/Modules/Standards/) — PowerShell module coding standards.
- [PSModule/memory](https://github.com/PSModule/memory) — durable cross-session agent working memory for the PSModule organization.

## Org-wide guidance

For cross-cutting ways of working and standards:

- [Agentic Development](https://msxorg.github.io/docs/Ways-of-Working/Agentic-Development/) — how agents and humans collaborate in this ecosystem.
- [Ways of Working](https://msxorg.github.io/docs/Ways-of-Working/) — contribution workflow, branching, PRs, issues.
- [Coding Standards](https://msxorg.github.io/docs/Coding-Standards/) — language-level conventions.
- [MSXOrg/memory](https://github.com/MSXOrg/memory) — durable agent working memory: gotchas, knowledge, and agent role notes.

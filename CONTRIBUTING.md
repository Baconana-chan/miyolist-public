# Contributing to MiyoList

Thanks for your interest in contributing.

## Development Setup

1. Install Bun and Rust toolchain.
2. Install frontend dependencies:

```bash
bun install
```

3. Run the desktop app in development mode:

```bash
bun tauri dev
```

## Before Opening a PR

Please run the same checks as CI:

```bash
bun run build
cd src-tauri && cargo check
```

## Pull Request Guidelines

- Keep PRs focused on a single feature/fix where possible.
- Include a short summary of what changed and why.
- Add screenshots or recordings for UI changes.
- If behavior changes, update docs (`README.md`, `TODO.md`) where relevant.

## Code Style

- Frontend: TypeScript + Preact, prefer clear component boundaries and explicit types.
- Backend: Rust + Tauri commands, prefer local-first behavior and graceful fallbacks.
- Avoid unrelated refactors in the same PR.

## Reporting Issues

When reporting bugs, include:

- Steps to reproduce
- Expected result
- Actual result
- Platform (Windows/macOS/Linux)
- Logs/errors if available

## Security

If you discover a security issue, please avoid public disclosure before maintainers can assess it.

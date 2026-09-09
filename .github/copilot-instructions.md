# Copilot Instructions

## Repository status and architecture

- This is a minimal Neovim configuration. Neovim loads the root-level `init.lua` as the configuration entry point.
- `init.lua` declares the external plugins through Neovim 0.12's built-in `vim.pack` manager. There are no Lua modules, custom commands, documentation files, or other configuration layers yet.
- The repository has no commits at present, so there is no historical implementation pattern to preserve.

## Commands

- No build, test, lint, formatter, or test-runner configuration exists yet.
- After adding Neovim configuration, validate that it starts non-interactively with:

  ```powershell
  nvim --headless "+quitall"
  ```

  This is the only available whole-configuration check; there are no individual tests to select.

## Conventions

- Prefer built-in Neovim functionality; add extensions only where they materially improve the setup.
- Manage external plugins exclusively with one `vim.pack.add()` declaration in `init.lua`. Keep `nvim-pack-lock.json` under version control after it is generated, and do not edit it by hand.
- The initial package set is `copilot.lua`, `sidekick.nvim`, `nvim-lspconfig`, `nvim-treesitter`, and `nvim-treesitter-textobjects`; retain `nvim-treesitter` whenever textobjects are present. Do not add `snacks.nvim` unless explicitly requested.
- Copilot uses `copilot.lua`'s bundled language server. Do not also enable nvim-lspconfig's `copilot` configuration unless a standalone `copilot-language-server` is intentionally installed, as that would create competing Copilot LSP clients.
- Keep configuration changes rooted in `init.lua` until separation is warranted. Group related concerns rather than creating one file per small plugin; use conventional locations such as `ftplugin/` when they fit the feature.
- The existing Vim configuration at `C:\Users\fabia\.vimrc` is a reference for familiar mappings. When adding or changing custom keymaps, align with it unless that conflicts with a Neovim default, a built-in mapping it overrides, or an established Neovim practice (including LSP mappings). Do not bulk-port that configuration; add capabilities incrementally and only when requested.
- Prioritize excellent Python and C# editing, test-running, and test-debugging workflows. Treat Haskell, Roc, and other language support as secondary.
- Preserve Windows and Linux compatibility where practical, especially for paths, shell commands, and external tools.
- GitHub Copilot integration and a code-review workflow are important capabilities to account for as the configuration evolves.

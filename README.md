# pimpmyshell

Configure a complete, beautiful zsh environment in one command.

[![Tests](https://github.com/christopherlouet/pimpmyshell/actions/workflows/test.yml/badge.svg)](https://github.com/christopherlouet/pimpmyshell/actions/workflows/test.yml)
[![Multi-Distro Tests](https://github.com/christopherlouet/pimpmyshell/actions/workflows/test-multi-distro.yml/badge.svg)](https://github.com/christopherlouet/pimpmyshell/actions/workflows/test-multi-distro.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Bash 4+](https://img.shields.io/badge/bash-4%2B-green.svg)](https://www.gnu.org/software/bash/)

## Features

- **One-command setup** - `pimpmyshell apply` configures everything
- **7 themes** - Cyberpunk (default), Matrix, Dracula, Catppuccin, Nord, Gruvbox, Tokyo Night
- **Multi-terminal support** - GNOME Terminal, kitty, alacritty, Konsole, XFCE Terminal, WezTerm
- **Multi-distro** - Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine, macOS
- **Live theme switching** - Terminal colors change instantly via OSC escape sequences
- **Modern CLI tools** - Automatic installation of eza, bat, fzf, starship, fd, ripgrep, zoxide, delta, dust, hyperfine, tldr
- **Data-driven tool management** - YAML registry maps tools to packages per distribution
- **Oh-My-Zsh integration** - Standard and custom plugins managed from YAML config
- **Alias groups** - Git, Docker, Kubernetes, navigation, files
- **Integrations** - fzf (preview with bat/eza), mise, tmux, zoxide, delta
- **Shell completions** - Tab completion for all commands, themes, profiles (bash and zsh)
- **Profiles** - Switch between work, personal, minimal configurations
- **Interactive wizard** - Guided setup with `pimpmyshell wizard`
- **Backup/restore** - Automatic backup before every change
- **Idempotent** - Safe to run multiple times

## Supported platforms

### Linux distributions

| Family | Distributions | Package manager |
|--------|--------------|-----------------|
| Debian | Ubuntu, Debian, Mint | apt |
| Fedora | Fedora, RHEL, CentOS, Rocky, Alma | dnf |
| Arch | Arch, Manjaro, EndeavourOS | pacman |
| SUSE | openSUSE Tumbleweed/Leap | zypper |
| Alpine | Alpine Linux | apk |

### macOS

Supported via Homebrew.

### Terminal emulators

| Terminal | Theme support | Detection method |
|----------|--------------|------------------|
| GNOME Terminal | dconf profile + palette | dconf |
| kitty | Config file + remote control | `TERM` / `TERM_PROGRAM` |
| alacritty | TOML config file | `TERM` / `TERM_PROGRAM` |
| Konsole | .colorscheme file | `KONSOLE_VERSION` |
| XFCE Terminal | xfconf-query | `XFCE_TERMINAL_VERSION` |
| WezTerm | OSC escape codes | `TERM_PROGRAM` |

All terminals also receive OSC escape codes for immediate color changes.

## Installation

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/christopherlouet/pimpmyshell/main/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/christopherlouet/pimpmyshell.git ~/.pimpmyshell
cd ~/.pimpmyshell
./install.sh
```

### Uninstall

```bash
~/.pimpmyshell/install.sh uninstall
```

## Usage

### Interactive setup

```bash
pimpmyshell wizard
```

The wizard guides you through 7 steps:

| Step | Description |
|------|-------------|
| 1. Theme | Choose from 7 themes with color swatch preview |
| 2. Plugins | Select Oh-My-Zsh and custom plugins |
| 3. Aliases | Pick alias groups (git, docker, kubernetes, navigation, files) |
| 4. Integrations | Enable fzf, zoxide, delta, fzf_tab, mise, tmux |
| 5. Tools | Select recommended CLI tools to install |
| 6. Preview | Review configuration summary before applying |
| 7. Profile | Optionally save as a named profile |

After confirmation, the wizard generates `pimpmyshell.yaml`, applies the theme, installs plugins, generates `.zshrc`, and reloads the shell.

### Apply configuration

```bash
pimpmyshell apply
```

Reads `~/.config/pimpmyshell/pimpmyshell.yaml` and generates your `.zshrc`, applies the theme, and installs plugins.

## Commands

| Command | Description |
|---------|-------------|
| `pimpmyshell apply` | Apply configuration (generate .zshrc, theme, plugins) |
| `pimpmyshell wizard` | Interactive setup wizard |
| `pimpmyshell theme [name]` | Show or change the current theme |
| `pimpmyshell theme --list` | List available themes |
| `pimpmyshell theme --preview` | Preview all themes with color swatches |
| `pimpmyshell tools check` | Check installed tools |
| `pimpmyshell tools install` | Install required and recommended tools |
| `pimpmyshell profile list` | List configuration profiles |
| `pimpmyshell profile create <name>` | Create a new profile |
| `pimpmyshell profile switch <name>` | Switch to a profile |
| `pimpmyshell profile delete <name>` | Delete a profile |
| `pimpmyshell backup` | Create a manual backup |
| `pimpmyshell restore` | Restore from backup |
| `pimpmyshell doctor` | Run environment diagnostics |
| `pimpmyshell update` | Update pimpmyshell to latest version |
| `pimpmyshell version` | Show version |
| `pimpmyshell help` | Show help |

### Options

```
-c, --config FILE   Use a specific config file
-v, --verbose       Enable verbose output
-d, --debug         Enable debug output
-q, --quiet         Suppress all output except errors
--dry-run           Show what would be done without making changes
--no-backup         Skip automatic backup before apply
```

### Aliases

Shorthand aliases are available after installation:

| Alias | Equivalent | Description |
|-------|-----------|-------------|
| `pms` | `pimpmyshell` | Short alias for all commands |
| `pms-switch <name>` | `pimpmyshell profile switch <name>` | Quick profile switch |

```bash
pms wizard              # Interactive setup
pms theme matrix        # Switch theme
pms-switch work         # Switch to work profile
```

`pms` and `pms-switch` are available as symlinks immediately after `install.sh`. Tab completion works for both.

## Configuration

Configuration is stored in `~/.config/pimpmyshell/pimpmyshell.yaml`.

```yaml
theme: cyberpunk

shell:
  framework: ohmyzsh

prompt:
  engine: starship

plugins:
  ohmyzsh:
    - git
    - fzf
    - tmux
    - docker
    - kubectl
    - extract
    - web-search
    - wd
    - mise
    - eza
  custom:
    - zsh-autosuggestions
    - zsh-syntax-highlighting
    - zsh-bat
    - zsh-completions

tools:
  required:
    - eza
    - bat
    - fzf
    - starship
  recommended:
    - fd
    - ripgrep
    - zoxide
    - delta
    - tldr

aliases:
  enabled: true
  groups:
    - git
    - docker
    - kubernetes
    - navigation
    - files

integrations:
  fzf:
    enabled: true
  fzf_tab:
    enabled: false    # set to true to use fzf for Tab completion
  mise:
    enabled: true
  zoxide:
    enabled: true
  delta:
    enabled: true
```

See `pimpmyshell.yaml.example` for a fully documented configuration file.

## Themes

Seven built-in themes, each applied consistently across Starship prompt, eza file listing colors, and your terminal emulator:

| Theme | Description |
|-------|-------------|
| **cyberpunk** | Neon lights in the rain - Night City aesthetic (default) |
| **matrix** | Digital rain - Classic green terminal |
| **dracula** | Dark theme with vibrant colors |
| **catppuccin** | Soothing pastel theme |
| **nord** | Arctic, north-bluish color palette |
| **gruvbox** | Retro groove color scheme |
| **tokyo-night** | Clean dark theme inspired by Tokyo at night |

Preview all themes:

```bash
pimpmyshell theme --preview
```

Switch theme (terminal colors change instantly):

```bash
pimpmyshell theme matrix
```

## Tools

Tools are managed via a data-driven YAML registry (`config/tools-registry.yaml`). Each tool maps to the correct package name per distribution and has an alternative install method as fallback.

| Tool | Description | Alt install |
|------|-------------|-------------|
| eza | Modern ls replacement | cargo |
| bat | Cat with syntax highlighting | cargo |
| fzf | Fuzzy finder | git clone |
| starship | Cross-shell prompt | curl script |
| fd | Fast find alternative | cargo |
| ripgrep | Fast grep alternative | cargo |
| zoxide | Smarter cd | cargo |
| delta | Git diff viewer | cargo |
| dust | Disk usage viewer | cargo |
| hyperfine | Benchmarking tool | cargo |
| tldr | Simplified man pages | npm |

## Shell completions

Tab completion is available for bash and zsh. It covers all commands, subcommands, theme names, profile names, and options.

Completions are automatically configured in the generated `.zshrc` (via `fpath`). For bash, source the completion file:

```bash
source ~/.pimpmyshell/completions/pimpmyshell.bash
```

## Environment diagnostics

```bash
pimpmyshell doctor
```

Checks: zsh, oh-my-zsh, required tools, plugins, theme files, Nerd Font, true color support.

## Project structure

```
pimpmyshell/
├── bin/              # CLI entry point
├── completions/      # Bash and zsh completions
├── config/           # tools-registry.yaml
├── lib/              # Core library (13 modules)
│   ├── core.sh       # Logging, guards, utilities
│   ├── config.sh     # YAML config management
│   ├── distro.sh     # Distribution detection
│   ├── tools.sh      # Tool installation
│   ├── themes.sh     # Theme engine (multi-terminal)
│   ├── zshrc-gen.sh  # .zshrc generation
│   ├── plugins.sh    # Plugin management
│   ├── profiles.sh   # Profile switching
│   ├── backup.sh     # Backup/restore
│   ├── doctor.sh     # Diagnostics
│   ├── wizard.sh     # Interactive wizard
│   ├── validation.sh # Input validation
│   └── yq-utils.sh   # YAML utilities
├── modules/          # Alias modules (git, docker, k8s, nav, files)
├── templates/        # zshrc template
├── themes/           # 7 theme definitions + data files
├── tests/            # 711 bats tests (18 test files)
└── install.sh        # Installer (standalone)
```

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

```bash
# Run all tests
bats tests/

# Run a specific test file
bats tests/tools.bats
```

CI runs tests on:
- Ubuntu (latest) and macOS (latest) via the **Tests** workflow
- Fedora, Arch Linux, openSUSE Tumbleweed, Alpine via the **Multi-Distro Tests** workflow
- ShellCheck static analysis on all shell files

## Requirements

- **zsh** - Shell (must be installed)
- **git** - For plugin installation
- **bash 4.0+** - For the CLI tool itself
- **yq** - YAML parser (installed automatically)

## License

GPL-3.0 - See [LICENSE](LICENSE) for details.

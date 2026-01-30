# pimpmyshell

Configure a complete, beautiful zsh environment in one command.

[![Tests](https://github.com/christopherlouet/pimpmyshell/actions/workflows/test.yml/badge.svg)](https://github.com/christopherlouet/pimpmyshell/actions/workflows/test.yml)

## Features

- **One-command setup** - `pimpmyshell apply` configures everything
- **7 Themes** - Cyberpunk (default), Matrix, Dracula, Catppuccin, Nord, Gruvbox, Tokyo Night
- **Coherent styling** - Each theme applies across Starship prompt, eza colors, and GNOME Terminal
- **Live theme switching** - Terminal foreground, background, and 16-color palette change instantly via OSC escape sequences
- **Modern CLI tools** - Automatic installation of eza, bat, fzf, starship, fd, ripgrep, zoxide, delta
- **Oh-My-Zsh integration** - Standard and custom plugins managed from YAML config
- **Alias groups** - Git, Docker, Kubernetes, navigation, files
- **Integrations** - fzf (preview with bat/eza), mise, tmux, zoxide, delta
- **Shell completions** - Tab completion for all commands, themes, profiles (bash and zsh)
- **Profiles** - Switch between work, personal, minimal configurations
- **Interactive wizard** - Guided setup with `pimpmyshell wizard`
- **Backup/restore** - Automatic backup before every change
- **Cross-platform** - Linux (apt/dnf/pacman) and macOS (brew)
- **Idempotent** - Safe to run multiple times

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
~/.pimpmyshell/install.sh --uninstall
```

## Usage

### Interactive setup

```bash
pimpmyshell wizard
```

The wizard guides you through choosing a theme, plugins, aliases, and integrations, then generates your configuration file.

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

Seven built-in themes, each applied consistently across Starship prompt, eza file listing colors, and optionally GNOME Terminal:

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

## Requirements

- **zsh** - Shell (must be installed)
- **git** - For plugin installation
- **bash 4.0+** - For the CLI tool itself
- **yq** - YAML parser (installed automatically)

## License

GPL-3.0 - See [LICENSE](LICENSE) for details.

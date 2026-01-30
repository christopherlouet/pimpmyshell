# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-01-30

### Added

- Live terminal color switching via OSC escape sequences (OSC 4/10/11) for instant theme changes
- Zsh fpath-based completions for all pimpmyshell commands, themes, and profiles
- Configurable fzf-tab integration (`integrations.fzf_tab.enabled`) - disabled by default
- Pre-selection of all items in wizard multi-select prompts (gum and fallback modes)
- Powerline filled style for all 7 Starship prompt themes with per-theme accent colors
- 16-color ANSI palette in terminal-colors.sh for full theme consistency

### Changed

- Theme switching now applies colors immediately (OSC sequences) plus persists via dconf
- Wizard no longer includes fzf-tab in custom plugin options by default
- Updated README with new features, shell completions section, and current config options

### Fixed

- Wizard now respects `WIZARD_THEME` environment variable in auto mode
- Added `~/.local/bin` to PATH in generated `.zshrc`
- Theme accent colors correctly used in powerline prompt segments

## [0.1.0] - 2026-01-29

### Added

- Core library (`lib/core.sh`): logging, platform detection, XDG directories, color support
- Configuration parsing (`lib/config.sh`): YAML via yq, get_config, config_enabled, get_config_list
- Configuration validation (`lib/validation.sh`): YAML syntax, theme/plugin/tool validation
- Theme management (`lib/themes.sh`): 7 themes, Starship + eza + GNOME Terminal application
- Theme preview and gallery (`preview_theme`, `theme_gallery`)
- Plugin management (`lib/plugins.sh`): oh-my-zsh standard and custom plugins
- Tool management (`lib/tools.sh`): detection, installation via package managers
- Backup/restore (`lib/backup.sh`): automatic backup before apply, manual backup/restore
- Doctor diagnostics (`lib/doctor.sh`): shell, framework, tools, plugins, theme, font, color checks
- Interactive wizard (`lib/wizard.sh`): guided setup with gum TUI or bash fallback
- Profile management (`lib/profiles.sh`): create, switch, delete configuration profiles
- CLI (`bin/pimpmyshell`): apply, theme, tools, backup, restore, doctor, wizard, profile, update
- .zshrc generation from YAML config with template system
- Alias modules: git, docker, kubernetes, navigation, files
- Integration modules: fzf, mise, tmux, zoxide, delta
- 7 themes: cyberpunk (default), matrix, dracula, catppuccin, nord, gruvbox, tokyo-night
- Starship prompt theme files (7 .toml files)
- Eza color theme files (7 .sh files)
- Shell completions: zsh and bash
- Installation script (`install.sh`) with uninstall support
- Configuration example (`pimpmyshell.yaml.example`)
- CI/CD: GitHub Actions for tests (ubuntu + macos) and releases
- 529+ BATS tests across all modules

[Unreleased]: https://github.com/christopherlouet/pimpmyshell/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/christopherlouet/pimpmyshell/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/christopherlouet/pimpmyshell/releases/tag/v0.1.0

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-01-30

### Added

- Interactive wizard v2 with step-based navigation engine (back/quit/next between 7 steps)
- Visual ASCII progress bar (`[====>    ] Step 3/7`) for wizard steps
- Descriptions for all 25 plugins, alias groups, and integrations in wizard selection
- Theme preview with ANSI truecolor swatches during theme selection (`_wizard_theme_swatch`, `_wizard_theme_label`)
- Tool selection step showing installed status markers (✓/✗), required tools always included
- Profile save step: optionally save wizard config as a named profile via `lib/profiles.sh`
- `fzf_tab` added to integrations list and config generation
- Input validation with retry loops (max 3 attempts) for `_wizard_choose`, `_wizard_choose_multi`, `_wizard_confirm`
- `_wizard_get_desc` function-based description lookup (30 entries across plugins, aliases, integrations)
- `_wizard_nav_prompt` navigation between wizard steps with auto-mode passthrough
- `_WIZARD_STEPS` step registry array for declarative wizard flow
- `WIZARD_TOOLS` and `WIZARD_PROFILE` state variables
- 45 new wizard tests (82 total), full suite 757 tests passing

### Changed

- `run_wizard()` refactored from linear call sequence to step loop with back navigation support
- Wizard step functions now receive `(step_num, total)` parameters instead of hardcoded numbers
- `_wizard_generate_config` uses `WIZARD_TOOLS` for dynamic recommended tools list
- `fzf_tab` integration now driven by wizard selection (was always `false`)

## [0.3.1] - 2026-01-30

### Added

- Multi-distro Linux support: Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine, macOS
- `lib/distro.sh`: distribution detection (`get_distro_id`, `get_distro_family`, `get_distro_pretty`, `run_privileged`)
- Multi-terminal theme support: GNOME Terminal, kitty, alacritty, Konsole, XFCE Terminal, WezTerm
- Multi-Distro CI workflow (Fedora, Arch, openSUSE, Alpine) via Docker containers
- `_parse_palette_colors()` helper in themes.sh for DRY palette parsing across 5 terminal backends

### Fixed

- `local status=$?` always capturing 0 in tools.sh — replaced with explicit error capture per case branch
- Tool install now skips package manager when no package defined for the distro, falls back to alternative install directly
- Single-quoted values in `/etc/os-release` now parsed correctly in `_read_os_release_field`
- openSUSE CI prerequisites: added `gawk` and `findutils` missing from minimal image
- `install.sh` `detect_package_manager` aligned with tools.sh (`apt` instead of `apt-get`, zypper before apk)

### Changed

- README rewritten with badges, supported platforms tables, tools registry, and project structure tree

## [0.3.0] - 2026-01-30

### Added

- `lib/yq-utils.sh`: centralized yq abstraction layer (`yq_eval`, `yq_eval_list`, `yq_write`, `yq_validate`)
- `lib/zshrc-gen.sh`: extracted 14 `.zshrc` generation functions from `config.sh` (single responsibility)
- `_require_args` helper in `core.sh` for standardized argument validation across all lib files
- `config/tools-registry.yaml`: data-driven tool metadata (commands, packages, alt_install)
- `scripts/shellcheck.sh`: local shellcheck runner matching CI configuration
- 18 yq-utils tests, 4 `_require_args` tests, 25 argument validation tests, 10 registry tests, 16 edge case tests
- Git URL validation with `_validate_git_url` to prevent command injection

### Changed

- `config.sh` reduced from 529 to 150 lines by extracting generation logic and delegating yq to `yq-utils.sh`
- `tools.sh` reads tool metadata from YAML registry instead of hardcoded case statements
- CI shellcheck separated into dedicated job (ubuntu-only) for faster feedback
- `install.sh` uses `_safe_rm` wrapper instead of raw `rm -rf`
- `eval` replaced with `declare -g` for safe variable assignment in `themes.sh`

### Fixed

- `validate_config` empty-arg handling using `$#` check
- PATH override in yq-utils tests for CI compatibility
- Shellcheck SC2034 suppressions for cross-file readonly constants

## [0.2.1] - 2026-01-30

### Fixed

- CI shellcheck failures: export `PIMPMYSHELL_DRY_RUN`, exclude SC1091, set warning severity
- Cross-platform `.zshrc` generation: use awk `ENVIRON[]` instead of `-v` for multi-line replacements (macOS compatibility)
- Wizard tmux integration now uses `tmux_enabled` variable instead of hardcoded value
- yq version detection test uses string comparison for macOS bash compatibility
- Added `shellcheck disable` directives for cross-file readonly constants

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

[Unreleased]: https://github.com/christopherlouet/pimpmyshell/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/christopherlouet/pimpmyshell/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/christopherlouet/pimpmyshell/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/christopherlouet/pimpmyshell/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/christopherlouet/pimpmyshell/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/christopherlouet/pimpmyshell/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/christopherlouet/pimpmyshell/releases/tag/v0.1.0

# Taches : pimpmyshell

**Date**: 2026-01-29
**Spec**: specs/pimpmyshell/spec.md
**Plan**: specs/pimpmyshell/plan.md

## Legende

| Marqueur | Signification |
|----------|---------------|
| `[P]` | Parallelisable (pas de dependance bloquante entre taches marquees) |
| `[US1]`..`[US10]` | Appartient a la User Story correspondante |
| `→ depend de` | Depend de la tache indiquee |

---

## Phase 1 : Fondation (bloquant)

> Prerequis : aucun. Tout le reste depend de cette phase.

### T001 - [US1] Creer la structure de repertoires du projet
**Fichiers**: `bin/`, `lib/`, `modules/aliases/`, `modules/integrations/`, `themes/`, `themes/data/`, `templates/`, `tests/`, `completions/`, `.github/workflows/`
**Description**: Creer l'arborescence vide avec README placeholders.
**Complexite**: Simple

### T002 - [US1] Implementer lib/core.sh
**Fichier**: `lib/core.sh`
**Description**: Librairie fondamentale reprenant les patterns de pimpmytmux/lib/core.sh :
- Guard contre re-sourcing (`_PIMPMYSHELL_CORE_LOADED`)
- Version du projet (`PIMPMYSHELL_VERSION="0.1.0"`)
- Repertoires XDG (`PIMPMYSHELL_CONFIG_DIR`, `PIMPMYSHELL_DATA_DIR`, `PIMPMYSHELL_CACHE_DIR`)
- Couleurs avec support `NO_COLOR`
- Niveaux de verbosité (0-3: quiet, normal, verbose, debug)
- Fonctions de log : `log_info`, `log_success`, `log_warn`, `log_error`, `log_debug`, `log_verbose`
- Fonctions erreur avancees : `die`, `die_with_help`, `error_with_suggestion`
- Detection plateforme : `get_platform`, `is_macos`, `is_linux`, `is_wsl`
- Verification commandes : `check_command`, `require_command`
- Chargement modules : `load_lib`, `load_module`, `is_module_loaded`
- Utilitaires : `trim`, `is_empty`, `to_lower`, `to_upper`, `array_contains`
- Initialisation repertoires : `init_directories`
**Complexite**: Moyenne
**→ depend de**: T001

### T003 - [US1] Creer le framework de tests
**Fichier**: `tests/test_helper.bash`
**Description**: Helper BATS inspire de pimpmytmux/tests/test_helper.bash :
- Setup/teardown avec repertoires temporaires
- Chargement libs (`load_lib`)
- Assertions : `assert_success`, `assert_failure`, `assert_output_contains`, `assert_file_exists`, `assert_dir_exists`
- Creation de config de test (`create_test_config`)
- Mock de commandes systeme
**Complexite**: Simple
**→ depend de**: T001

### T004 - [US1] Ecrire les tests de core.sh
**Fichier**: `tests/core.bats`
**Description**: Tests pour toutes les fonctions de core.sh :
- Detection plateforme
- Fonctions de log (avec capture stdout/stderr)
- Check commandes existantes/inexistantes
- Module loading
- String utilities
- Init directories
**Complexite**: Moyenne
**→ depend de**: T002, T003

### T005 - [US1] Creer le squelette CLI bin/pimpmyshell
**Fichier**: `bin/pimpmyshell`
**Description**: Point d'entree CLI inspire de pimpmytmux/bin/pimpmytmux :
- Resolution chemin script (symlinks)
- Chargement core.sh + libs necessaires
- Parsing arguments globaux (`--verbose`, `--debug`, `--dry-run`, `--quiet`, `--no-backup`, `--config`)
- Routing commandes : `apply`, `theme`, `tools`, `backup`, `restore`, `doctor`, `wizard`, `profile`, `update`, `version`, `help`
- Affichage aide avec usage et exemples
- Stubs pour chaque commande (a implementer dans les phases suivantes)
**Complexite**: Moyenne
**→ depend de**: T002

### T006 - Creer .gitignore et LICENSE
**Fichiers**: `.gitignore`, `LICENSE`
**Description**: .gitignore adapte (*.swp, .DS_Store, tmp/, etc.). LICENSE GPL v3.
**Complexite**: Simple
**→ depend de**: T001

---

## Phase 2 : Configuration & Validation (bloquant pour apply)

> Prerequis : Phase 1 terminee.

### T007 - [US1] Implementer lib/validation.sh
**Fichier**: `lib/validation.sh`
**Description**: Validation du fichier de configuration YAML :
- Guard (`_PIMPMYSHELL_VALIDATION_LOADED`)
- `validate_yaml_syntax` : verifier syntaxe YAML via yq
- `validate_config_values` : verifier valeurs (theme existe, plugins valides, outils connus)
- `validate_config` : orchestration des validations
- Messages d'erreur avec numero de ligne et suggestion
**Complexite**: Moyenne
**→ depend de**: T002

### T008 - [US1] Ecrire les tests de validation
**Fichier**: `tests/validation.bats`
**Description**: Tests avec YAML valide, invalide (syntaxe), valeurs incorrectes (theme inexistant), fichier vide, fichier absent.
**Complexite**: Moyenne
**→ depend de**: T003, T007

### T009 - [US1] Implementer lib/config.sh
**Fichier**: `lib/config.sh`
**Description**: Parsing YAML et acces configuration :
- Guard (`_PIMPMYSHELL_CONFIG_LOADED`)
- `detect_yq_version` : detecter yq Go vs Python
- `require_yq` : verifier yq disponible
- `yq_get` : lire valeur YAML (compatible Go/Python yq)
- `get_config` : lire valeur avec defaut
- `config_enabled` : lire booleen avec defaut
- `get_config_list` : lire liste YAML
- Constantes par defaut (theme: cyberpunk, framework: ohmyzsh, prompt: starship)
**Complexite**: Moyenne
**→ depend de**: T002

### T010 - [US1] Ecrire les tests de config
**Fichier**: `tests/config.bats`
**Description**: Tests avec config valide (lecture valeurs, listes, booleens), valeurs par defaut, config minimale, config absente.
**Complexite**: Moyenne
**→ depend de**: T003, T009

### T011 - [US1] Creer pimpmyshell.yaml.example
**Fichier**: `pimpmyshell.yaml.example`
**Description**: Fichier de configuration exemple complet et documente avec toutes les sections :
- theme, shell, prompt, plugins (ohmyzsh + custom), tools (required + recommended), aliases (groups), integrations (fzf, tmux, mise, zoxide, delta), keybindings, platform
- Commentaires explicatifs pour chaque option
- Theme par defaut : cyberpunk
**Complexite**: Simple
**→ depend de**: aucun

---

## Phase 3 : Themes [P - parallelisable]

> Prerequis : Phase 2 terminee (besoin de config.sh pour lire le theme choisi).

### T012 - [US3] Implementer lib/themes.sh
**Fichier**: `lib/themes.sh`
**Description**: Gestion des themes inspire de pimpmytmux/lib/themes.sh :
- Guard (`_PIMPMYSHELL_THEMES_LOADED`)
- `PIMPMYSHELL_THEMES_DIR` : chemin vers themes/
- `list_themes` : lister les themes disponibles
- `get_theme_path` : resoudre nom → fichier YAML
- `theme_get` : lire valeur depuis theme YAML
- `load_theme` : charger et exporter THEME_* variables
- `apply_starship_theme` : copier le .toml vers ~/.config/starship.toml
- `apply_eza_theme` : sourcer le .sh dans .zshrc
- `apply_gnome_theme` : appliquer profil GNOME Terminal (si disponible)
- `apply_theme` : orchestrer les 3 composants
**Complexite**: Complexe
**→ depend de**: T009

### T013 - [US3] Ecrire les tests de themes
**Fichier**: `tests/themes.bats`
**Description**: Tests : list_themes (7 resultats), get_theme_path (existant/inexistant), load_theme (variables exportees), theme_get (valeurs), apply_starship_theme (fichier copie).
**Complexite**: Moyenne
**→ depend de**: T003, T012

### T014 - [P] [US3] Creer les 7 fichiers theme YAML
**Fichiers**: `themes/cyberpunk.yaml`, `themes/matrix.yaml`, `themes/dracula.yaml`, `themes/catppuccin.yaml`, `themes/nord.yaml`, `themes/gruvbox.yaml`, `themes/tokyo-night.yaml`
**Description**: Adapter depuis pimpmytmux/themes/*.yaml. Conserver la meme structure (name, description, colors, separators, icons) mais retirer les champs tmux-specific (status_bar.style, show_prefix, show_mode).
**Complexite**: Simple
**→ depend de**: T001

### T015 - [P] [US3] Integrer les 7 fichiers Starship
**Fichiers**: `themes/data/starship-*.toml` (7 fichiers)
**Description**: Copier depuis claude-socle/scripts/themes/starship-themes/*.toml sans modification.
**Complexite**: Simple
**→ depend de**: T001

### T016 - [P] [US3] Integrer les 7 fichiers eza
**Fichiers**: `themes/data/eza-*.sh` (7 fichiers)
**Description**: Copier depuis claude-socle/scripts/themes/eza-*.sh. Retirer les aliases (geres par modules/aliases/files.sh). Garder uniquement l'export EZA_COLORS.
**Complexite**: Simple
**→ depend de**: T001

### T017 - [US3] Implementer generation theme GNOME Terminal
**Fichier**: `themes/data/gnome-terminal.sh`
**Description**: Script adapte de claude-socle/scripts/themes/install-gnome-terminal-theme.sh :
- Detection GNOME Terminal (via dconf)
- Palette 16 couleurs par theme
- Creation/mise a jour profil terminal
- Fonctions : `is_gnome_terminal`, `apply_gnome_terminal_theme`, `get_gnome_palette`
**Complexite**: Moyenne
**→ depend de**: T012

### T018 - [US3] Implementer la commande theme dans le CLI
**Fichier**: `bin/pimpmyshell` (section theme)
**Description**: Sous-commandes theme :
- `pimpmyshell theme` (sans arg) : afficher theme actuel
- `pimpmyshell theme --list` : lister les 7 themes
- `pimpmyshell theme <nom>` : changer et appliquer le theme
- Mise a jour du YAML (theme: <nom>)
**Complexite**: Simple
**→ depend de**: T005, T012

---

## Phase 4 : Plugins oh-my-zsh [P - parallelisable]

> Prerequis : Phase 2 terminee.

### T019 - [US1] Implementer lib/plugins.sh
**Fichier**: `lib/plugins.sh`
**Description**: Gestion plugins oh-my-zsh :
- Guard (`_PIMPMYSHELL_PLUGINS_LOADED`)
- `OMZ_DIR`, `OMZ_CUSTOM_DIR` : chemins oh-my-zsh
- `is_omz_installed` : verifier oh-my-zsh present
- `install_omz` : installer oh-my-zsh (script officiel, mode unattended)
- `is_plugin_installed` : verifier plugin (standard ou custom)
- `clone_custom_plugin` : cloner plugin git dans custom/plugins/
- `install_plugins` : installer tous les plugins de la config
- Registre plugins custom avec URL :
  - zsh-autosuggestions → https://github.com/zsh-users/zsh-autosuggestions
  - zsh-syntax-highlighting → https://github.com/zsh-users/zsh-syntax-highlighting
  - zsh-bat → https://github.com/fdellwing/zsh-bat
**Complexite**: Moyenne
**→ depend de**: T009

### T020 - [US1] Ecrire les tests de plugins
**Fichier**: `tests/plugins.bats`
**Description**: Tests : is_omz_installed (mock), is_plugin_installed (standard vs custom), clone_custom_plugin (mock git), liste plugins depuis config.
**Complexite**: Moyenne
**→ depend de**: T003, T019

---

## Phase 5 : Outils CLI [P - parallelisable]

> Prerequis : Phase 2 terminee.

### T021 - [US2] Implementer lib/tools.sh
**Fichier**: `lib/tools.sh`
**Description**: Detection et installation outils :
- Guard (`_PIMPMYSHELL_TOOLS_LOADED`)
- `detect_pkg_manager` : detecter apt/dnf/pacman/brew
- `is_tool_installed` : verifier outil present (par nom de commande)
- `get_tool_command` : resoudre nom alternatif (batcat→bat, fdfind→fd)
- `install_tool` : installer via pkg manager
- `install_tool_alt` : installer via methode alternative (curl, cargo)
- `install_all_tools` : installer tous les outils requis
- `check_tools` : verifier et rapporter l'etat de tous les outils
- Registre des outils :

| Outil | Commande | apt | dnf | pacman | brew | Alternatif |
|-------|----------|-----|-----|--------|------|------------|
| eza | eza | eza | eza | eza | eza | cargo install eza |
| bat | bat/batcat | bat | bat | bat | bat | cargo install bat |
| fzf | fzf | fzf | fzf | fzf | fzf | git clone + install |
| starship | starship | - | - | starship | starship | curl -sS starship.rs |
| fd | fd/fdfind | fd-find | fd-find | fd | fd | cargo install fd-find |
| ripgrep | rg | ripgrep | ripgrep | ripgrep | ripgrep | cargo install ripgrep |
| zoxide | zoxide | zoxide | zoxide | zoxide | zoxide | cargo install zoxide |
| delta | delta | git-delta | git-delta | git-delta | git-delta | cargo install git-delta |
| tldr | tldr | tldr | tldr | tldr | tldr | npm install -g tldr |
| dust | dust | dust | dust | dust | dust | cargo install du-dust |
| duf | duf | duf | duf | duf | duf | binaire Go |
| btop | btop | btop | btop | btop | btop | - |
| hyperfine | hyperfine | hyperfine | hyperfine | hyperfine | hyperfine | cargo install hyperfine |

**Complexite**: Complexe
**→ depend de**: T009

### T022 - [US2] Definir le registre des outils
**Fichier**: `lib/tools.sh` (integre dans T021)
**Description**: Tableau associatif des outils avec noms de paquets par plateforme et methode alternative.
**Complexite**: Inclus dans T021

### T023 - [US2] Ecrire les tests de tools
**Fichier**: `tests/tools.bats`
**Description**: Tests : detect_pkg_manager (mock), is_tool_installed, get_tool_command (aliases), install_tool (mock pkg manager).
**Complexite**: Moyenne
**→ depend de**: T003, T021

### T024 - [US2] Implementer la commande tools dans le CLI
**Fichier**: `bin/pimpmyshell` (section tools)
**Description**: Sous-commandes :
- `pimpmyshell tools check` : afficher etat de tous les outils
- `pimpmyshell tools install` : installer les outils manquants (requis auto, recommandes interactif)
**Complexite**: Simple
**→ depend de**: T005, T021

---

## Phase 6 : Modules aliases & integrations [P - parallelisable]

> Prerequis : Phase 2 terminee.

### T025 - [P] [US1] Creer modules/aliases/git.sh
**Fichier**: `modules/aliases/git.sh`
**Description**: Aliases git : `ga="git add"`, `gc="git commit"`, `gp="git push"`, `gl="git log --oneline"`, `gs="git status"`, `gd="git diff"`, `gb="git branch"`, `gco="git checkout"`, `gcm="git commit -m"`, etc.
**Complexite**: Simple

### T026 - [P] [US1] Creer modules/aliases/docker.sh
**Fichier**: `modules/aliases/docker.sh`
**Description**: Aliases docker : `dps="docker ps"`, `dex="docker exec -it"`, `dlogs="docker logs -f"`, `dcp="docker compose"`, `dcup="docker compose up -d"`, `dcdn="docker compose down"`, etc.
**Complexite**: Simple

### T027 - [P] [US1] Creer modules/aliases/kubernetes.sh
**Fichier**: `modules/aliases/kubernetes.sh`
**Description**: Aliases k8s : `kg="kubectl get"`, `kd="kubectl describe"`, `kl="kubectl logs"`, `kn="kubens"`, `kx="kubectx"`, `kgp="kubectl get pods"`, `kgs="kubectl get svc"`, etc.
**Complexite**: Simple

### T028 - [P] [US1] Creer modules/aliases/navigation.sh
**Fichier**: `modules/aliases/navigation.sh`
**Description**: Aliases navigation : `..="cd .."`, `...="cd ../.."`, `mkcd` (mkdir + cd), `take` (alias mkcd), etc.
**Complexite**: Simple

### T029 - [P] [US1] Creer modules/aliases/files.sh
**Fichier**: `modules/aliases/files.sh`
**Description**: Aliases fichiers via eza (adaptes depuis config actuelle) :
- `ls='eza --icons --group-directories-first'`
- `ll='eza -l --icons --group-directories-first --git'`
- `la='eza -la --icons --group-directories-first --git'`
- `lt='eza -T --icons --level=2'`
- `l='eza -l --icons --group-directories-first'`
- `cat='bat --paging=never'` (si bat installe)
- `catp='bat'` (avec paging)
**Complexite**: Simple

### T030 - [P] [US1] Creer modules/integrations/fzf.sh
**Fichier**: `modules/integrations/fzf.sh`
**Description**: Configuration fzf inspiree du .zshrc actuel :
- `FZF_DEFAULT_OPTS` : layout, couleurs theme, pointer, marker
- `FZF_CTRL_T_OPTS` : preview bat (fichiers) + eza tree (repertoires)
- `FZF_ALT_C_OPTS` : preview eza tree
- `FZF_CTRL_R_OPTS` : preview commande
- Keybindings fzf (Ctrl+T, Alt+C, Ctrl+R)
**Complexite**: Moyenne

### T031 - [P] [US1] Creer modules/integrations/mise.sh
**Fichier**: `modules/integrations/mise.sh`
**Description**: `eval "$(mise activate zsh)"` si mise installe.
**Complexite**: Simple

### T032 - [P] [US1] Creer modules/integrations/tmux.sh
**Fichier**: `modules/integrations/tmux.sh`
**Description**: Auto-start tmux optionnel (si configure). Variables ZSH_TMUX_*.
**Complexite**: Simple

### T033 - [P] [US1] Creer modules/integrations/zoxide.sh
**Fichier**: `modules/integrations/zoxide.sh`
**Description**: `eval "$(zoxide init zsh)"` si zoxide installe. Alias `cd` → `z` optionnel.
**Complexite**: Simple

### T034 - [P] [US1] Creer modules/integrations/delta.sh
**Fichier**: `modules/integrations/delta.sh`
**Description**: Configuration git pour utiliser delta : `git config --global core.pager delta`, `git config --global interactive.diffFilter 'delta --color-only'`.
**Complexite**: Simple

### T035 - [US1] Ecrire les tests aliases et integrations
**Fichiers**: `tests/aliases.bats`, `tests/integrations.bats`
**Description**: Tests : chaque fichier alias est sourcable sans erreur, fzf config genere les bonnes variables, integrations detectent correctement les outils.
**Complexite**: Moyenne
**→ depend de**: T003, T025-T034

---

## Phase 7 : Generation .zshrc (apply)

> Prerequis : Phases 2, 3, 4, 5, 6 terminees.

### T036 - [US1] Creer templates/zshrc.template
**Fichier**: `templates/zshrc.template`
**Description**: Template .zshrc avec sections ordonnees et marqueurs :
```
# >>> pimpmyshell managed >>>
# Generated by pimpmyshell v{VERSION} on {DATE}
# Theme: {THEME}
# DO NOT EDIT this section manually - use pimpmyshell apply

# --- Environment ---
{ENV_VARS}

# --- Oh-My-Zsh ---
{OMZ_CONFIG}

# --- Plugins ---
{PLUGINS}

# --- Source Oh-My-Zsh ---
source $ZSH/oh-my-zsh.sh

# --- Theme (eza colors) ---
{EZA_THEME}

# --- Aliases ---
{ALIASES}

# --- Integrations ---
{INTEGRATIONS}

# --- Prompt (Starship) ---
eval "$(starship init zsh)"

# <<< pimpmyshell managed <<<

# >>> user custom >>>
# Your custom configuration goes here
# This section is preserved across pimpmyshell apply
{USER_CUSTOM}
# <<< user custom <<<
```
**Complexite**: Moyenne
**→ depend de**: T011

### T037 - [US1] Implementer la generation .zshrc dans lib/config.sh
**Fichier**: `lib/config.sh` (ajout fonctions)
**Description**: Fonctions de generation :
- `_generate_env_vars` : exports (ZSH, LANG, EDITOR, PATH...)
- `_generate_omz_config` : ZSH_THEME, plugins=()
- `_generate_aliases` : sourcer les modules/aliases/ actives
- `_generate_integrations` : sourcer les modules/integrations/ activees
- `_generate_eza_theme` : sourcer le fichier eza du theme
- `generate_zshrc` : orchestrer toutes les sections, remplacer dans template
- `extract_user_custom` : extraire section user custom du .zshrc existant
- `inject_user_custom` : reinjecter section user custom
**Complexite**: Complexe
**→ depend de**: T009, T012, T019, T021, T036

### T038 - [US1] Implementer la commande apply dans le CLI
**Fichier**: `bin/pimpmyshell` (section apply)
**Description**: Orchestration complete :
1. Charger configuration
2. Valider configuration
3. Backup .zshrc et starship.toml existants (si --no-backup pas passe)
4. Installer oh-my-zsh si absent
5. Installer plugins custom manquants
6. Appliquer theme (starship + eza + gnome)
7. Generer .zshrc
8. Afficher resume des actions
**Complexite**: Moyenne
**→ depend de**: T005, T037, T040

### T039 - [US1] Test d'integration apply
**Fichier**: `tests/config.bats` (ajout tests integration)
**Description**: Test complet : config YAML → generate_zshrc → verifier .zshrc contient les bonnes sections, plugins, aliases, theme. Test idempotence (2x apply = meme resultat). Test preservation user custom.
**Complexite**: Moyenne
**→ depend de**: T003, T037

---

## Phase 8 : Backup/Restore [P - parallelisable avec Phase 7]

> Prerequis : Phase 1 terminee.

### T040 - [US4] Implementer lib/backup.sh
**Fichier**: `lib/backup.sh`
**Description**: Backup et restore inspire de pimpmytmux/lib/backup.sh :
- Guard (`_PIMPMYSHELL_BACKUP_LOADED`)
- `BACKUP_DIR` : `~/.local/share/pimpmyshell/backups/`
- `BACKUP_RETENTION` : 10
- `backup_file` : sauvegarder un fichier avec horodatage
- `restore_file` : restaurer un fichier depuis backup
- `list_backups` : lister sauvegardes disponibles (filtre optionnel)
- `get_latest_backup` : trouver la plus recente
- `cleanup_old_backups` : purger au-dela de RETENTION
- `backup_before_apply` : sauvegarder .zshrc + starship.toml + pimpmyshell.yaml
- `restore_interactive` : restauration interactive (selection ou derniere)
**Complexite**: Moyenne
**→ depend de**: T002

### T041 - [US4] Ecrire les tests de backup
**Fichier**: `tests/backup.bats`
**Description**: Tests : backup_file cree fichier horodate, restore_file restaure, list_backups liste, cleanup_old_backups purge, backup_before_apply sauvegarde les 3 fichiers.
**Complexite**: Moyenne
**→ depend de**: T003, T040

### T042 - [US4] Implementer les commandes backup et restore dans le CLI
**Fichier**: `bin/pimpmyshell` (sections backup/restore)
**Description**: Commandes :
- `pimpmyshell backup` : sauvegarde manuelle
- `pimpmyshell restore` : restauration interactive
- `pimpmyshell restore --latest` : restauration derniere sauvegarde
**Complexite**: Simple
**→ depend de**: T005, T040

### T043 - [US4] Integrer backup automatique avant apply
**Fichier**: `bin/pimpmyshell` (dans commande apply)
**Description**: Appeler `backup_before_apply` dans le flux apply, sauf si `--no-backup` est passe.
**Complexite**: Simple
**→ depend de**: T038, T040

---

## Phase 9 : Installation

> Prerequis : Phases 7 et 8 terminees.

### T044 - [US5] Implementer install.sh
**Fichier**: `install.sh`
**Description**: Script d'installation inspire de pimpmytmux/install.sh :
- Detection plateforme et pkg manager
- Verification prerequis (zsh, git, bash 4+)
- Installation yq si absent
- Installation oh-my-zsh si absent
- Clone ou mise a jour du repo dans `~/.pimpmyshell`
- Symlink CLI vers `~/.local/bin/pimpmyshell`
- Ajout `~/.local/bin` au PATH si necessaire
- Installation completions shell
- Copie config exemple si premiere installation
- Information sur zsh comme shell par defaut
- Support uninstall (`--uninstall`)
**Complexite**: Complexe
**→ depend de**: T038

### T045 - [US5] Creer completions/pimpmyshell.zsh
**Fichier**: `completions/pimpmyshell.zsh`
**Description**: Completions zsh inspirees de pimpmytmux/completions/pimpmytmux.zsh :
- Commandes principales avec descriptions
- Sous-commandes (theme list/--list/--preview, tools check/install, profile list/create/switch/delete)
- Completion dynamique des themes (depuis themes/)
- Completion dynamique des profils (depuis profiles/)
**Complexite**: Moyenne
**→ depend de**: T005

### T046 - [US5] Creer completions/pimpmyshell.bash
**Fichier**: `completions/pimpmyshell.bash`
**Description**: Completions bash equivalentes (plus simples).
**Complexite**: Simple
**→ depend de**: T005

---

## Phase 10 : Doctor (P2)

> Prerequis : Phase 9 terminee.

### T047 - [US8] Implementer lib/doctor.sh
**Fichier**: `lib/doctor.sh`
**Description**: Diagnostic complet :
- Guard (`_PIMPMYSHELL_DOCTOR_LOADED`)
- `check_shell` : verifier zsh installe et shell par defaut
- `check_framework` : verifier oh-my-zsh installe
- `check_tools` : verifier chaque outil requis/recommande
- `check_plugins` : verifier chaque plugin reference installe
- `check_theme` : verifier fichiers theme presents (starship.toml, eza)
- `check_config` : verifier pimpmyshell.yaml valide
- `check_nerd_font` : detecter Nerd Font (heuristique)
- `check_true_color` : verifier support true color terminal
- `run_doctor` : orchestrer tous les checks avec rapport colore (OK/WARN/FAIL)
**Complexite**: Moyenne
**→ depend de**: T009, T012, T019, T021

### T048 - [US8] Ecrire les tests de doctor
**Fichier**: `tests/doctor.bats`
**Description**: Tests avec mocks : outil manquant detecte, plugin absent detecte, config invalide detecte, tout OK.
**Complexite**: Moyenne
**→ depend de**: T003, T047

### T049 - [US8] Implementer la commande doctor dans le CLI
**Fichier**: `bin/pimpmyshell` (section doctor)
**Description**: `pimpmyshell doctor` lance `run_doctor` et affiche le rapport.
**Complexite**: Simple
**→ depend de**: T005, T047

---

## Phase 11 : Wizard (P2)

> Prerequis : Phase 9 terminee.

### T050 - [US6] Implementer lib/wizard.sh
**Fichier**: `lib/wizard.sh`
**Description**: Assistant interactif inspire de pimpmytmux/lib/wizard.sh :
- Guard (`_PIMPMYSHELL_WIZARD_LOADED`)
- Detection gum (TUI toolkit) pour UX amelioree, fallback read/select
- `_wizard_choose` : selection simple
- `_wizard_choose_multi` : selection multiple
- `_wizard_confirm` : confirmation oui/non
- `_wizard_input` : saisie texte
- Steps :
  1. Welcome + check prerequisites
  2. Choix du theme (avec preview couleurs)
  3. Choix des plugins oh-my-zsh
  4. Choix des outils a installer
  5. Choix des groupes d'aliases
  6. Choix des integrations
  7. Preview config + confirmation
  8. Generation pimpmyshell.yaml
  9. Proposition d'appliquer immediatement
**Complexite**: Complexe
**→ depend de**: T009, T012, T021

### T051 - [US6] Implementer la commande wizard dans le CLI
**Fichier**: `bin/pimpmyshell` (section wizard)
**Description**: `pimpmyshell wizard` lance `run_wizard`.
**Complexite**: Simple
**→ depend de**: T005, T050

---

## Phase 12 : Profils (P2)

> Prerequis : Phase 9 terminee.

### T052 - [US7] Implementer lib/profiles.sh
**Fichier**: `lib/profiles.sh`
**Description**: Gestion profils inspire de pimpmytmux/lib/profiles.sh :
- Guard (`_PIMPMYSHELL_PROFILES_LOADED`)
- `PROFILES_DIR` : `~/.config/pimpmyshell/profiles/`
- `list_profiles` : lister les profils
- `get_current_profile` : profil actif (via symlink current)
- `profile_exists` : verifier existence
- `create_profile` : copier config actuelle dans profil nomme
- `switch_profile` : changer symlink current + apply
- `delete_profile` : supprimer profil (empecher suppression actif)
**Complexite**: Moyenne
**→ depend de**: T009

### T053 - [US7] Ecrire les tests de profils
**Fichier**: `tests/profiles.bats`
**Description**: Tests : create, list, switch, delete, suppression profil actif impossible.
**Complexite**: Moyenne
**→ depend de**: T003, T052

### T054 - [US7] Implementer la commande profile dans le CLI
**Fichier**: `bin/pimpmyshell` (section profile)
**Description**: Sous-commandes :
- `pimpmyshell profile list`
- `pimpmyshell profile create <nom>`
- `pimpmyshell profile switch <nom>`
- `pimpmyshell profile delete <nom>`
**Complexite**: Simple
**→ depend de**: T005, T052

---

## Phase 13 : Preview & Update (P3)

> Prerequis : Phases 10-12 terminees.

### T055 - [US9] Implementer preview theme
**Fichier**: `lib/themes.sh` (ajout fonctions)
**Description**: Inspire de pimpmytmux/lib/themes.sh preview_theme :
- `preview_theme` : afficher apercu couleurs (swatches) d'un theme
- `theme_gallery` : afficher les 7 themes en galerie interactive
- Integration dans `pimpmyshell theme --preview`
**Complexite**: Moyenne
**→ depend de**: T012

### T056 - [US10] Implementer la commande update
**Fichier**: `bin/pimpmyshell` (section update)
**Description**: `pimpmyshell update` : git pull dans le repo installe, re-apply si config existe.
**Complexite**: Simple
**→ depend de**: T005

---

## Phase 14 : CI/CD & Documentation

> Prerequis : Toutes les phases precedentes.

### T057 - [P] Creer .github/workflows/test.yml
**Fichier**: `.github/workflows/test.yml`
**Description**: CI GitHub Actions :
- Trigger : push + PR
- Matrix : ubuntu-latest + macos-latest
- Steps : checkout, install bats, install yq, shellcheck, run tests
**Complexite**: Simple

### T058 - [P] Creer .github/workflows/release.yml
**Fichier**: `.github/workflows/release.yml`
**Description**: Release sur tag v* : creer release GitHub avec changelog.
**Complexite**: Simple

### T059 - Creer README.md
**Fichier**: `README.md`
**Description**: Documentation complete : badge, description, features, installation rapide, configuration, themes (avec screenshots), commandes, FAQ.
**Complexite**: Moyenne
**→ depend de**: T044

### T060 - Creer CHANGELOG.md
**Fichier**: `CHANGELOG.md`
**Description**: Changelog initial v0.1.0 suivant Keep a Changelog.
**Complexite**: Simple

---

## Resume par priorite

### MVP (P1) : 43 taches
- Phase 1 (Fondation) : T001-T006
- Phase 2 (Config & Validation) : T007-T011
- Phase 3 (Themes) : T012-T018
- Phase 4 (Plugins) : T019-T020
- Phase 5 (Outils) : T021-T024
- Phase 6 (Modules) : T025-T035
- Phase 7 (Apply) : T036-T039
- Phase 8 (Backup) : T040-T043
- Phase 9 (Install) : T044-T046

### P2 : 8 taches
- Phase 10 (Doctor) : T047-T049
- Phase 11 (Wizard) : T050-T051
- Phase 12 (Profils) : T052-T054

### P3 : 2 taches
- Phase 13 (Preview/Update) : T055-T056

### Transversal : 4 taches
- Phase 14 (CI/CD & Docs) : T057-T060

### Total : 60 taches

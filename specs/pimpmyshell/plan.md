# Plan d'implementation : pimpmyshell

**Date**: 2026-01-29
**Spec**: specs/pimpmyshell/spec.md
**Complexite**: Complexe (>30 fichiers, architecture modulaire complete)

## Resume

Construire un outil CLI en Bash modulaire qui genere une configuration zsh complete a partir d'un fichier YAML. L'architecture reprend les patterns eprouves de pimpmytmux (guard loading, module system, XDG, BATS tests) et integre les themes existants de claude-socle (Starship, eza, GNOME Terminal).

## Contexte Technique

| Aspect | Choix |
|--------|-------|
| Langage | Bash 4.0+ |
| Parsing YAML | yq (Go version) |
| Shell cible | zsh + oh-my-zsh |
| Prompt | Starship |
| Tests | BATS (Bash Automated Testing System) |
| CI/CD | GitHub Actions |
| Standard | XDG Base Directory |

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     bin/pimpmyshell (CLI)                     │
│  apply | theme | tools | backup | restore | doctor | wizard  │
└──────────┬───────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                      lib/ (Core Libraries)                    │
├──────────┬──────────┬──────────┬──────────┬─────────────────┤
│ core.sh  │config.sh │themes.sh │backup.sh │ validation.sh   │
│ logging  │yq parse  │load theme│backup/   │ validate YAML   │
│ platform │generate  │starship  │restore   │ check values    │
│ modules  │zshrc     │eza/gnome │cleanup   │                 │
├──────────┼──────────┼──────────┼──────────┼─────────────────┤
│tools.sh  │plugins.sh│profiles.sh│wizard.sh│                 │
│pkg mgr   │omz mgr  │create/   │interactive│                │
│install   │clone     │switch    │setup     │                 │
└──────────┴──────────┴──────────┴──────────┴─────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                    modules/ (Feature Modules)                 │
├────────────────────┬─────────────────────────────────────────┤
│ aliases/           │ integrations/                            │
│  git.sh            │  fzf.sh                                 │
│  docker.sh         │  mise.sh                                │
│  kubernetes.sh     │  tmux.sh                                │
│  navigation.sh     │  zoxide.sh                              │
│  files.sh          │  delta.sh                               │
└────────────────────┴─────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                     themes/ (7 Theme YAMLs)                   │
│  cyberpunk | matrix | dracula | catppuccin | nord | gruvbox  │
│                        tokyo-night                            │
│                                                               │
│  Chaque theme genere :                                        │
│  - starship.toml (prompt)                                    │
│  - EZA_COLORS (listing)                                      │
│  - GNOME Terminal profile (si disponible)                    │
└──────────────────────────────────────────────────────────────┘
```

## Fichiers Impactes

### A creer

#### Structure racine
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `bin/pimpmyshell` | CLI principal, routing des commandes | US1-US10 |
| `install.sh` | Installeur one-shot | US5 |
| `pimpmyshell.yaml.example` | Configuration exemple documentee | US1 |
| `CHANGELOG.md` | Historique des versions | - |
| `README.md` | Documentation utilisateur | - |
| `LICENSE` | GPL v3 | - |

#### Libraries core (lib/)
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `lib/core.sh` | Logging, platform detection, module loading, XDG dirs | US1-US10 |
| `lib/config.sh` | Parsing YAML, generation .zshrc, valeurs par defaut | US1 |
| `lib/themes.sh` | Chargement themes, generation starship/eza/gnome | US3 |
| `lib/plugins.sh` | Installation/gestion plugins oh-my-zsh | US1 |
| `lib/tools.sh` | Detection pkg manager, installation outils | US2 |
| `lib/backup.sh` | Backup/restore, cleanup, listing | US4 |
| `lib/validation.sh` | Validation YAML, verification valeurs | US1 |
| `lib/profiles.sh` | Creation, switch, suppression profils | US7 |
| `lib/wizard.sh` | Assistant interactif pas a pas | US6 |
| `lib/doctor.sh` | Diagnostic complet de l'environnement | US8 |

#### Modules aliases (modules/aliases/)
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `modules/aliases/git.sh` | Aliases git (ga, gc, gp, gl...) | US1 |
| `modules/aliases/docker.sh` | Aliases docker (dps, dex, dlogs...) | US1 |
| `modules/aliases/kubernetes.sh` | Aliases k8s (kg, kn, kx...) | US1 |
| `modules/aliases/navigation.sh` | Aliases navigation (mkcd, ...) | US1 |
| `modules/aliases/files.sh` | Aliases fichiers eza (ls, ll, la, lt) | US1 |

#### Modules integrations (modules/integrations/)
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `modules/integrations/fzf.sh` | Config fzf (preview, keybindings) | US1 |
| `modules/integrations/mise.sh` | Integration mise | US1 |
| `modules/integrations/tmux.sh` | Integration tmux (auto-start) | US1 |
| `modules/integrations/zoxide.sh` | Config zoxide (cd intelligent) | US1 |
| `modules/integrations/delta.sh` | Config delta (git pager) | US1 |

#### Themes (themes/)
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `themes/cyberpunk.yaml` | Theme cyberpunk (defaut) | US3 |
| `themes/matrix.yaml` | Theme matrix | US3 |
| `themes/dracula.yaml` | Theme dracula | US3 |
| `themes/catppuccin.yaml` | Theme catppuccin | US3 |
| `themes/nord.yaml` | Theme nord | US3 |
| `themes/gruvbox.yaml` | Theme gruvbox | US3 |
| `themes/tokyo-night.yaml` | Theme tokyo-night | US3 |

#### Theme data (themes/data/) - fichiers generes par theme
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `themes/data/starship-cyberpunk.toml` | Config Starship cyberpunk | US3 |
| `themes/data/starship-matrix.toml` | Config Starship matrix | US3 |
| `themes/data/starship-dracula.toml` | Config Starship dracula | US3 |
| `themes/data/starship-catppuccin.toml` | Config Starship catppuccin | US3 |
| `themes/data/starship-nord.toml` | Config Starship nord | US3 |
| `themes/data/starship-gruvbox.toml` | Config Starship gruvbox | US3 |
| `themes/data/starship-tokyo-night.toml` | Config Starship tokyo-night | US3 |
| `themes/data/eza-cyberpunk.sh` | Couleurs eza cyberpunk | US3 |
| `themes/data/eza-matrix.sh` | Couleurs eza matrix | US3 |
| `themes/data/eza-dracula.sh` | Couleurs eza dracula | US3 |
| `themes/data/eza-catppuccin.sh` | Couleurs eza catppuccin | US3 |
| `themes/data/eza-nord.sh` | Couleurs eza nord | US3 |
| `themes/data/eza-gruvbox.sh` | Couleurs eza gruvbox | US3 |
| `themes/data/eza-tokyo-night.sh` | Couleurs eza tokyo-night | US3 |
| `themes/data/gnome-terminal.sh` | Script application theme GNOME | US3 |

#### Templates
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `templates/zshrc.template` | Template .zshrc avec marqueurs | US1 |

#### Completions
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `completions/pimpmyshell.zsh` | Completions zsh | US5 |
| `completions/pimpmyshell.bash` | Completions bash | US5 |

#### Tests (tests/)
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `tests/test_helper.bash` | Setup/teardown, assertions | US1-US10 |
| `tests/core.bats` | Tests lib/core.sh | US1 |
| `tests/config.bats` | Tests lib/config.sh | US1 |
| `tests/themes.bats` | Tests lib/themes.sh | US3 |
| `tests/plugins.bats` | Tests lib/plugins.sh | US1 |
| `tests/tools.bats` | Tests lib/tools.sh | US2 |
| `tests/backup.bats` | Tests lib/backup.sh | US4 |
| `tests/validation.bats` | Tests lib/validation.sh | US1 |
| `tests/profiles.bats` | Tests lib/profiles.sh | US7 |
| `tests/doctor.bats` | Tests lib/doctor.sh | US8 |
| `tests/aliases.bats` | Tests modules aliases | US1 |
| `tests/integrations.bats` | Tests modules integrations | US1 |

#### CI/CD
| Fichier | Responsabilite | US |
|---------|----------------|----|
| `.github/workflows/test.yml` | CI : lint + tests BATS | - |
| `.github/workflows/release.yml` | Release automatique sur tag | - |
| `.gitignore` | Fichiers ignores | - |

## Phases d'Implementation

### Phase 1 : Fondation [bloquant pour tout le reste]

Objectif : Avoir le squelette du projet avec core.sh fonctionnel, la structure de repertoires, et le framework de tests.

- T001 - [US1] Creer la structure de repertoires du projet
- T002 - [US1] Implementer `lib/core.sh` (logging, platform, XDG, module loading)
- T003 - [US1] Implementer le framework de tests (`tests/test_helper.bash`)
- T004 - [US1] Ecrire les tests de `lib/core.sh` (`tests/core.bats`)
- T005 - [US1] Creer le squelette CLI `bin/pimpmyshell` (routing, help, options globales)
- T006 - Creer `.gitignore`, `LICENSE`

### Phase 2 : Configuration & Validation [bloquant pour US1]

Objectif : Pouvoir lire un fichier YAML et valider sa structure.

- T007 - [US1] Implementer `lib/validation.sh` (validation YAML syntaxe + valeurs)
- T008 - [US1] Ecrire les tests de validation (`tests/validation.bats`)
- T009 - [US1] Implementer `lib/config.sh` (parsing YAML, get_config, config_enabled)
- T010 - [US1] Ecrire les tests de config (`tests/config.bats`)
- T011 - [US1] Creer `pimpmyshell.yaml.example` (config documentee complete)

### Phase 3 : Themes [P - parallele avec Phase 4, 5, 6]

Objectif : Systeme de themes complet avec les 7 themes et les 3 composants.

- T012 - [US3] Implementer `lib/themes.sh` (load_theme, list_themes, theme_get)
- T013 - [US3] Ecrire les tests de themes (`tests/themes.bats`)
- T014 - [P] [US3] Creer les 7 fichiers theme YAML (`themes/*.yaml`) - adapter depuis pimpmytmux
- T015 - [P] [US3] Integrer les 7 fichiers Starship (`themes/data/starship-*.toml`) - copier depuis claude-socle
- T016 - [P] [US3] Integrer les 7 fichiers eza (`themes/data/eza-*.sh`) - copier depuis claude-socle
- T017 - [US3] Implementer generation theme GNOME Terminal (`themes/data/gnome-terminal.sh`)
- T018 - [US3] Implementer la commande `theme` dans le CLI (list, switch, apply)

### Phase 4 : Plugins oh-my-zsh [P - parallele avec Phase 3, 5, 6]

Objectif : Installer et configurer oh-my-zsh et ses plugins.

- T019 - [US1] Implementer `lib/plugins.sh` (install_omz, clone_custom_plugin, list_plugins)
- T020 - [US1] Ecrire les tests de plugins (`tests/plugins.bats`)

### Phase 5 : Outils CLI [P - parallele avec Phase 3, 4, 6]

Objectif : Detecter le package manager et installer les outils.

- T021 - [US2] Implementer `lib/tools.sh` (detect_pkg_manager, install_tool, check_tool)
- T022 - [US2] Definir le registre des outils (nom, commande, paquets par plateforme, installeur alternatif)
- T023 - [US2] Ecrire les tests de tools (`tests/tools.bats`)
- T024 - [US2] Implementer la commande `tools` dans le CLI (install, check)

### Phase 6 : Modules aliases & integrations [P - parallele avec Phase 3, 4, 5]

Objectif : Les alias groups et les integrations fzf/mise/tmux/zoxide/delta.

- T025 - [P] [US1] Creer `modules/aliases/git.sh`
- T026 - [P] [US1] Creer `modules/aliases/docker.sh`
- T027 - [P] [US1] Creer `modules/aliases/kubernetes.sh`
- T028 - [P] [US1] Creer `modules/aliases/navigation.sh`
- T029 - [P] [US1] Creer `modules/aliases/files.sh`
- T030 - [P] [US1] Creer `modules/integrations/fzf.sh` (preview bat/eza, keybindings)
- T031 - [P] [US1] Creer `modules/integrations/mise.sh`
- T032 - [P] [US1] Creer `modules/integrations/tmux.sh`
- T033 - [P] [US1] Creer `modules/integrations/zoxide.sh`
- T034 - [P] [US1] Creer `modules/integrations/delta.sh`
- T035 - [US1] Ecrire les tests aliases et integrations (`tests/aliases.bats`, `tests/integrations.bats`)

### Phase 7 : Generation .zshrc (apply) [depend de Phase 2, 3, 4, 5, 6]

Objectif : La commande `apply` genere un .zshrc complet et fonctionnel.

- T036 - [US1] Creer `templates/zshrc.template` (avec marqueurs pimpmyshell et section user custom)
- T037 - [US1] Implementer la generation .zshrc dans `lib/config.sh` (generate_zshrc)
- T038 - [US1] Implementer la commande `apply` dans le CLI (orchestration complete)
- T039 - [US1] Test d'integration : apply avec config complete → .zshrc valide

### Phase 8 : Backup/Restore [P - parallele avec Phase 7]

Objectif : Sauvegarde et restauration automatique.

- T040 - [US4] Implementer `lib/backup.sh` (backup_config, restore_backup, list_backups, cleanup_old)
- T041 - [US4] Ecrire les tests de backup (`tests/backup.bats`)
- T042 - [US4] Implementer les commandes `backup` et `restore` dans le CLI
- T043 - [US4] Integrer backup automatique avant apply

### Phase 9 : Installation [depend de Phase 7, 8]

Objectif : Script d'installation one-shot.

- T044 - [US5] Implementer `install.sh` (detection systeme, deps, install, completions)
- T045 - [US5] Creer `completions/pimpmyshell.zsh`
- T046 - [US5] Creer `completions/pimpmyshell.bash`

### Phase 10 : Doctor (P2) [depend de Phase 9]

Objectif : Diagnostic automatique.

- T047 - [US8] Implementer `lib/doctor.sh` (check_shell, check_tools, check_plugins, check_config)
- T048 - [US8] Ecrire les tests de doctor (`tests/doctor.bats`)
- T049 - [US8] Implementer la commande `doctor` dans le CLI

### Phase 11 : Wizard (P2) [depend de Phase 9]

Objectif : Assistant interactif.

- T050 - [US6] Implementer `lib/wizard.sh` (steps: theme, plugins, tools, aliases, apply)
- T051 - [US6] Implementer la commande `wizard` dans le CLI

### Phase 12 : Profils (P2) [depend de Phase 9]

Objectif : Gestion multi-profils.

- T052 - [US7] Implementer `lib/profiles.sh` (create, switch, list, delete)
- T053 - [US7] Ecrire les tests de profils (`tests/profiles.bats`)
- T054 - [US7] Implementer la commande `profile` dans le CLI

### Phase 13 : Preview & Update (P3)

Objectif : Previsualisation themes et mise a jour.

- T055 - [US9] Implementer preview theme dans `lib/themes.sh` (preview_theme, gallery)
- T056 - [US10] Implementer la commande `update` dans le CLI

### Phase 14 : CI/CD & Documentation

Objectif : Automatisation et documentation.

- T057 - [P] Creer `.github/workflows/test.yml` (shellcheck + BATS)
- T058 - [P] Creer `.github/workflows/release.yml`
- T059 - Creer `README.md`
- T060 - Creer `CHANGELOG.md`

## Diagramme de dependances

```
Phase 1 (Fondation)
    │
    ▼
Phase 2 (Config & Validation)
    │
    ├──────────┬──────────┬──────────┐
    ▼          ▼          ▼          ▼
Phase 3    Phase 4    Phase 5    Phase 6
(Themes)   (Plugins)  (Tools)    (Modules)
    │          │          │          │
    └──────────┴──────────┴──────────┘
                    │
                    ▼
              Phase 7 (Apply)  ◄──── Phase 8 (Backup) [P]
                    │
                    ▼
              Phase 9 (Install)
                    │
         ┌──────────┼──────────┐
         ▼          ▼          ▼
    Phase 10    Phase 11   Phase 12
    (Doctor)    (Wizard)   (Profiles)
         │          │          │
         └──────────┴──────────┘
                    │
                    ▼
              Phase 13 (P3: Preview/Update)
                    │
                    ▼
              Phase 14 (CI/CD & Docs)
```

## Strategie de copie des themes existants

Les fichiers de themes seront **copies et adaptes** depuis les projets existants :

| Source | Destination | Adaptation |
|--------|-------------|------------|
| `claude-socle/scripts/themes/starship-themes/*.toml` | `themes/data/starship-*.toml` | Aucune (copie directe) |
| `claude-socle/scripts/themes/eza-*.sh` | `themes/data/eza-*.sh` | Retirer aliases (geres par modules/aliases/files.sh) |
| `claude-socle/scripts/themes/install-gnome-terminal-theme.sh` | `themes/data/gnome-terminal.sh` | Adapter en fonction library |
| `pimpmytmux/themes/*.yaml` | `themes/*.yaml` | Adapter structure (retirer tmux-specific, ajouter shell-specific) |

## Risques et Mitigations

| # | Risque | Impact | Probabilite | Mitigation |
|---|--------|--------|-------------|------------|
| R1 | yq pas installe et pas installable | Bloquant | Faible | Fallback sur parseur YAML minimal en bash (section par section) |
| R2 | Conflit avec .zshrc existant complexe | Moyen | Moyenne | Marqueurs `>>> pimpmyshell >>>` + preservation section user |
| R3 | Noms de paquets differents par distro | Moyen | Haute | Registre complet avec mapping par pkg manager + fallback binaire |
| R4 | oh-my-zsh deja installe avec config custom | Moyen | Haute | Detection existant, merge plugins sans ecraser custom |
| R5 | Pas de sudo pour installer les outils | Moyen | Moyenne | Installation userspace (~/.local/bin, cargo, pip) |
| R6 | GNOME Terminal absent (KDE, macOS, etc.) | Faible | Haute | Detection silencieuse, skip sans erreur |

## Criteres de Validation

- [ ] `pimpmyshell apply` genere un .zshrc fonctionnel avec theme cyberpunk
- [ ] `pimpmyshell theme matrix` change coheremment les 3 composants
- [ ] `pimpmyshell tools check` liste les outils installes/manquants
- [ ] `pimpmyshell backup` + `pimpmyshell restore` fait un aller-retour sans perte
- [ ] `./install.sh` fonctionne sur Ubuntu 22.04+ propre
- [ ] Tests BATS passent a 80%+ de couverture
- [ ] Idempotence : `apply` 2x produit le meme resultat
- [ ] Pas de secret commite (shellcheck + review)

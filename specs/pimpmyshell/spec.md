# Specification : pimpmyshell

**Branche**: `feature/pimpmyshell-v1`
**Date**: 2026-01-29
**Statut**: Draft

## Resume

pimpmyshell est un outil en ligne de commande qui configure automatiquement un environnement shell zsh complet, coherent et esthetique. A partir d'un unique fichier de configuration YAML, l'utilisateur obtient un terminal moderne avec prompt stylise, outils CLI nouvelle generation, plugins zsh, aliases organises et theme visuel unifie -- le tout en une seule commande.

Le theme par defaut est **cyberpunk** (neon pink & cyan, Night City vibes).

---

## User Stories (prioritisees)

### US1 - Appliquer une configuration shell complete (Priorite: P1) MVP

**En tant qu'** utilisateur du terminal
**Je veux** appliquer ma configuration shell a partir d'un fichier YAML
**Afin de** obtenir un environnement zsh complet et fonctionnel sans configuration manuelle

**Pourquoi P1**: C'est la fonctionnalite fondamentale du projet. Sans elle, rien d'autre n'a de sens.

**Test independant**: Lancer `pimpmyshell apply` avec un fichier YAML valide et verifier que le shell est configure (prompt, aliases, plugins actifs).

**Criteres d'acceptation**:

1. **Etant donne** un fichier `pimpmyshell.yaml` valide dans le repertoire de configuration, **Quand** l'utilisateur lance `pimpmyshell apply`, **Alors** le fichier `.zshrc` est genere avec tous les elements configures (framework, prompt, plugins, aliases, integrations).
2. **Etant donne** une configuration qui reference des plugins oh-my-zsh custom (ex: zsh-autosuggestions), **Quand** `pimpmyshell apply` est lance, **Alors** les plugins manquants sont automatiquement clones dans le repertoire custom d'oh-my-zsh.
3. **Etant donne** une configuration valide, **Quand** `pimpmyshell apply` est lance deux fois de suite, **Alors** le resultat est identique (idempotence).
4. **Etant donne** qu'aucun fichier de configuration n'existe, **Quand** `pimpmyshell apply` est lance, **Alors** un message d'erreur clair indique comment creer la configuration (avec reference au wizard ou au fichier exemple).

---

### US2 - Installer les outils CLI modernes (Priorite: P1) MVP

**En tant qu'** utilisateur du terminal
**Je veux** que les outils modernes (eza, bat, fzf, starship, etc.) soient installes automatiquement
**Afin de** ne pas avoir a chercher et installer chaque outil manuellement

**Pourquoi P1**: Les outils sont indispensables au bon fonctionnement de la configuration generee. Sans eux, les aliases et integrations ne fonctionnent pas.

**Test independant**: Lancer `pimpmyshell tools install` et verifier que les outils listes sont disponibles.

**Criteres d'acceptation**:

1. **Etant donne** une liste d'outils requis dans la configuration, **Quand** `pimpmyshell tools install` est lance, **Alors** chaque outil manquant est installe via le gestionnaire de paquets du systeme.
2. **Etant donne** un outil deja installe, **Quand** `pimpmyshell tools install` est lance, **Alors** l'outil est ignore (pas de reinstallation).
3. **Etant donne** un systeme Linux avec apt, **Quand** les outils sont installes, **Alors** le gestionnaire apt est utilise. De meme pour dnf, pacman ou brew selon le systeme.
4. **Etant donne** un outil qui ne peut pas etre installe via le gestionnaire systeme (ex: starship), **Quand** l'installation est lancee, **Alors** un installeur alternatif est utilise (binaire, cargo, script officiel).
5. **Etant donne** une configuration avec des outils "recommandes", **Quand** `pimpmyshell tools install` est lance, **Alors** l'utilisateur est informe des outils recommandes non installes et peut choisir de les installer.
6. **Etant donne** un outil qui echoue a s'installer, **Quand** l'erreur survient, **Alors** un message clair indique le probleme et les outils restants continuent a s'installer.

---

### US3 - Appliquer un theme visuel coherent (Priorite: P1) MVP

**En tant qu'** utilisateur du terminal
**Je veux** appliquer un theme visuel qui colore de maniere coherente le prompt, le listing de fichiers et le terminal
**Afin d'** avoir un environnement visuellement harmonieux et agreable

**Pourquoi P1**: L'identite visuelle est au coeur de la proposition de valeur ("pimp my shell"). Le theme cyberpunk par defaut est le premier element percu.

**Test independant**: Lancer `pimpmyshell theme cyberpunk` et verifier que le prompt Starship, les couleurs eza et le terminal GNOME utilisent la meme palette.

**Criteres d'acceptation**:

1. **Etant donne** un theme choisi dans la configuration (ex: cyberpunk), **Quand** `pimpmyshell apply` est lance, **Alors** le fichier de configuration Starship est genere avec la palette du theme.
2. **Etant donne** un theme choisi, **Quand** la configuration est appliquee, **Alors** les couleurs eza sont configurees avec la meme palette.
3. **Etant donne** un environnement GNOME Terminal sur Linux, **Quand** le theme est applique, **Alors** un profil terminal est cree ou mis a jour avec les couleurs du theme.
4. **Etant donne** un environnement sans GNOME Terminal (macOS, autre terminal), **Quand** le theme est applique, **Alors** seuls le prompt et les couleurs eza sont configures, sans erreur.
5. **Etant donne** la commande `pimpmyshell theme --list`, **Quand** elle est lancee, **Alors** la liste des 7 themes disponibles est affichee avec nom et description.
6. **Etant donne** la commande `pimpmyshell theme <nom>`, **Quand** elle est lancee avec un theme valide, **Alors** le theme est change et applique immediatement.

---

### US4 - Sauvegarder et restaurer la configuration (Priorite: P1) MVP

**En tant qu'** utilisateur du terminal
**Je veux** que ma configuration existante soit sauvegardee avant toute modification
**Afin de** pouvoir revenir en arriere si quelque chose ne fonctionne pas

**Pourquoi P1**: La securite des donnees utilisateur est non-negociable. Sans backup, l'utilisateur risque de perdre sa configuration existante.

**Test independant**: Lancer `pimpmyshell backup`, modifier la config, puis `pimpmyshell restore` et verifier le retour a l'etat initial.

**Criteres d'acceptation**:

1. **Etant donne** un fichier `.zshrc` existant, **Quand** `pimpmyshell apply` est lance, **Alors** une sauvegarde horodatee est creee automatiquement avant toute modification.
2. **Etant donne** une configuration Starship existante, **Quand** `pimpmyshell apply` modifie le fichier, **Alors** l'ancien fichier est sauvegarde.
3. **Etant donne** des sauvegardes existantes, **Quand** `pimpmyshell restore` est lance, **Alors** la sauvegarde la plus recente est restauree (ou l'utilisateur choisit parmi les disponibles).
4. **Etant donne** la commande `pimpmyshell backup`, **Quand** elle est lancee manuellement, **Alors** une sauvegarde complete est creee (zshrc, starship, config pimpmyshell).
5. **Etant donne** plus de 10 sauvegardes, **Quand** une nouvelle sauvegarde est creee, **Alors** les plus anciennes sont purgees (garder les 10 dernieres).

---

### US5 - Installer le projet via un script unique (Priorite: P1) MVP

**En tant qu'** utilisateur qui decouvre le projet
**Je veux** installer pimpmyshell en une seule commande
**Afin de** demarrer rapidement sans etapes manuelles complexes

**Pourquoi P1**: L'installation est la porte d'entree. Si elle est compliquee, l'utilisateur abandonne.

**Test independant**: Lancer `./install.sh` sur un systeme vierge et verifier que pimpmyshell est operationnel.

**Criteres d'acceptation**:

1. **Etant donne** un systeme avec zsh installe, **Quand** `./install.sh` est lance, **Alors** pimpmyshell est installe dans le repertoire utilisateur avec la commande `pimpmyshell` disponible.
2. **Etant donne** que oh-my-zsh n'est pas installe, **Quand** l'installation est lancee, **Alors** oh-my-zsh est installe automatiquement.
3. **Etant donne** que zsh n'est pas le shell par defaut, **Quand** l'installation est lancee, **Alors** l'utilisateur est informe et peut choisir de changer son shell par defaut.
4. **Etant donne** que yq n'est pas installe, **Quand** l'installation est lancee, **Alors** yq est installe automatiquement (dependance requise).
5. **Etant donne** une installation reussie, **Quand** l'utilisateur ouvre un nouveau terminal, **Alors** les completions zsh de pimpmyshell sont disponibles.
6. **Etant donne** que pimpmyshell est deja installe, **Quand** `./install.sh` est relance, **Alors** une mise a jour est effectuee sans perte de configuration.

---

### US6 - Configurer le shell via un assistant interactif (Priorite: P2)

**En tant qu'** utilisateur qui ne connait pas les options disponibles
**Je veux** etre guide pas a pas pour creer ma configuration
**Afin de** choisir les bons reglages sans lire de documentation

**Pourquoi P2**: Ameliore fortement l'experience de decouverte mais n'est pas bloquant (on peut editer le YAML manuellement).

**Test independant**: Lancer `pimpmyshell wizard` et repondre aux questions pour generer un fichier de configuration valide.

**Criteres d'acceptation**:

1. **Etant donne** la commande `pimpmyshell wizard`, **Quand** elle est lancee, **Alors** un assistant interactif pose des questions etape par etape (theme, plugins, outils, aliases).
2. **Etant donne** l'etape de choix du theme, **Quand** les themes sont presentes, **Alors** un apercu visuel de chaque theme est affiche.
3. **Etant donne** la fin du wizard, **Quand** l'utilisateur valide ses choix, **Alors** un fichier `pimpmyshell.yaml` valide est genere.
4. **Etant donne** la fin du wizard, **Quand** le fichier est genere, **Alors** l'utilisateur peut choisir d'appliquer la configuration immediatement.
5. **Etant donne** qu'une configuration existe deja, **Quand** le wizard est lance, **Alors** les choix existants sont pre-selectionnes.

---

### US7 - Gerer des profils de configuration (Priorite: P2)

**En tant qu'** utilisateur qui travaille dans differents contextes (perso, travail, serveur)
**Je veux** basculer entre plusieurs configurations
**Afin d'** adapter mon environnement au contexte sans tout reconfigurer

**Pourquoi P2**: Valeur reelle pour les utilisateurs avances mais pas necessaire pour une premiere utilisation.

**Test independant**: Creer un profil "work", un profil "personal", basculer entre les deux et verifier que la configuration change.

**Criteres d'acceptation**:

1. **Etant donne** la commande `pimpmyshell profile create <nom>`, **Quand** elle est lancee, **Alors** un nouveau profil est cree base sur la configuration actuelle.
2. **Etant donne** la commande `pimpmyshell profile switch <nom>`, **Quand** elle est lancee avec un profil existant, **Alors** la configuration est remplacee par celle du profil et appliquee.
3. **Etant donne** la commande `pimpmyshell profile list`, **Quand** elle est lancee, **Alors** la liste des profils est affichee avec le profil actif marque.
4. **Etant donne** la commande `pimpmyshell profile delete <nom>`, **Quand** elle est lancee sur le profil actif, **Alors** un message d'erreur empeche la suppression.

---

### US8 - Diagnostiquer les problemes de configuration (Priorite: P2)

**En tant qu'** utilisateur qui rencontre un probleme
**Je veux** lancer un diagnostic automatique de mon environnement
**Afin d'** identifier et corriger les problemes rapidement

**Pourquoi P2**: Reduit drastiquement le support et aide l'utilisateur a s'auto-depanner.

**Test independant**: Lancer `pimpmyshell doctor` avec un outil manquant et verifier que le probleme est detecte et une solution proposee.

**Criteres d'acceptation**:

1. **Etant donne** la commande `pimpmyshell doctor`, **Quand** elle est lancee, **Alors** un diagnostic complet est effectue (shell, framework, outils, plugins, theme, fichiers de config).
2. **Etant donne** un outil requis manquant, **Quand** le diagnostic s'execute, **Alors** le probleme est signale avec la commande pour l'installer.
3. **Etant donne** un plugin oh-my-zsh reference mais non installe, **Quand** le diagnostic s'execute, **Alors** le probleme est signale avec la solution.
4. **Etant donne** un fichier de configuration invalide, **Quand** le diagnostic s'execute, **Alors** les erreurs de syntaxe ou de valeurs sont signalees avec la ligne concernee.
5. **Etant donne** que tout est correct, **Quand** le diagnostic s'execute, **Alors** un message de confirmation est affiche.

---

### US9 - Previsualiser les themes avant application (Priorite: P3)

**En tant qu'** utilisateur curieux
**Je veux** voir a quoi ressemble un theme avant de l'appliquer
**Afin de** choisir le theme qui me plait le plus

**Pourquoi P3**: Confort d'utilisation, pas indispensable (on peut appliquer puis changer).

**Test independant**: Lancer `pimpmyshell theme --preview` et verifier que les 7 themes sont presentes visuellement.

**Criteres d'acceptation**:

1. **Etant donne** la commande `pimpmyshell theme --preview`, **Quand** elle est lancee, **Alors** une galerie affiche les 7 themes avec un apercu des couleurs et du prompt.
2. **Etant donne** la galerie de themes, **Quand** l'utilisateur selectionne un theme, **Alors** il peut choisir de l'appliquer immediatement.

---

### US10 - Mettre a jour pimpmyshell (Priorite: P3)

**En tant qu'** utilisateur avec une version installee
**Je veux** mettre a jour vers la derniere version
**Afin de** beneficier des nouveaux themes, outils et corrections

**Pourquoi P3**: Important a terme mais pas pour le lancement initial.

**Test independant**: Lancer `pimpmyshell update` et verifier que la derniere version est telechargee.

**Criteres d'acceptation**:

1. **Etant donne** la commande `pimpmyshell update`, **Quand** une nouvelle version est disponible, **Alors** le code est mis a jour et la configuration re-appliquee.
2. **Etant donne** la commande `pimpmyshell update`, **Quand** aucune mise a jour n'est disponible, **Alors** un message confirme que la version est a jour.
3. **Etant donne** une mise a jour qui modifie le format de configuration, **Quand** la mise a jour est appliquee, **Alors** une migration automatique est proposee.

---

## Exigences Fonctionnelles

### Configuration

- **EF-001**: Le systeme DOIT lire la configuration depuis un fichier YAML unique (`pimpmyshell.yaml`).
- **EF-002**: Le systeme DOIT generer un fichier `.zshrc` complet a partir de la configuration YAML.
- **EF-003**: Le systeme DOIT supporter la validation du fichier de configuration avant application.
- **EF-004**: Le systeme DOIT fournir un fichier de configuration exemple (`pimpmyshell.yaml.example`).

### Framework Shell

- **EF-010**: Le systeme DOIT installer oh-my-zsh si absent et configure dans le YAML.
- **EF-011**: Le systeme DOIT configurer les plugins oh-my-zsh standard (git, fzf, tmux, docker, kubectl, extract, web-search, wd, mise, eza).
- **EF-012**: Le systeme DOIT cloner et configurer les plugins oh-my-zsh custom (zsh-autosuggestions, zsh-syntax-highlighting, zsh-bat).
- **EF-013**: Le systeme DOIT supporter l'ajout de plugins personnalises via la configuration.

### Prompt

- **EF-020**: Le systeme DOIT configurer Starship comme moteur de prompt par defaut.
- **EF-021**: Le systeme DOIT generer un fichier `starship.toml` conforme au theme choisi.
- **EF-022**: Le systeme DOIT supporter les indicateurs de langage (Node, Python, Go, Rust, Docker, Kubernetes).
- **EF-023**: Le systeme DOIT supporter les informations Git dans le prompt (branche, statut).

### Themes

- **EF-030**: Le systeme DOIT fournir 7 themes : cyberpunk (defaut), matrix, dracula, catppuccin, nord, gruvbox, tokyo-night.
- **EF-031**: Chaque theme DOIT configurer de maniere coherente : le prompt Starship, les couleurs eza, et le terminal GNOME (si disponible).
- **EF-032**: Le systeme DOIT permettre de changer de theme via une commande unique (`pimpmyshell theme <nom>`).
- **EF-033**: Le systeme DOIT supporter les separateurs Powerline et les icones Nerd Font dans les themes.

### Outils

- **EF-040**: Le systeme DOIT detecter le gestionnaire de paquets du systeme (apt, dnf, pacman, brew).
- **EF-041**: Le systeme DOIT installer les outils requis : eza, bat, fzf, starship.
- **EF-042**: Le systeme DOIT proposer les outils recommandes : fd, ripgrep, zoxide, delta, tldr, dust, duf, btop, hyperfine.
- **EF-043**: Le systeme DOIT gerer les noms alternatifs de paquets (ex: `fdfind` vs `fd` sur Debian/Ubuntu, `batcat` vs `bat`).
- **EF-044**: Le systeme DOIT utiliser des installeurs alternatifs quand le paquet n'est pas dans le gestionnaire systeme.

### Aliases

- **EF-050**: Le systeme DOIT fournir des groupes d'aliases configurables : git, docker, kubernetes, navigation, files.
- **EF-051**: Les aliases de fichiers DOIVENT utiliser eza (avec icones, git, group-directories-first).
- **EF-052**: Le systeme DOIT permettre d'activer/desactiver chaque groupe d'aliases individuellement.

### Integrations

- **EF-060**: Le systeme DOIT configurer fzf avec preview (bat pour fichiers, eza pour repertoires).
- **EF-061**: Le systeme DOIT configurer les raccourcis fzf (Ctrl+T, Alt+C, Ctrl+R).
- **EF-062**: Le systeme DOIT supporter l'integration tmux (auto-start optionnel).
- **EF-063**: Le systeme DOIT supporter l'integration mise (gestionnaire de runtimes).
- **EF-064**: Le systeme DOIT configurer zoxide (remplacement intelligent de cd) si installe.
- **EF-065**: Le systeme DOIT configurer delta comme pager git diff si installe.

### Operationnel

- **EF-070**: Le systeme DOIT suivre le standard XDG Base Directory (config dans `~/.config/pimpmyshell/`, donnees dans `~/.local/share/pimpmyshell/`, cache dans `~/.cache/pimpmyshell/`).
- **EF-071**: Le systeme DOIT fournir des completions shell (zsh et bash).
- **EF-072**: Le systeme DOIT supporter les options globales : `--verbose`, `--debug`, `--dry-run`, `--quiet`, `--no-backup`.
- **EF-073**: Le systeme DOIT afficher des messages de log colores et structures (info, success, warning, error).
- **EF-074**: Le systeme DOIT respecter la variable `NO_COLOR` pour desactiver les couleurs.

---

## Cas Limites (Edge Cases)

### Installation et systeme

- Que se passe-t-il quand zsh n'est pas installe ? → Message d'erreur avec instructions d'installation pour le systeme detecte.
- Que se passe-t-il quand le gestionnaire de paquets n'est pas detecte ? → Message d'erreur listant les gestionnaires supportes et la possibilite de specifier manuellement via le YAML.
- Que se passe-t-il sur WSL ? → Detection automatique et adaptation (clipboard wsl, chemins).
- Que se passe-t-il sans connexion internet ? → Les outils deja installes fonctionnent, les installations echouent avec message clair.
- Que se passe-t-il si l'utilisateur n'a pas les droits sudo ? → Installer dans l'espace utilisateur quand possible (cargo, pip, binaires dans ~/.local/bin).

### Configuration

- Que se passe-t-il si le YAML est invalide (syntaxe) ? → Message d'erreur avec le numero de ligne et la nature du probleme.
- Que se passe-t-il si un theme reference n'existe pas ? → Message d'erreur listant les themes disponibles.
- Que se passe-t-il si un plugin reference n'existe pas ? → Avertissement mais poursuite de l'application.
- Que se passe-t-il si le fichier YAML est vide ? → Application des valeurs par defaut (theme cyberpunk, plugins essentiels).
- Que se passe-t-il si le .zshrc existant contient du contenu personnalise ? → Le contenu est preserve dans une section dediee ("user custom" encadree par des marqueurs).

### Themes

- Que se passe-t-il si Nerd Fonts n'est pas installe ? → Les icones sont degradees en caracteres ASCII, un avertissement est affiche.
- Que se passe-t-il si le terminal ne supporte pas le true color ? → Fallback sur les 256 couleurs.
- Que se passe-t-il si GNOME Terminal n'est pas detecte (KDE, Alacritty, WezTerm, iTerm2) ? → Le theme terminal est ignore silencieusement, seuls prompt et eza sont configures.

---

## Entites Cles

| Entite | Description | Attributs cles |
|--------|-------------|----------------|
| **Configuration** | Fichier YAML central | theme, shell, prompt, plugins, tools, aliases, integrations, keybindings, platform |
| **Theme** | Palette visuelle coherente | nom, description, couleurs (bg, fg, accent, accent2, warning, error, success), separateurs, icones |
| **Profil** | Configuration nommee | nom, fichier YAML, date de creation, actif (oui/non) |
| **Outil** | Programme CLI a installer | nom, categorie (requis/recommande), commande de verification, methode d'installation par plateforme |
| **Plugin** | Extension oh-my-zsh | nom, type (standard/custom), URL du depot (si custom) |
| **Groupe d'aliases** | Ensemble d'aliases thematiques | nom (git, docker, k8s, navigation, files), liste d'aliases |
| **Sauvegarde** | Snapshot de configuration | horodatage, fichiers sauvegardes, taille |

---

## Criteres de Succes (mesurables)

- **CS-001**: L'installation complete (install.sh + pimpmyshell apply) fonctionne sans erreur sur Ubuntu 22.04+ et macOS 14+.
- **CS-002**: `pimpmyshell apply` est idempotent : 2 executions successives produisent le meme resultat.
- **CS-003**: Changer de theme (`pimpmyshell theme <nom>`) modifie coheremment les 3 composants (prompt, eza, terminal) sans intervention manuelle.
- **CS-004**: Un backup automatique est cree avant chaque modification de fichier existant.
- **CS-005**: `pimpmyshell doctor` detecte 100% des problemes courants (outil manquant, plugin absent, config invalide).
- **CS-006**: Le projet atteint 80%+ de couverture de tests (tests BATS).
- **CS-007**: Les 7 themes sont visuellement coherents entre prompt, listing et terminal.

---

## Hors Scope (explicitement exclus)

- **Configuration de tmux** -- couverte par le projet pimpmytmux.
- **Configuration de Neovim/Vim** -- hors perimetre, projet independant.
- **Support de fish shell** -- uniquement zsh en v1.
- **Support de bash comme shell principal** -- les scripts utilisent bash mais la cible est zsh.
- **Themes custom utilisateur** -- v1 fournit 7 themes fixes. L'ajout de themes personnalises sera traite en v2.
- **Synchronisation git des configurations** -- sera traitee dans une future iteration (comme dans pimpmytmux).
- **Support de terminaux non-GNOME (Alacritty, WezTerm, Kitty, iTerm2)** -- v1 supporte GNOME Terminal uniquement pour le theme terminal. Les autres terminaux recoivent prompt + eza.
- **Gestion de Nerd Fonts** -- l'utilisateur doit installer sa Nerd Font manuellement. Le doctor signale l'absence.

---

## Hypotheses et Dependances

### Hypotheses

- L'utilisateur a un acces sudo ou peut installer des paquets dans son espace utilisateur.
- L'utilisateur utilise un terminal supportant le true color (256 couleurs minimum).
- Une connexion internet est disponible pour l'installation initiale des outils et plugins.
- Le systeme cible est Linux (Debian/Ubuntu, Fedora, Arch) ou macOS.
- yq (version Go) est la dependance externe principale pour le parsing YAML.

### Dependances

- **yq** (Go version) -- parsing YAML, installe automatiquement si absent.
- **git** -- clonage des plugins oh-my-zsh custom et installation.
- **curl** ou **wget** -- telechargement d'installeurs (starship, etc.).
- **oh-my-zsh** -- framework de plugins zsh (installe automatiquement).
- **Starship** -- moteur de prompt (installe automatiquement).
- **Themes existants** -- les fichiers de themes Starship et eza proviennent du projet claude-socle et seront integres dans pimpmyshell.

---

## Points de Clarification

> Points resolus par choix eclaires :

- **Choix du moteur de prompt** : Starship est le seul moteur supporte en v1. Powerlevel10k pourra etre ajoute en v2.
- **Gestion du .zshrc existant** : Le contenu personnalise est preserve entre des marqueurs `# >>> pimpmyshell >>>` et `# <<< pimpmyshell <<<`. Le reste du fichier est gere par pimpmyshell.
- **Ordre de priorite des outils** : Les outils "requis" sont installes automatiquement, les "recommandes" sont proposes interactivement.

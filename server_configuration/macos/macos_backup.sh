#!/usr/bin/env bash
# ============================================================================
# macOS Backup Script — Backup system preferences, software lists, configs, etc.
# Usage: bash macos_backup.sh [backup_dir]
# ============================================================================
set -euo pipefail

# ── Source log_message ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_MESSAGE_SH="$REPO_ROOT/log_message/log_message.sh"
source "$LOG_MESSAGE_SH"

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# ── Backup directory ──────────────────────────────────────────────────────────
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_ROOT="${1:-$HOME/macos_backup}"
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

mkdir -p "$BACKUP_DIR"
log_message -t success "Backup directory: $BACKUP_DIR"

# Save system information
{
  echo "Backup Date: $(date)"
  echo "macOS Version: $(sw_vers -productVersion)"
  echo "Build: $(sw_vers -buildVersion)"
  echo "Hostname: $(scutil --get ComputerName 2>/dev/null || hostname)"
  echo "User: $(whoami)"
  echo "Shell: $SHELL"
  echo "Architecture: $(uname -m)"
} > "$BACKUP_DIR/system_info.txt"
log_message -t success "System info saved"

# ============================================================================
# 1. Homebrew
# ============================================================================
log_message -t running "1/9  Homebrew packages"
if need_cmd brew; then
  BREW_DIR="$BACKUP_DIR/homebrew"
  mkdir -p "$BREW_DIR"

  # Brewfile (most convenient format for one-click restore)
  brew bundle dump --file="$BREW_DIR/Brewfile" --force 2>/dev/null || true
  log_message -t success "Brewfile exported"

  # Plain-text lists for manual review
  brew leaves        > "$BREW_DIR/formulae.txt"   2>/dev/null || true
  brew list --cask   > "$BREW_DIR/casks.txt"      2>/dev/null || true
  brew tap           > "$BREW_DIR/taps.txt"       2>/dev/null || true
  log_message -t success "Homebrew formulae / casks / taps lists saved"

  # Homebrew configuration
  brew config > "$BREW_DIR/brew_config.txt" 2>/dev/null || true
else
  log_message -t warning "Homebrew not installed, skipping"
fi

# ============================================================================
# 2. Mac App Store apps
# ============================================================================
log_message -t running "2/9  Mac App Store apps"
if need_cmd mas; then
  mas list > "$BACKUP_DIR/mas_apps.txt" 2>/dev/null || true
  log_message -t success "App Store app list saved"
else
  log_message -t warning "mas not installed (brew install mas), skipping App Store backup"
fi

# ============================================================================
# 3. macOS system preferences (defaults)
# ============================================================================
log_message -t running "3/9  macOS system preferences"
DEFAULTS_DIR="$BACKUP_DIR/defaults"
mkdir -p "$DEFAULTS_DIR"

# Export all defaults (may be large, but most complete)
defaults read > "$DEFAULTS_DIR/defaults_all.plist" 2>/dev/null || true

# Export commonly used domains individually
DOMAINS=(
  NSGlobalDomain
  com.apple.dock
  com.apple.finder
  com.apple.Safari
  com.apple.systempreferences
  com.apple.screensaver
  com.apple.screencapture
  com.apple.menuextra.clock
  com.apple.AppleMultitouchTrackpad
  com.apple.driver.AppleBluetoothMultitouch.trackpad
  com.apple.keyboard
  com.apple.loginwindow
  com.apple.Terminal
  com.apple.TextEdit
  com.apple.ActivityMonitor
  com.apple.WindowManager
)
for domain in "${DOMAINS[@]}"; do
  defaults read "$domain" > "$DEFAULTS_DIR/${domain}.plist" 2>/dev/null || true
done
log_message -t success "System preferences exported"

# ============================================================================
# 4. Dotfiles (configuration files)
# ============================================================================
log_message -t running "4/9  Dotfiles"
DOTFILES_DIR="$BACKUP_DIR/dotfiles"
mkdir -p "$DOTFILES_DIR"

DOTFILES=(
  .zshrc
  .zprofile
  .zshenv
  .bashrc
  .bash_profile
  .profile
  .gitconfig
  .gitignore_global
  .vimrc
  .tmux.conf
  .wgetrc
  .curlrc
  .npmrc
  .condarc
  .Rprofile
  .Renviron
  .p10k.zsh
  .hushlogin
  .editorconfig
)

for f in "${DOTFILES[@]}"; do
  if [[ -f "$HOME/$f" ]]; then
    cp -a "$HOME/$f" "$DOTFILES_DIR/$f"
    log_message -t success "  Backed up ~/$f"
  fi
done

# SSH config (no private keys, config only)
if [[ -d "$HOME/.ssh" ]]; then
  SSH_DIR="$DOTFILES_DIR/.ssh"
  mkdir -p "$SSH_DIR"
  for item in config config.d known_hosts; do
    if [[ -e "$HOME/.ssh/$item" ]]; then
      cp -a "$HOME/.ssh/$item" "$SSH_DIR/" 2>/dev/null || true
    fi
  done
  # List key filenames only, do not copy private keys
  ls -la "$HOME/.ssh/" > "$SSH_DIR/key_list.txt" 2>/dev/null || true
  log_message -t success "  SSH config backed up (private keys excluded)"
fi

# ============================================================================
# 5. VS Code / Cursor
# ============================================================================
log_message -t running "5/9  VS Code / Cursor extensions & settings"
VSCODE_DIR="$BACKUP_DIR/vscode"
mkdir -p "$VSCODE_DIR"

# VS Code
if need_cmd code; then
  code --list-extensions > "$VSCODE_DIR/vscode_extensions.txt" 2>/dev/null || true
  log_message -t success "VS Code extension list saved"
fi
# Copy settings.json & keybindings.json
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_USER_DIR" ]]; then
  for cfg in settings.json keybindings.json snippets; do
    if [[ -e "$VSCODE_USER_DIR/$cfg" ]]; then
      cp -a "$VSCODE_USER_DIR/$cfg" "$VSCODE_DIR/" 2>/dev/null || true
    fi
  done
  log_message -t success "VS Code settings/keybindings backed up"
fi

# Cursor (VS Code fork)
if need_cmd cursor; then
  cursor --list-extensions > "$VSCODE_DIR/cursor_extensions.txt" 2>/dev/null || true
fi
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$CURSOR_USER_DIR" ]]; then
  for cfg in settings.json keybindings.json snippets; do
    if [[ -e "$CURSOR_USER_DIR/$cfg" ]]; then
      cp -a "$CURSOR_USER_DIR/$cfg" "$VSCODE_DIR/cursor_${cfg}" 2>/dev/null || true
    fi
  done
  log_message -t success "Cursor settings backed up"
fi

# ============================================================================
# 6. LaunchAgents / Crontab
# ============================================================================
log_message -t running "6/9  LaunchAgents & Crontab"
LA_DIR="$BACKUP_DIR/launch_agents"
mkdir -p "$LA_DIR"

if [[ -d "$HOME/Library/LaunchAgents" ]]; then
  cp -a "$HOME/Library/LaunchAgents/"*.plist "$LA_DIR/" 2>/dev/null || true
  log_message -t success "User LaunchAgents backed up"
fi

crontab -l > "$BACKUP_DIR/crontab.txt" 2>/dev/null || true
log_message -t success "Crontab backed up"

# ============================================================================
# 7. Terminal & Shell configuration
# ============================================================================
log_message -t running "7/9  Terminal & Shell configuration"
SHELL_DIR="$BACKUP_DIR/shell"
mkdir -p "$SHELL_DIR"

# List oh-my-zsh custom plugins/themes repos
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" ]]; then
  find "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" -maxdepth 3 -name ".git" -type d | \
    while read -r gitdir; do
      repo_dir="$(dirname "$gitdir")"
      origin="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || echo 'unknown')"
      echo "$repo_dir -> $origin"
    done > "$SHELL_DIR/omz_custom_repos.txt" 2>/dev/null || true
  log_message -t success "oh-my-zsh custom repo list saved"
fi

# iTerm2 preferences
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
if [[ -f "$ITERM_PLIST" ]]; then
  cp -a "$ITERM_PLIST" "$SHELL_DIR/" 2>/dev/null || true
  log_message -t success "iTerm2 preferences backed up"
fi

# ============================================================================
# 8. Conda / Python / pip
# ============================================================================
log_message -t running "8/9  Conda / Python / pip environments"
PY_DIR="$BACKUP_DIR/python"
mkdir -p "$PY_DIR"

if need_cmd conda; then
  conda env list > "$PY_DIR/conda_envs.txt" 2>/dev/null || true
  # Export each conda environment
  conda env list --json 2>/dev/null | python3 -c "
import sys, json, os
data = json.load(sys.stdin)
for env_path in data.get('envs', []):
    name = os.path.basename(env_path) or 'base'
    print(name)
" 2>/dev/null | while read -r env_name; do
    conda env export -n "$env_name" > "$PY_DIR/conda_${env_name}.yml" 2>/dev/null || true
  done
  log_message -t success "Conda environments exported"
fi

if need_cmd pip3; then
  pip3 list --format=freeze > "$PY_DIR/pip3_packages.txt" 2>/dev/null || true
  log_message -t success "pip3 package list saved"
fi

# ============================================================================
# 9. Fonts
# ============================================================================
log_message -t running "9/9  User fonts"
FONT_DIR="$BACKUP_DIR/fonts"
if [[ -d "$HOME/Library/Fonts" ]] && [[ -n "$(ls -A "$HOME/Library/Fonts" 2>/dev/null)" ]]; then
  mkdir -p "$FONT_DIR"
  cp -a "$HOME/Library/Fonts/"* "$FONT_DIR/" 2>/dev/null || true
  log_message -t success "User fonts backed up"
else
  log_message -t info "No user fonts found"
fi

# ============================================================================
# 10. Copy restore script into backup
# ============================================================================
log_message -t running "Copying restore.sh into backup"
cp "$SCRIPT_DIR/macos_restore.sh" "$BACKUP_DIR/restore.sh" 2>/dev/null || true
chmod +x "$BACKUP_DIR/restore.sh" 2>/dev/null || true

# ============================================================================
# Done
# ============================================================================
echo ""
log_message -t success "============================================"
log_message -t success "  Backup complete!"
log_message -t success "============================================"
echo ""
log_message -t info "Backup location: $BACKUP_DIR"
echo ""
du -sh "$BACKUP_DIR" 2>/dev/null || true
echo ""
log_message -t info "File listing:"
find "$BACKUP_DIR" -type f | sort | sed "s|$BACKUP_DIR/|  |"
echo ""
log_message -t info "Restore command: bash $BACKUP_DIR/restore.sh $BACKUP_DIR"
echo ""
log_message -t info "Tip: Sync backup directory to external storage or cloud (iCloud, Git repo, etc.)"

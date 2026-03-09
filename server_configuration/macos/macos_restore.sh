#!/usr/bin/env bash
# ============================================================================
# macOS Restore Script — Restore system settings, software, configs from backup
# Usage: bash macos_restore.sh <backup_dir>
#   e.g. bash macos_restore.sh ~/macos_backup/20260302_143000
# ============================================================================
set -euo pipefail

# ── Source log_message ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_MESSAGE_SH="$REPO_ROOT/log_message/log_message.sh"
source "$LOG_MESSAGE_SH"

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# ── Argument check ────────────────────────────────────────────────────────────
BACKUP_DIR="${1:-}"
if [[ -z "$BACKUP_DIR" ]] || [[ ! -d "$BACKUP_DIR" ]]; then
  log_message -t warning "Usage: bash $0 <backup_directory_path>"
  log_message -t warning "Example: bash $0 ~/macos_backup/20260302_143000"
  exit 1
fi

# Convert to absolute path
BACKUP_DIR="$(cd "$BACKUP_DIR" && pwd)"

echo ""
log_message -t running "============================================"
log_message -t running "  macOS System Restore"
log_message -t running "============================================"
echo ""
log_message -t info "Backup source: $BACKUP_DIR"

if [[ -f "$BACKUP_DIR/system_info.txt" ]]; then
  echo ""
  cat "$BACKUP_DIR/system_info.txt"
fi

echo ""
log_message -t warning "This will overwrite some of your current configuration files."
log_message -t warning "It is recommended to run macos_backup.sh first as a safety measure."
echo ""
read -rp "Confirm to proceed with restore? (y/N) " confirm
if [[ "${confirm,,}" != "y" ]]; then
  log_message -t info "Cancelled."
  exit 0
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

backup_existing() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp -a "$f" "${f}.pre_restore.${TIMESTAMP}"
    log_message -t info "  Backed up existing file: ${f}.pre_restore.${TIMESTAMP}"
  fi
}

# ============================================================================
# 1. Homebrew installation & software restore
# ============================================================================
log_message -t running "1/8  Homebrew installation & software restore"

# Ensure Homebrew is installed
if ! need_cmd brew; then
  log_message -t warning "Homebrew not installed, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew in PATH
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

BREW_DIR="$BACKUP_DIR/homebrew"

if [[ -f "$BREW_DIR/Brewfile" ]]; then
  echo ""
  log_message -t info "Brewfile summary:"
  echo "  Taps:     $(grep -c '^tap ' "$BREW_DIR/Brewfile" 2>/dev/null || echo 0)"
  echo "  Formulae: $(grep -c '^brew ' "$BREW_DIR/Brewfile" 2>/dev/null || echo 0)"
  echo "  Casks:    $(grep -c '^cask ' "$BREW_DIR/Brewfile" 2>/dev/null || echo 0)"
  echo "  MAS Apps: $(grep -c '^mas '  "$BREW_DIR/Brewfile" 2>/dev/null || echo 0)"
  echo ""
  read -rp "  Restore all packages via Brewfile? (y/N) " brew_confirm
  if [[ "${brew_confirm,,}" == "y" ]]; then
    brew bundle install --file="$BREW_DIR/Brewfile" --no-lock || true
    log_message -t success "Homebrew packages restored"
  else
    log_message -t warning "Skipped Homebrew package restore"

    # Provide manual install commands
    if [[ -f "$BREW_DIR/taps.txt" ]]; then
      log_message -t info "Manual restore commands:"
      echo "      # Taps"
      while read -r tap; do
        echo "      brew tap $tap"
      done < "$BREW_DIR/taps.txt"
    fi
  fi
else
  log_message -t warning "Brewfile not found, skipping"
fi

# ============================================================================
# 2. Mac App Store apps
# ============================================================================
log_message -t running "2/8  Mac App Store apps"
if [[ -f "$BACKUP_DIR/mas_apps.txt" ]] && need_cmd mas; then
  log_message -t info "App Store app list:"
  cat "$BACKUP_DIR/mas_apps.txt" | head -20
  echo ""
  read -rp "  Restore App Store apps? (y/N) " mas_confirm
  if [[ "${mas_confirm,,}" == "y" ]]; then
    while IFS= read -r line; do
      app_id="$(echo "$line" | awk '{print $1}')"
      app_name="$(echo "$line" | sed 's/^[0-9]* //')"
      log_message -t info "  Installing: $app_name ($app_id)"
      mas install "$app_id" 2>/dev/null || log_message -t warning "  Failed to install: $app_name"
    done < "$BACKUP_DIR/mas_apps.txt"
    log_message -t success "App Store apps restored"
  fi
elif [[ -f "$BACKUP_DIR/mas_apps.txt" ]]; then
  log_message -t warning "mas not installed. Run: brew install mas"
else
  log_message -t info "No App Store backup found, skipping"
fi

# ============================================================================
# 3. Dotfiles
# ============================================================================
log_message -t running "3/8  Dotfiles"
DOTFILES_DIR="$BACKUP_DIR/dotfiles"
if [[ -d "$DOTFILES_DIR" ]]; then
  log_message -t info "Available dotfiles to restore:"
  find "$DOTFILES_DIR" -maxdepth 1 -type f -name ".*" | while read -r f; do
    echo "      $(basename "$f")"
  done
  echo ""
  read -rp "  Restore dotfiles to HOME directory? (y/N) " dot_confirm
  if [[ "${dot_confirm,,}" == "y" ]]; then
    find "$DOTFILES_DIR" -maxdepth 1 -type f -name ".*" | while read -r f; do
      fname="$(basename "$f")"
      target="$HOME/$fname"
      backup_existing "$target"
      cp -a "$f" "$target"
      log_message -t success "  Restored ~/$fname"
    done

    # SSH config
    if [[ -d "$DOTFILES_DIR/.ssh" ]]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      for item in config config.d known_hosts; do
        if [[ -e "$DOTFILES_DIR/.ssh/$item" ]]; then
          if [[ -e "$HOME/.ssh/$item" ]]; then
            cp -a "$HOME/.ssh/$item" "$HOME/.ssh/${item}.pre_restore.${TIMESTAMP}" 2>/dev/null || true
          fi
          cp -a "$DOTFILES_DIR/.ssh/$item" "$HOME/.ssh/$item"
          log_message -t success "  Restored ~/.ssh/$item"
        fi
      done
    fi
  fi
else
  log_message -t info "No dotfiles backup found, skipping"
fi

# ============================================================================
# 4. macOS system preferences
# ============================================================================
log_message -t running "4/8  macOS system preferences"
DEFAULTS_DIR="$BACKUP_DIR/defaults"
if [[ -d "$DEFAULTS_DIR" ]]; then
  log_message -t info "Available preference domains:"
  ls "$DEFAULTS_DIR"/*.plist 2>/dev/null | head -10 | while read -r f; do
    echo "      $(basename "$f" .plist)"
  done
  echo ""
  log_message -t warning "Note: Importing system preferences carries some risk."
  log_message -t warning "Manual import: defaults import <domain> <plist_file>"
  echo ""
  read -rp "  Batch import common system preferences? (y/N) " defaults_confirm
  if [[ "${defaults_confirm,,}" == "y" ]]; then
    SAFE_DOMAINS=(
      com.apple.dock
      com.apple.finder
      com.apple.screencapture
      com.apple.menuextra.clock
      com.apple.AppleMultitouchTrackpad
      com.apple.WindowManager
    )
    for domain in "${SAFE_DOMAINS[@]}"; do
      plist_file="$DEFAULTS_DIR/${domain}.plist"
      if [[ -f "$plist_file" ]]; then
        defaults import "$domain" "$plist_file" 2>/dev/null && \
          log_message -t success "  Imported: $domain" || \
          log_message -t warning "  Failed to import: $domain"
      fi
    done
    # Restart Dock and Finder to apply settings
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
    log_message -t success "Dock and Finder restarted"
  fi
else
  log_message -t info "No defaults backup found, skipping"
fi

# ============================================================================
# 5. VS Code / Cursor extensions & settings
# ============================================================================
log_message -t running "5/8  VS Code / Cursor"
VSCODE_DIR="$BACKUP_DIR/vscode"
if [[ -d "$VSCODE_DIR" ]]; then
  # VS Code extensions
  if [[ -f "$VSCODE_DIR/vscode_extensions.txt" ]] && need_cmd code; then
    ext_count="$(wc -l < "$VSCODE_DIR/vscode_extensions.txt" | tr -d ' ')"
    read -rp "  Install $ext_count VS Code extensions? (y/N) " vsc_ext_confirm
    if [[ "${vsc_ext_confirm,,}" == "y" ]]; then
      while IFS= read -r ext; do
        code --install-extension "$ext" --force 2>/dev/null || log_message -t warning "  Failed to install: $ext"
      done < "$VSCODE_DIR/vscode_extensions.txt"
      log_message -t success "VS Code extensions restored"
    fi
  fi

  # VS Code settings
  VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
  if [[ -d "$VSCODE_USER_DIR" ]]; then
    for cfg in settings.json keybindings.json; do
      if [[ -f "$VSCODE_DIR/$cfg" ]]; then
        backup_existing "$VSCODE_USER_DIR/$cfg"
        cp -a "$VSCODE_DIR/$cfg" "$VSCODE_USER_DIR/$cfg"
        log_message -t success "  Restored VS Code $cfg"
      fi
    done
    if [[ -d "$VSCODE_DIR/snippets" ]]; then
      cp -a "$VSCODE_DIR/snippets" "$VSCODE_USER_DIR/" 2>/dev/null || true
      log_message -t success "  Restored VS Code snippets"
    fi
  fi

  # Cursor extensions
  if [[ -f "$VSCODE_DIR/cursor_extensions.txt" ]] && need_cmd cursor; then
    read -rp "  Install Cursor extensions? (y/N) " cursor_ext_confirm
    if [[ "${cursor_ext_confirm,,}" == "y" ]]; then
      while IFS= read -r ext; do
        cursor --install-extension "$ext" --force 2>/dev/null || true
      done < "$VSCODE_DIR/cursor_extensions.txt"
      log_message -t success "Cursor extensions restored"
    fi
  fi

  # Cursor settings
  CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
  if [[ -d "$CURSOR_USER_DIR" ]]; then
    for cfg in settings.json keybindings.json; do
      if [[ -f "$VSCODE_DIR/cursor_${cfg}" ]]; then
        backup_existing "$CURSOR_USER_DIR/$cfg"
        cp -a "$VSCODE_DIR/cursor_${cfg}" "$CURSOR_USER_DIR/$cfg"
        log_message -t success "  Restored Cursor $cfg"
      fi
    done
  fi
else
  log_message -t info "No VS Code backup found, skipping"
fi

# ============================================================================
# 6. Shell configuration (oh-my-zsh, iTerm2)
# ============================================================================
log_message -t running "6/8  Shell configuration (oh-my-zsh, iTerm2)"
SHELL_DIR="$BACKUP_DIR/shell"

# Restore oh-my-zsh custom plugins/themes
if [[ -f "$SHELL_DIR/omz_custom_repos.txt" ]]; then
  ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
  log_message -t info "oh-my-zsh custom repos:"
  cat "$SHELL_DIR/omz_custom_repos.txt"
  echo ""
  read -rp "  Clone these repos? (y/N) " omz_confirm
  if [[ "${omz_confirm,,}" == "y" ]]; then
    while IFS=' -> ' read -r local_path remote_url; do
      # Compute relative path
      relative="${local_path##*/custom/}"
      target_dir="$ZSH_CUSTOM/$relative"
      if [[ ! -d "$target_dir" ]] && [[ "$remote_url" != "unknown" ]]; then
        log_message -t info "  Cloning: $remote_url -> $target_dir"
        git clone --depth=1 "$remote_url" "$target_dir" 2>/dev/null || log_message -t warning "  Clone failed: $remote_url"
      else
        log_message -t success "  Already exists: $target_dir"
      fi
    done < "$SHELL_DIR/omz_custom_repos.txt"
  fi
fi

# iTerm2
if [[ -f "$SHELL_DIR/com.googlecode.iterm2.plist" ]]; then
  read -rp "  Restore iTerm2 preferences? (y/N) " iterm_confirm
  if [[ "${iterm_confirm,,}" == "y" ]]; then
    backup_existing "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    cp -a "$SHELL_DIR/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/"
    log_message -t success "iTerm2 preferences restored (restart iTerm2 to apply)"
  fi
fi

# ============================================================================
# 7. Conda / Python environments
# ============================================================================
log_message -t running "7/8  Conda / Python environments"
PY_DIR="$BACKUP_DIR/python"
if [[ -d "$PY_DIR" ]] && need_cmd conda; then
  log_message -t info "Available Conda environments:"
  ls "$PY_DIR"/conda_*.yml 2>/dev/null | while read -r f; do
    env_name="$(basename "$f" .yml | sed 's/^conda_//')"
    echo "      $env_name"
  done
  echo ""
  read -rp "  Restore Conda environments? (y/N) " conda_confirm
  if [[ "${conda_confirm,,}" == "y" ]]; then
    for yml in "$PY_DIR"/conda_*.yml; do
      [[ -f "$yml" ]] || continue
      env_name="$(basename "$yml" .yml | sed 's/^conda_//')"
      if [[ "$env_name" == "base" ]]; then
        log_message -t info "  Skipping base env (use 'conda update --all' to update manually)"
        continue
      fi
      log_message -t info "  Restoring environment: $env_name"
      conda env create -f "$yml" -n "$env_name" 2>/dev/null || \
        conda env update -f "$yml" -n "$env_name" 2>/dev/null || \
        log_message -t warning "  Failed to restore: $env_name"
    done
    log_message -t success "Conda environments restored"
  fi
elif [[ -d "$PY_DIR" ]]; then
  log_message -t warning "conda not installed, skipping Python environment restore"
fi

# ============================================================================
# 8. Fonts
# ============================================================================
log_message -t running "8/8  User fonts"
FONT_DIR="$BACKUP_DIR/fonts"
if [[ -d "$FONT_DIR" ]] && [[ -n "$(ls -A "$FONT_DIR" 2>/dev/null)" ]]; then
  font_count="$(ls -1 "$FONT_DIR" | wc -l | tr -d ' ')"
  read -rp "  Restore $font_count fonts to ~/Library/Fonts? (y/N) " font_confirm
  if [[ "${font_confirm,,}" == "y" ]]; then
    mkdir -p "$HOME/Library/Fonts"
    cp -a "$FONT_DIR/"* "$HOME/Library/Fonts/" 2>/dev/null || true
    log_message -t success "Fonts restored"
  fi
else
  log_message -t info "No font backup found, skipping"
fi

# ============================================================================
# 9. LaunchAgents
# ============================================================================
LA_DIR="$BACKUP_DIR/launch_agents"
if [[ -d "$LA_DIR" ]] && [[ -n "$(ls -A "$LA_DIR" 2>/dev/null)" ]]; then
  log_message -t running "Extra  LaunchAgents"
  read -rp "  Restore user LaunchAgents? (y/N) " la_confirm
  if [[ "${la_confirm,,}" == "y" ]]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    cp -a "$LA_DIR/"*.plist "$HOME/Library/LaunchAgents/" 2>/dev/null || true
    log_message -t success "LaunchAgents restored (re-login to apply)"
  fi
fi

# Crontab
if [[ -f "$BACKUP_DIR/crontab.txt" ]] && [[ -s "$BACKUP_DIR/crontab.txt" ]]; then
  log_message -t running "Extra  Crontab"
  log_message -t info "Backed up crontab:"
  cat "$BACKUP_DIR/crontab.txt"
  echo ""
  read -rp "  Restore crontab? (y/N) " cron_confirm
  if [[ "${cron_confirm,,}" == "y" ]]; then
    crontab "$BACKUP_DIR/crontab.txt"
    log_message -t success "Crontab restored"
  fi
fi

# ============================================================================
# Done
# ============================================================================
echo ""
log_message -t success "============================================"
log_message -t success "  Restore complete!"
log_message -t success "============================================"
echo ""
log_message -t info "Next steps:"
echo "  1. Open a new terminal window to apply shell configuration"
echo "  2. Run 'p10k configure' to set up Powerlevel10k theme (if applicable)"
echo "  3. Manually import other defaults domains if needed:"
echo "     defaults import <domain> $BACKUP_DIR/defaults/<domain>.plist"
echo "  4. Re-login or restart to apply all settings"
echo ""

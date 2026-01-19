#!/usr/bin/env bash
set -euo pipefail

echo "==> macOS Zsh Terminal Setup: oh-my-zsh + powerlevel10k + plugins + fzf"

ZSHRC="$HOME/.zshrc"
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
PLUGIN_DIR="$ZSH_CUSTOM/plugins"
AUTOSUG_DIR="$PLUGIN_DIR/zsh-autosuggestions"
SYNTAX_DIR="$PLUGIN_DIR/zsh-syntax-highlighting"

need_cmd() { command -v "$1" >/dev/null 2>&1; }

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    local ts
    ts="$(date +%Y%m%d_%H%M%S)"
    cp -a "$f" "${f}.bak.${ts}"
    echo "    backed up: $f -> ${f}.bak.${ts}"
  fi
}

ensure_line() {
  local file="$1" line="$2"
  touch "$file"
  grep -Fqx "$line" "$file" || echo "$line" >>"$file"
}

set_or_append_kv() {
  # usage: set_or_append_kv file KEY VALUE(without quotes)
  local file="$1" key="$2" value="$3"
  touch "$file"
  if grep -Eq "^[# ]*${key}=" "$file"; then
    # replace first occurrence
    perl -0777 -i -pe "s/^[# ]*${key}=.*\$/${key}=${value}/m" "$file"
  else
    echo "${key}=${value}" >>"$file"
  fi
}

ensure_plugins() {
  local file="$1"
  touch "$file"
  local want="git zsh-autosuggestions zsh-syntax-highlighting"
  if grep -Eq "^[# ]*plugins=\(" "$file"; then
    # If plugins line exists, make sure these plugins are included.
    # We keep existing ones and append missing.
    local current
    current="$(perl -ne 'if (/^[# ]*plugins=\(([^)]*)\)/){print $1; exit}' "$file" || true)"
    # Normalize spaces
    current="$(echo "${current:-}" | tr -s ' ')"
    local merged="$current"
    for p in $want; do
      if [[ " $merged " != *" $p "* ]]; then
        merged="${merged} ${p}"
      fi
    done
    merged="$(echo "$merged" | xargs)"
    perl -0777 -i -pe "s/^[# ]*plugins=\([^)]*\)/plugins=(${merged})/m" "$file"
  else
    echo "plugins=(${want})" >>"$file"
  fi
}

echo "==> Step 1: Homebrew & git"
if ! need_cmd brew; then
  echo "    Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "    Homebrew already installed."
fi

# Ensure brew is in PATH for current shell (Apple Silicon path)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew update >/dev/null || true
brew install git >/dev/null

echo "==> Step 2: Install oh-my-zsh (if needed)"
if [[ ! -d "$ZSH_DIR" ]]; then
  echo "    Installing oh-my-zsh..."
  # This installer may modify ~/.zshrc and switch shell; keep non-interactive best effort.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "    oh-my-zsh already installed at: $ZSH_DIR"
fi

echo "==> Step 3: Install Powerlevel10k theme"
if [[ ! -d "$P10K_DIR" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "    powerlevel10k already exists at: $P10K_DIR"
fi

echo "==> Step 4: Install zsh plugins"
mkdir -p "$PLUGIN_DIR"
if [[ ! -d "$AUTOSUG_DIR" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUG_DIR"
else
  echo "    zsh-autosuggestions already exists."
fi
if [[ ! -d "$SYNTAX_DIR" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_DIR"
else
  echo "    zsh-syntax-highlighting already exists."
fi

echo "==> Step 5: Update ~/.zshrc (backup + set theme + plugins + options)"
backup_file "$ZSHRC"

# Set theme
# Replace ZSH_THEME="robbyrussell" or any existing theme with powerlevel10k
touch "$ZSHRC"
if grep -Eq '^[# ]*ZSH_THEME=' "$ZSHRC"; then
  perl -0777 -i -pe 's/^[# ]*ZSH_THEME=.*$/ZSH_THEME="powerlevel10k\/powerlevel10k"/m' "$ZSHRC"
else
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >>"$ZSHRC"
fi

# Ensure plugins include required ones
ensure_plugins "$ZSHRC"

# Extra: disable auto title + simple prompt (from your note at the bottom)
# If you only want to use p10k's prompt, you can comment out the PROMPT line.
set_or_append_kv "$ZSHRC" "DISABLE_AUTO_TITLE" "\"true\""
# ensure_line "$ZSHRC" "PROMPT='%~ % '"

echo "==> Step 6: Install fzf (optional but recommended)"
if ! brew list fzf >/dev/null 2>&1; then
  brew install fzf >/dev/null
else
  echo "    fzf already installed."
fi

# Initialize fzf key-bindings (interactive script; safe to run multiple times)
FZF_INSTALL="$(brew --prefix)/opt/fzf/install"
if [[ -x "$FZF_INSTALL" ]]; then
  echo "    Running fzf install (may ask questions)..."
  "$FZF_INSTALL" --key-bindings --completion --no-update-rc || true
else
  echo "    fzf install script not found at: $FZF_INSTALL"
fi

echo "==> Step 7: Configuration complete"
# Skip reloading zshrc here because:
# 1. This script runs in bash, but oh-my-zsh can only be loaded in zsh
# 2. Configuration files have been updated and will take effect in new terminals
echo "    All configuration files have been updated."
echo "    Please open a NEW zsh terminal window/tab to see the changes."

echo
echo "✅ Done."
echo "Next manual steps:"
echo "  1) Open a NEW terminal tab/window."
echo "  2) Run: p10k configure   (Powerlevel10k will start the configuration wizard)"

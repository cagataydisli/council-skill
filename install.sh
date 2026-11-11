#!/usr/bin/env bash
# council skill kurulumu: Claude Code, Codex CLI ve Antigravity CLI (agy).
#
# Kullanım:
#   bash install.sh              # bulunan tüm araçlara kur
#   bash install.sh claude codex # sadece seçilenlere kur (claude|codex|agy)
#   bash install.sh --uninstall  # hepsini kaldır
#
# Not: Ortak script her durumda ~/.claude/skills/council/council.sh konumuna
# kopyalanır; Codex ve agy skill'leri de onu çağırır.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
CLAUDE_DIR="$HOME/.claude/skills/council"
CODEX_DIR="$HOME/.codex/skills/council"
AGY_DIR="$HOME/.gemini/config/skills/council"

backup() {  # mevcut kurulumu silmeden yedekle
  if [ -e "$1" ]; then
    local b="$1.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$1" "$b"
    echo "  eski kurulum yedeklendi: $b"
  fi
}

if [ "${1:-}" = "--uninstall" ]; then
  for d in "$CLAUDE_DIR" "$CODEX_DIR" "$AGY_DIR"; do
    [ -e "$d" ] && rm -rf "$d" && echo "kaldırıldı: $d"
  done
  exit 0
fi

TARGETS=("$@")
if [ ${#TARGETS[@]} -eq 0 ]; then
  command -v claude >/dev/null 2>&1 && TARGETS+=(claude)
  command -v codex  >/dev/null 2>&1 && TARGETS+=(codex)
  command -v agy    >/dev/null 2>&1 && TARGETS+=(agy)
  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "claude, codex ya da agy bulunamadı. Hedefi elle verin: bash install.sh claude codex agy" >&2
    exit 1
  fi
fi

install_script() {  # ortak council.sh
  mkdir -p "$CLAUDE_DIR"
  cp "$SRC/council.sh" "$CLAUDE_DIR/council.sh"
  chmod +x "$CLAUDE_DIR/council.sh"
}

for t in "${TARGETS[@]}"; do
  case "$t" in
    claude)
      echo "Claude Code -> $CLAUDE_DIR"
      backup "$CLAUDE_DIR"
      mkdir -p "$CLAUDE_DIR"
      cp "$SRC/claude/SKILL.md" "$CLAUDE_DIR/SKILL.md"
      install_script ;;
    codex)
      echo "Codex CLI   -> $CODEX_DIR"
      backup "$CODEX_DIR"
      mkdir -p "$CODEX_DIR/agents"
      cp "$SRC/codex/SKILL.md" "$CODEX_DIR/SKILL.md"
      cp "$SRC/codex/agents/openai.yaml" "$CODEX_DIR/agents/openai.yaml" ;;
    agy|antigravity)
      echo "Antigravity -> $AGY_DIR"
      backup "$AGY_DIR"
      mkdir -p "$AGY_DIR"
      cp "$SRC/antigravity/SKILL.md" "$AGY_DIR/SKILL.md" ;;
    *) echo "Bilinmeyen hedef: $t (claude|codex|agy)" >&2; exit 2 ;;
  esac
done

# Codex ya da agy tek başına kurulduysa da ortak script yerinde olmalı.
install_script

echo
echo "Kurulum tamam. Çağırma:"
echo "  Claude Code: /council <soru>"
echo "  Codex CLI:   \$council <soru>"
echo "  Antigravity: /council <soru>"
echo "Kontrol: bash $CLAUDE_DIR/council.sh  (kullanım mesajı görmelisin)"

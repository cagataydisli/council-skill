#!/usr/bin/env bash
# Ortak akıl kurulu (Fable + gpt-6-astra + gemini-4-argon).
# Ev sahibi (başkan) kim ise o hariç diğer iki üyeye aynı brief'i paralel,
# bağımsız ve salt okunur olarak gönderir. Cevaplar <out>/<üye>.md.
#
# Kullanım:
#   bash council.sh --host claude|codex|agy <brief.md> [cikti_klasoru]
#   bash council.sh --members astra,argon   <brief.md> [cikti_klasoru]
# Ortam:
#   FABLE_MODEL  (vars: fable)               FABLE_EFFORT (vars: high)
#   ASTRA_MODEL  (vars: gpt-6-astra)         ASTRA_EFFORT (vars: high)
#   ARGON_MODEL  (vars: gemini-4-argon-high)
#   COUNCIL_TIMEOUT saniye (vars: 540)
#
# Tek kaynak: ~/.claude/skills/council/council.sh (Codex ve agy skill'leri de bunu çağırır).
set -u

MEMBERS=""
case "${1:-}" in
  --host)
    case "${2:-}" in
      claude) MEMBERS="astra,argon" ;;
      codex)  MEMBERS="fable,argon" ;;
      agy)    MEMBERS="fable,astra" ;;
      *) echo "--host claude|codex|agy olmalı" >&2; exit 2 ;;
    esac; shift 2 ;;
  --members) MEMBERS="${2:?--members a,b}"; shift 2 ;;
  *) echo "Kullanım: council.sh --host claude|codex|agy <brief.md> [cikti_klasoru]" >&2; exit 2 ;;
esac

BRIEF="${1:?brief.md gerekli}"
[ -f "$BRIEF" ] || { echo "Brief bulunamadı: $BRIEF" >&2; exit 2; }
BRIEF_DIR="$(cd "$(dirname "$BRIEF")" && pwd)"
BRIEF_ABS="$BRIEF_DIR/$(basename "$BRIEF")"
OUT="${2:-$BRIEF_DIR/council_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT" && OUT="$(cd "$OUT" && pwd)"

T="${COUNCIL_TIMEOUT:-540}"

# macOS'ta GNU timeout yoksa gtimeout'a, o da yoksa süresiz çalıştırmaya düş.
if command -v timeout >/dev/null 2>&1; then TO=(timeout "$T")
elif command -v gtimeout >/dev/null 2>&1; then TO=(gtimeout "$T")
else TO=(); fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "'$1' komutu bulunamadı (PATH'te değil)" > "$OUT/$2.log"; return 127; }; }

PROMPT="You are an independent advisor on a three-member council. Read the brief at: $BRIEF_ABS
Answer from your own reasoning; do not just agree with any option. Do not modify any files.
Reply in this structure:
1. Recommendation
2. Reasoning
3. Risks or options the asker may be missing
4. Confidence (low/medium/high) and what evidence would change your mind"

run_member() {
  local m="$1"
  case "$m" in
    fable)
      need claude fable || return 127
      ( cd "$BRIEF_DIR" && ${TO[@]+"${TO[@]}"} claude -p --model "${FABLE_MODEL:-fable}" \
          --effort "${FABLE_EFFORT:-high}" --permission-mode plan --no-session-persistence \
          "$PROMPT" > "$OUT/fable.md" 2> "$OUT/fable.log" ) ;;
    astra)
      need codex astra || return 127
      ${TO[@]+"${TO[@]}"} codex exec -m "${ASTRA_MODEL:-gpt-6-astra}" -c model_reasoning_effort="${ASTRA_EFFORT:-high}" \
        --skip-git-repo-check -s read-only -C "$BRIEF_DIR" \
        -o "$OUT/astra.md" "$PROMPT" > "$OUT/astra.log" 2>&1 ;;
    argon)
      need agy argon || return 127
      ( cd "$BRIEF_DIR" && ${TO[@]+"${TO[@]}"} agy -p "$PROMPT" --model "${ARGON_MODEL:-gemini-4-argon-high}" \
          --mode plan --add-dir "$BRIEF_DIR" --print-timeout "$((T-10))s" \
          > "$OUT/argon.md" 2> "$OUT/argon.log" ) ;;
    *) echo "Bilinmeyen üye: $m" > "$OUT/$m.log"; return 2 ;;
  esac
}

PIDS=()
IFS=',' read -r -a LIST <<< "$MEMBERS"
for m in "${LIST[@]}"; do
  ( run_member "$m"; echo $? > "$OUT/$m.exit" ) &
  PIDS+=($!)
done
wait "${PIDS[@]}"

for m in "${LIST[@]}"; do
  code="$(cat "$OUT/$m.exit" 2>/dev/null || echo '?')"
  if [ "$code" = "0" ] && [ -s "$OUT/$m.md" ]; then
    echo "[$m] OK -> $OUT/$m.md"
  else
    echo "[$m] BAŞARISIZ (exit $code) -> log: $OUT/$m.log"
  fi
done
echo "Çıktı klasörü: $OUT"

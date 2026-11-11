# council: üç modelli ortak akıl kurulu

Claude Code, Codex CLI ve Antigravity CLI (`agy`) için tek bir skill.
Zor bir kararda çalıştığın araçtaki model **başkan** olur, diğer iki model
ailesine aynı soruyu **paralel ve birbirinden bağımsız** sorar, cevapları
tartıp son kararı verir. Ayrıca işleri zorluğuna göre ucuz alt modellere
(Opus / Sonnet / Haiku, gpt-6.1-sol / gpt-6-luna) dağıtma kurallarını içerir.

| Kurul üyesi | Hangi CLI ile çağrılır | Varsayılan model |
|---|---|---|
| Claude | `claude` | `fable` |
| GPT | `codex` | `gpt-6-astra` |
| Gemini | `agy` | `gemini-4-argon-high` |

Hangi araçtaysan o araç başkandır, diğer ikisi danışmandır:

| Çağırdığın yer | Komut | Danışılanlar |
|---|---|---|
| Claude Code | `/council <soru>` | GPT + Gemini |
| Codex CLI | `$council <soru>` | Claude + Gemini |
| Antigravity | `/council <soru>` | Claude + GPT |

Skill **sadece elle çağrılınca** çalışır; normal konuşmalarda kendiliğinden
devreye girmez ve dış modelleri çağırmaz.

## Gereksinimler

- **bash**: macOS ve Linux'ta hazır. Windows'ta [Git for Windows](https://git-scm.com/download/win) ile gelen Git Bash.
- Kullanmak istediğin CLI'lar kurulu ve giriş yapılmış olmalı:
  - [Claude Code](https://docs.claude.com/en/docs/claude-code) (`claude`)
  - [Codex CLI](https://github.com/openai/codex) (`codex`)
  - Antigravity CLI (`agy`)
- Kurulun tam çalışması için üçü de gerekir. Biri eksikse skill kalan üyelerle
  devam eder ve bunu söyler.
- macOS'ta zaman aşımı için isteğe bağlı: `brew install coreutils` (yoksa
  script süre sınırı olmadan çalışır).

## Kurulum

```bash
git clone https://github.com/cagataydisli/council-skill.git
cd council-skill
bash install.sh
```

`install.sh` makinede hangi CLI'lar varsa onlara kurar. Sadece bazılarına
kurmak için:

```bash
bash install.sh claude codex   # hedefler: claude | codex | agy
```

Dosyalar şuraya gider (önceden bir kurulum varsa silinmez, `.bak.<tarih>`
olarak yedeklenir):

| Araç | Konum |
|---|---|
| Claude Code | `~/.claude/skills/council/` (SKILL.md + ortak `council.sh`) |
| Codex CLI | `~/.codex/skills/council/` |
| Antigravity | `~/.gemini/config/skills/council/` |

Ortak script her zaman `~/.claude/skills/council/council.sh` konumundadır;
Codex ve Antigravity skill'leri de onu çağırır. Sadece Codex'e kursan bile
script oraya kopyalanır.

Kurulumdan sonra CLI'ı yeniden başlat, sonra dene:

```text
/council Bu projede veritabanı olarak SQLite mı Postgres mi seçmeliyim?
```

Kaldırmak için: `bash install.sh --uninstall`. Güncellemek için: `git pull && bash install.sh`.

### Elle kurulum

Script çalıştırmak istemezsen klasörleri kendin kopyala:

```bash
mkdir -p ~/.claude/skills/council ~/.codex/skills/council/agents ~/.gemini/config/skills/council
cp skills/council.sh skills/claude/SKILL.md      ~/.claude/skills/council/
cp skills/codex/SKILL.md                         ~/.codex/skills/council/
cp skills/codex/agents/openai.yaml               ~/.codex/skills/council/agents/
cp skills/antigravity/SKILL.md                   ~/.gemini/config/skills/council/
```

## Nasıl çalışır

1. Başkan model önce kendi görüşünü oluşturur ama paylaşmaz.
2. Sorunu, kanıtı ve seçenekleri tek bir `brief.md` dosyasına yazar.
3. `council.sh` diğer iki üyeyi **salt okunur** modda paralel çalıştırır; her
   biri cevabını ayrı bir dosyaya yazar (`fable.md`, `astra.md`, `argon.md`).
4. Başkan üç görüşü karşılaştırır. Ayrışma varsa en fazla bir tur çapraz
   eleştiri yapılır. Karar çoğunluk oyuyla değil, en güçlü gerekçeyle verilir.

Script'i elle de çalıştırabilirsin:

```bash
bash ~/.claude/skills/council/council.sh --host claude brief.md
bash ~/.claude/skills/council/council.sh --members astra,argon brief.md cikti/
```

## Modelleri değiştirme

Hesabında bu modeller yoksa ya da daha ucuz bir kurul istersen ortam
değişkenleriyle değiştir:

| Değişken | Varsayılan | Örnek |
|---|---|---|
| `FABLE_MODEL` | `fable` | `opus` |
| `FABLE_EFFORT` | `high` | `medium` |
| `ASTRA_MODEL` | `gpt-6-astra` | `gpt-6.1-sol` |
| `ASTRA_EFFORT` | `high` | `xhigh` |
| `ARGON_MODEL` | `gemini-4-argon-high` | `gemini-4-argon-medium` |
| `COUNCIL_TIMEOUT` | `540` (saniye) | `900` |

Kalıcı yapmak için `~/.bashrc` ya da `~/.zshrc` dosyana ekle, örneğin
`export FABLE_MODEL=opus`.

## Sorun giderme

- **`[astra] BAŞARISIZ`** gibi bir satır: çıktı klasöründeki `<üye>.log`
  dosyasına bak. Genelde CLI'a giriş yapılmamıştır ya da model adı hesabında yoktur.
- **`'agy' komutu bulunamadı`**: CLI PATH'te değil. Terminali yeniden aç ya da PATH'e ekle.
- **Codex script'i çalıştıramıyor**: Codex sandbox'ı dış CLI çağrılarına ağ
  izni vermeyebilir; Codex onay istediğinde izin ver.
- **Windows'ta `bash` bulunamıyor**: Git for Windows'u kur ve komutu Git Bash'ten çalıştır.

## Güvenlik notu

Brief dosyası diğer iki sağlayıcıya (OpenAI, Google ya da Anthropic) gönderilir.
Skill, brief'e secret, token, şifre ya da kişisel veri konmamasını söyler; yine
de hassas projelerde neyin dışarı gittiğine dikkat et.

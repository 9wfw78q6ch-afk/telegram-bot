# AIDailyBrief Watch

Malá automatizace, která pravidelně kontroluje více zdrojů, pozná nové video nebo nový obsah, stáhne text a vytvoří shrnutí nejdůležitějších bodů.

## Co to dělá

- kontroluje více zdrojů v zadaném intervalu, výchozí je 8 hodin
- podporuje YouTube kanály, RSS/Atom feedy a běžné webové stránky
- pro YouTube zkusí přepis, potom titulky, potom fallback z popisku videa
- pro weby stáhne viditelný text stránky a počítá změny přes fingerprint obsahu
- když je k dispozici `OPENAI_API_KEY`, vytvoří kvalitnější shrnutí přes OpenAI
- když OpenAI není dostupné, zkusí lokální Ollama model a teprve potom jednoduché lokální shrnutí
- uloží výstup do Markdown reportu v adresáři `reports/`
- uloží stav do `.state/last_video.json`, aby stejný zdroj nezpracoval dvakrát

## Instalace

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

## Spuštění

Jednorázová kontrola všech zdrojů:

```bash
python aidailybrief_watch.py
```

Nepřetržitý běh s kontrolou každých 8 hodin:

```bash
python aidailybrief_watch.py --daemon
```

Testovací režim pro Telegram a sumarizaci bez kontroly zdrojů:

```bash
python aidailybrief_watch.py --test
```

Vlastní testovací text:

```bash
python aidailybrief_watch.py --test --test-subject "Tady je můj testovací text, ze kterého chci udělat shrnutí."
```

Týdenní AI report:

```bash
python aidailybrief_watch.py --weekly-report
```

Tento report bere položky z historie posledních 7 dní, shrne je do týdně laděného digestu a pošle ho do Telegramu.

Jiný interval pro aktuální spuštění:

```bash
python aidailybrief_watch.py --daemon --interval-hours 8
```

## Nastavení

Pokud chceš použít OpenAI pro lepší shrnutí a záložní přepis, nastav v `.env`:

```bash
OPENAI_API_KEY=...
```

Volitelně můžeš změnit i modely:

```bash
OPENAI_SUMMARY_MODEL=gpt-4.1-mini
OPENAI_TRANSCRIPTION_MODEL=whisper-1
```

### Ollama fallback

Když není OpenAI k dispozici, automatika zkusí lokální Ollama server na `http://localhost:11434`.

Pokud chceš použít jiný model nebo jinou adresu, nastav v `.env`:

```bash
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1
OLLAMA_TIMEOUT_SECONDS=120
```

Předpoklad je, že Ollama běží lokálně a model je stažený přes `ollama pull <model>`.

### Jak to zprovoznit

1. Zvol model, který chceš používat, například `llama3.1:8b` nebo menší `qwen2.5:7b`.
2. Stáhni model:

```bash
ollama pull llama3.1:8b
```

3. Spusť Ollama server, pokud už neběží:

```bash
ollama serve
```

4. Nastav v `.env` konkrétní model:

```bash
OLLAMA_MODEL=llama3.1:8b
OLLAMA_BASE_URL=http://localhost:11434
```

5. Otestuj přímo v terminálu:

```bash
ollama run llama3.1:8b "Napiš 5 stručných bodů o tom, co je AI automatizace."
```

Když ten příkaz funguje, bude fungovat i automatizace.

### Zdroje

Seznam monitorovaných zdrojů se ukládá do [sources.example.json](sources.example.json) a při běhu se načítá ze souboru zadaného v `SOURCES_FILE`.

Volitelně může každý zdroj mít i `priority`. Vyšší číslo znamená vyšší prioritu a zdroje se pak zpracují i v Telegram digestu dřív.

Příklad `sources.json`:

```json
[
	{
		"type": "youtube",
		"name": "AIDailyBrief",
		"url": "https://www.youtube.com/@AIDailyBrief/videos"
	},
	{
		"type": "youtube",
		"name": "OpenAI",
		"url": "https://www.youtube.com/@OpenAI/videos"
	},
	{
		"type": "rss",
		"name": "OpenAI Blog",
		"url": "https://openai.com/blog/rss.xml"
	},
	{
		"type": "web",
		"name": "Tech News",
		"url": "https://example.com/news"
	}
]
```

Pro Twitter/X účty doporučuji používat RSS feed přes RSS bridge nebo jiný veřejný feed. Tím je lze sledovat stejně jako RSS zdroj.

### Telegram notifikace

Chceš-li dostávat notifikace o nových videích na Telegram:

1. **Vytvoř si Telegram bota** – napíšeš `/newbot` do [@BotFather](https://t.me/BotFather) a dostaneš `TELEGRAM_BOT_TOKEN`
2. **Získej ID své Telegram skupiny či osobního chatu** – přidej si bota do chatu a pošli mu zprávu, pak na `https://api.telegram.org/bot<TOKEN>/getUpdates` si vyhledej `"chat":{"id": <CHAT_ID>}`
3. **Nastav v `.env`:**

```bash
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=-1001234567890
```

Jakmile je vše nastaveno, bot automaticky pošle zprávu s názvem, linkem a shrnutím do tvého Telegramu.

## Výstupy

- `reports/<source_key>.md` obsahuje shrnutí a text poslední změny pro daný zdroj
- `.state/last_video.json` drží poslední fingerprinty všech zdrojů

## Cron alternativa

Místo dlouho běžícího procesu můžeš spouštět jednorázovou kontrolu přes cron každých 8 hodin:

```cron
0 */8 * * * cd /Users/mikolassvatos/Projects/aidailybrief-watch && . .venv/bin/activate && python aidailybrief_watch.py >> automation.log 2>&1
```

## Weekly report automaticky

Pro automatické týdenní shrnutí je připraven samostatný LaunchAgent, který spouští:

```bash
python aidailybrief_watch.py --weekly-report
```

Konfigurační soubor je v [launchd/com.mikolassvatos.aidailybrief.weekly.plist](launchd/com.mikolassvatos.aidailybrief.weekly.plist) a je nastavený na jednou týdně v neděli v 9:00.

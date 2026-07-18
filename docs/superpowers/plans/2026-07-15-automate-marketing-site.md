# AutoMate Marketing Site Rebuild — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic 2-file "Arctos Labs" portfolio-card GitHub Pages site with a 5-page, fully custom-designed AutoMate marketing site (homepage, `/vs-drivvo`, `/vs-fuelio`, `/privacy-policy`, `/press-kit`).

**Architecture:** Plain static HTML + 2 shared CSS files (`tokens.css`, `styles.css`) — no build step, no framework, no JS bundler. Each page is a real file under a directory (e.g. `vs-drivvo/index.html`) so GitHub Pages serves clean extensionless URLs. Pages share nav/footer/component markup by copy (5 pages is below the threshold where a templating layer earns its complexity — see CLAUDE.md-equivalent decomposition rule: "extract a shared component only at 4+ near-identical blocks; keep one-off variants inline" applied here at the *page* level, not component level, because Jekyll includes would be the first templating dependency this repo has ever had).

**Tech Stack:** HTML5, CSS3 (custom properties, no preprocessor), Google Fonts (JetBrains Mono, IBM Plex Sans), zero JS dependencies (any interactivity is `<details>`-based or CSS-only).

**Repo:** `banderberg/arctoslabs`, cloned to `/mnt/data/projects/arctoslabs-site`, branch `redesign-automate-site`, Pages source = `master` branch root.

## Global Constraints

- No fabricated metrics, testimonials, or pricing. Every claim in copy must be either a fact already confirmed in this conversation, or sourced via the Task 4 WebSearch with a citation.
- No `utm_*` query params on any Play Store link — plain `https://play.google.com/store/apps/details?id=com.arctosbuilt.automate` everywhere (confirmed: user has separate tinyurls for social bios, site CTAs stay plain).
- Every color reference in CSS uses a `var(--color-*)` token from `tokens.css` — no inline hex/oklch in page-level `<style>` blocks.
- Every interactive element (`<a>`, `<button>`, `<details>`) has visible `:focus-visible` styling and, where it's not obvious from visible text, an `aria-label`.
- No horizontal scroll at 320px. No two-line clickable text (nav links, buttons, footer links). Root `overflow-x: clip` on `html` and `body`.
- Tone: factual, non-disparaging on the two comparison pages — comparison, not attack.
- Never `git push` or open a PR without the user's explicit go-ahead (Task 9 stops and asks).

---

## File Structure

```
arctoslabs-site/
├── tokens.css                  # Hallmark design tokens (color/type/space/motion) — Task 1
├── styles.css                  # shared nav/footer/button/stat-block/table/section styles — Task 1
├── assets/
│   ├── logo/
│   │   ├── automate-mark-dark.png   # copied from automate-v2 assets/images/icon.png — Task 1
│   │   └── automate-mark-light.png  # copied from automate-v2 assets/images/adaptive-icon.png — Task 1
│   └── screenshots/
│       ├── dashboard.png            # copied from automate-v2 assets/screens/Screenshot_20260602-195819.png — Task 1
│       ├── efficiency-spending.png  # copied from Screenshot_20260602-200042.png — Task 1
│       ├── history.png              # copied from Screenshot_20260602-200107.png — Task 1
│       └── reminders.png            # copied from Screenshot_20260602-200144.png — Task 1
├── index.html                  # homepage — Task 2
├── vs-drivvo/index.html        # comparison page — Task 3
├── vs-fuelio/index.html        # comparison page — Task 5
├── privacy-policy/index.html   # privacy policy — Task 6
├── privacy.html                 # redirect stub -> /privacy-policy/ (preserves old URL) — Task 6
├── press-kit/index.html        # press kit — Task 7
└── tests/
    └── check-page.sh           # curl+grep structural assertion script, reused every task — Task 1
```

**Why a redirect stub, not a delete:** the current `privacy.html` may already be the URL entered in Play Console's Data Safety / privacy policy field. Deleting it outright would break that live listing. Task 6 keeps `privacy.html` alive as a thin `<meta http-equiv="refresh">` + canonical-link redirect to `/privacy-policy/`, and flags to the user that they should update the Play Console URL to the clean path when convenient (not required immediately — old URL keeps working).

---

## Task 1: Workspace foundation — tokens, shared styles, assets, test harness

**Files:**
- Create: `tokens.css`
- Create: `styles.css`
- Create: `assets/logo/automate-mark-dark.png`, `assets/logo/automate-mark-light.png`
- Create: `assets/screenshots/dashboard.png`, `efficiency-spending.png`, `history.png`, `reminders.png`
- Create: `tests/check-page.sh`

**Interfaces:**
- Produces: CSS custom properties consumed by every page (`--color-*`, `--font-*`, `--text-*`, `--space-*`, `--ease-*`, `--dur-*`, `--radius-*`); shared classes `.nav`, `.nav__wordmark`, `.nav__links`, `.footer`, `.footer__band`, `.btn`, `.btn--primary`, `.btn--secondary`, `.stat-block`, `.stat-block__figure`, `.compare-table`, `.section`, `.section--dark`, `.eyebrow`, `.container`.
- Consumes: nothing (first task).

- [ ] **Step 1: Copy real assets from the automate-v2 repo**

```bash
cd /mnt/data/projects/arctoslabs-site
mkdir -p assets/logo assets/screenshots tests
cp /mnt/data/projects/automate-v2/assets/images/icon.png assets/logo/automate-mark-dark.png
cp /mnt/data/projects/automate-v2/assets/images/adaptive-icon.png assets/logo/automate-mark-light.png
cp "/mnt/data/projects/automate-v2/assets/screens/Screenshot_20260602-195819.png" assets/screenshots/dashboard.png
cp "/mnt/data/projects/automate-v2/assets/screens/Screenshot_20260602-200042.png" assets/screenshots/efficiency-spending.png
cp "/mnt/data/projects/automate-v2/assets/screens/Screenshot_20260602-200107.png" assets/screenshots/history.png
cp "/mnt/data/projects/automate-v2/assets/screens/Screenshot_20260602-200144.png" assets/screenshots/reminders.png
```

- [ ] **Step 2: Verify the copies landed**

Run: `ls -la assets/logo assets/screenshots`
Expected: 2 files in `assets/logo/`, 4 files in `assets/screenshots/`, all non-zero size.

- [ ] **Step 3: Write the test harness (fails — nothing exists yet)**

Create `tests/check-page.sh`:

```bash
#!/usr/bin/env bash
# Usage: tests/check-page.sh <url-path> <required-string> [<required-string> ...]
# Serves the repo root on :8000, curls the given path, greps for each required string.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m http.server 8000 --bind 127.0.0.1 >/tmp/check-page-server.log 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null' EXIT
sleep 0.5

PATH_ARG="$1"; shift
BODY=$(curl -sf "http://127.0.0.1:8000${PATH_ARG}") || { echo "FAIL: could not fetch ${PATH_ARG}"; exit 1; }

STATUS=0
for needle in "$@"; do
  if ! grep -qF -- "$needle" <<< "$BODY"; then
    echo "FAIL: '${PATH_ARG}' missing required string: $needle"
    STATUS=1
  fi
done
if [ "$STATUS" -eq 0 ]; then
  echo "PASS: ${PATH_ARG} contains all ${#@} required strings"
fi
exit $STATUS
```

```bash
chmod +x tests/check-page.sh
```

- [ ] **Step 4: Run it against a path that doesn't exist yet — verify it fails**

Run: `tests/check-page.sh / "AutoMate"`
Expected: `curl: (22)` / non-2xx, script prints `FAIL: could not fetch /` and exits 1 (no `index.html` exists yet).

- [ ] **Step 5: Write `tokens.css`**

```css
/* Hallmark · macrostructure: Stat-Led · genre: editorial
 * theme: custom · vibe: "precision instrumentation, contained, mechanical-technical" · paper: oklch(98% 0.006 210) · accent: oklch(66% 0.160 62)
 * display: JetBrains Mono · body: IBM Plex Sans · axes: light / mono / warm (amber ~62°)
 * studied: no · context: user-provided · v1.0.0
 */
:root {
  /* — color — */
  --color-paper: #F2F8F9;
  --color-paper-2: #E5EDEE;
  --color-graphite: #0C1617;
  --color-graphite-2: #162123;
  --color-ink: #101819;
  --color-ink-2: #464F51;
  --color-rule: #B7C0C1;
  --color-muted: #5C6567;
  --color-accent: #D57700;
  --color-focus: #DD6600;
  --color-ink-on-graphite: #E4EDEF;

  /* — type — */
  --font-display: "JetBrains Mono", ui-monospace, "SFMono-Regular", Menlo, monospace;
  --font-body: "IBM Plex Sans", ui-sans-serif, system-ui, -apple-system, sans-serif;

  /* — scale (1.25 major third, 16px base) — */
  --text-xs: 0.64rem;
  --text-sm: 0.8rem;
  --text-base: 1rem;
  --text-md: 1.25rem;
  --text-lg: 1.5625rem;
  --text-xl: 1.9531rem;
  --text-2xl: 2.4414rem;
  --text-3xl: 3.0518rem;
  --text-display: clamp(2.75rem, 5vw + 1rem, 5.25rem);
  --text-display-s: clamp(2rem, 3.5vw + 1rem, 3.5rem);

  /* — space (4pt scale) — */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2.5rem;
  --space-2xl: 4rem;
  --space-3xl: 6rem;

  /* — motion — */
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in: cubic-bezier(0.7, 0, 0.84, 0);
  --ease-in-out: cubic-bezier(0.65, 0, 0.35, 1);
  --dur-fast: 120ms;
  --dur-base: 200ms;
  --dur-slow: 360ms;

  /* — misc — */
  --radius-sm: 2px;
  --radius-md: 4px;
  --measure: 65ch;
}

@media (prefers-reduced-motion: reduce) {
  :root {
    --dur-fast: 1ms;
    --dur-base: 1ms;
    --dur-slow: 1ms;
  }
}
```

- [ ] **Step 6: Write `styles.css`**

```css
/* Hallmark · consumes tokens.css — shared components for all 5 pages */
*, *::before, *::after { box-sizing: border-box; }
html, body { overflow-x: clip; }
html { -webkit-text-size-adjust: 100%; }

body {
  margin: 0;
  background: var(--color-paper);
  color: var(--color-ink);
  font-family: var(--font-body);
  font-size: var(--text-base);
  line-height: 1.6;
  font-variant-numeric: tabular-nums;
}

h1, h2, h3 {
  font-family: var(--font-display);
  line-height: 1.1;
  letter-spacing: -0.02em;
  margin: 0 0 var(--space-md);
  overflow-wrap: anywhere;
  min-width: 0;
}
h1 { font-weight: 700; }
h2 { font-weight: 700; font-size: var(--text-2xl); }
h3 { font-weight: 500; font-size: var(--text-lg); }

p { margin: 0 0 var(--space-md); max-width: var(--measure); }
a { color: var(--color-accent); }
a:focus-visible, button:focus-visible, details > summary:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
  transition: none;
}

.container {
  max-width: 1120px;
  margin: 0 auto;
  padding: 0 var(--space-lg);
}

.eyebrow {
  font-family: var(--font-display);
  font-size: var(--text-sm);
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--color-muted);
  display: block;
  margin-bottom: var(--space-sm);
}

/* — section rhythm — */
.section { padding: var(--space-3xl) 0; border-bottom: 1px solid var(--color-rule); }
.section:last-of-type { border-bottom: none; }
.section--dark {
  background: var(--color-graphite);
  color: var(--color-ink-on-graphite);
  border-bottom-color: var(--color-graphite-2);
}
.section--dark .eyebrow { color: var(--color-accent); }
.section--dark a { color: var(--color-accent); }

/* — nav (N9 edge-aligned minimal) — */
.nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-md);
  padding: var(--space-md) var(--space-lg);
  border-bottom: 1px solid var(--color-rule);
  flex-wrap: wrap;
}
.nav__wordmark {
  font-family: var(--font-display);
  font-weight: 700;
  font-size: var(--text-md);
  color: var(--color-ink);
  text-decoration: none;
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}
.nav__wordmark img { height: 1.5rem; width: auto; }
.nav__links {
  display: flex;
  gap: var(--space-lg);
  list-style: none;
  margin: 0;
  padding: 0;
  flex-wrap: wrap;
}
.nav__links a {
  color: var(--color-ink-2);
  text-decoration: none;
  font-size: var(--text-sm);
  white-space: nowrap;
}
.nav__links a:hover, .nav__links a[aria-current="page"] { color: var(--color-accent); }

/* — footer (Ft6 letter-close voice, graphite band) — */
.footer {
  background: var(--color-graphite);
  color: var(--color-ink-on-graphite);
  padding: var(--space-2xl) 0;
}
.footer .container {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--space-xl);
}
.footer__wordmark {
  font-family: var(--font-display);
  font-weight: 700;
  color: var(--color-ink-on-graphite);
  text-decoration: none;
  font-size: var(--text-md);
}
.footer__links {
  display: flex;
  gap: var(--space-lg);
  list-style: none;
  margin: 0;
  padding: 0;
  flex-wrap: wrap;
}
.footer__links a { color: var(--color-ink-on-graphite); font-size: var(--text-sm); text-decoration: none; }
.footer__links a:hover { color: var(--color-accent); }
.footer__copyright { color: var(--color-rule); font-size: var(--text-xs); width: 100%; margin-top: var(--space-lg); }

/* — buttons — */
.btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-sm);
  padding: var(--space-sm) var(--space-lg);
  border-radius: var(--radius-sm);
  font-family: var(--font-display);
  font-size: var(--text-sm);
  font-weight: 500;
  text-decoration: none;
  border: 1px solid transparent;
  cursor: pointer;
  transition: transform var(--dur-fast) var(--ease-out), background var(--dur-base) var(--ease-out);
  white-space: nowrap;
}
.btn:active { transform: translateY(1px); }
.btn--primary { background: var(--color-accent); color: var(--color-graphite); }
.btn--primary:hover { background: var(--color-focus); }
.btn--secondary {
  background: transparent;
  border-color: currentColor;
  color: inherit;
}
.section--dark .btn--secondary { color: var(--color-ink-on-graphite); }

/* — odometer stat block (hero) — */
.stat-block { text-align: left; }
.stat-block__figure {
  font-family: var(--font-display);
  font-weight: 700;
  font-size: var(--text-display);
  line-height: 1;
  color: var(--color-ink-on-graphite);
  border-bottom: 3px solid var(--color-accent);
  display: inline-block;
  padding-bottom: var(--space-xs);
}
.stat-block__label {
  font-size: var(--text-md);
  color: var(--color-rule);
  margin-top: var(--space-md);
  max-width: 40ch;
}

/* — feature grid (2-col on tablet+, 1-col mobile) — */
.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 20rem), 1fr));
  gap: var(--space-xl);
}
.feature-grid__icon { color: var(--color-accent); margin-bottom: var(--space-sm); }
.feature-grid__icon svg { width: 2rem; height: 2rem; }

/* — comparison table (spec-sheet style) — */
.compare-table-wrap { overflow-x: auto; }
.compare-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--text-sm);
  min-width: 36rem;
}
.compare-table th, .compare-table td {
  padding: var(--space-sm) var(--space-md);
  border-bottom: 1px solid var(--color-rule);
  text-align: left;
}
.compare-table thead th {
  background: var(--color-graphite);
  color: var(--color-ink-on-graphite);
  font-family: var(--font-display);
  font-weight: 500;
  position: sticky;
  top: 0;
}
.compare-table td:first-child, .compare-table th:first-child { font-weight: 600; }
.compare-table .yes { color: var(--color-accent); font-weight: 700; }
.compare-table .no { color: var(--color-muted); }

/* — responsive floor — */
@media (max-width: 480px) {
  .nav { padding: var(--space-sm) var(--space-md); }
  .section { padding: var(--space-2xl) 0; }
}
```

- [ ] **Step 7: Verify the CSS parses (no build tool — use a syntax sniff)**

Run: `python3 -c "import re,sys; s=open('styles.css').read(); assert s.count('{')==s.count('}'), 'brace mismatch'; print('OK', s.count(chr(123)), 'rules')"`
Expected: `OK <N> rules` (brace-balanced; catches the most common hand-edit typo).

- [ ] **Step 8: Commit**

```bash
git add tokens.css styles.css assets tests
git commit -m "chore: add design tokens, shared styles, real assets, test harness"
```

---

## Task 2: Homepage (`index.html`)

**Files:**
- Create: `index.html`
- Modify: `tests/check-page.sh` (no changes — reused as-is)

**Interfaces:**
- Consumes: every class/token from Task 1 (`.nav`, `.footer`, `.btn--primary`, `.stat-block`, `.feature-grid`, `.section--dark`).
- Produces: the nav/footer markup block that Tasks 3, 5, 6, 7 copy verbatim (only the `aria-current="page"` link and canonical `<link>` differ per page).

- [ ] **Step 1: Write the failing test**

```bash
tests/check-page.sh / \
  "<title>AutoMate" \
  "no ads, no account" \
  "play.google.com/store/apps/details?id=com.arctosbuilt.automate" \
  "vs-drivvo" \
  "press-kit"
```

Run it now (before `index.html` exists) — expected: `FAIL: could not fetch /`.

- [ ] **Step 2: Write `index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AutoMate — Track your car's expenses. Own your data.</title>
<meta name="description" content="AutoMate is an ad-free, offline car expense and fuel tracker. No account required, all data stored on your device. Fuel efficiency, maintenance reminders, multi-vehicle support, CSV/PDF export.">
<link rel="canonical" href="https://banderberg.github.io/arctoslabs/">
<link rel="icon" href="assets/logo/automate-mark-dark.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;700&family=IBM+Plex+Sans:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="tokens.css">
<link rel="stylesheet" href="styles.css">
</head>
<body>

<nav class="nav" aria-label="Primary">
  <a class="nav__wordmark" href="/" aria-label="AutoMate home">
    <img src="assets/logo/automate-mark-dark.png" alt="" width="24" height="24">
    AutoMate
  </a>
  <ul class="nav__links">
    <li><a href="vs-drivvo/" aria-label="Compare AutoMate to Drivvo">vs. Drivvo</a></li>
    <li><a href="vs-fuelio/" aria-label="Compare AutoMate to Fuelio">vs. Fuelio</a></li>
    <li><a href="press-kit/">Press</a></li>
    <li><a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play">Get the app</a></li>
  </ul>
</nav>

<header class="section section--dark">
  <div class="container">
    <div class="stat-block">
      <span class="eyebrow">AutoMate · car expense &amp; fuel tracker</span>
      <h1>Track your car's expenses. Own your data.</h1>
      <p class="stat-block__label" style="color: var(--color-ink-on-graphite);">No ads. No account. No cloud lock-in. Every fill-up, service, and expense stays on your device — not on someone else's server.</p>
      <div style="margin-top: var(--space-xl); display: flex; gap: var(--space-md); flex-wrap: wrap;">
        <a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play">Get it on Google Play</a>
        <a class="btn btn--secondary" href="vs-drivvo/">Switching from Drivvo?</a>
      </div>
    </div>
  </div>
</header>

<section class="section" aria-label="Key facts">
  <div class="container feature-grid">
    <div>
      <span class="stat-block__figure" style="font-size: var(--text-3xl); color: var(--color-ink);">0</span>
      <p class="eyebrow" style="margin-top: var(--space-sm);">ads shown, ever</p>
    </div>
    <div>
      <span class="stat-block__figure" style="font-size: var(--text-3xl); color: var(--color-ink);">100%</span>
      <p class="eyebrow" style="margin-top: var(--space-sm);">of your data stays on your device</p>
    </div>
    <div>
      <span class="stat-block__figure" style="font-size: var(--text-3xl); color: var(--color-ink);">7</span>
      <p class="eyebrow" style="margin-top: var(--space-sm);">languages supported</p>
    </div>
  </div>
</section>

<section class="section" id="features">
  <div class="container">
    <span class="eyebrow">What it does</span>
    <h2>Four instruments, one dashboard.</h2>
    <div class="feature-grid" style="margin-top: var(--space-xl);">
      <div>
        <div class="feature-grid__icon" aria-hidden="true">
          <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M8 20V12a4 4 0 0 1 4-4h8a4 4 0 0 1 4 4v8"/><rect x="6" y="20" width="20" height="6" rx="1"/><circle cx="11" cy="26" r="1.5"/><circle cx="21" cy="26" r="1.5"/><path d="M24 14h2a2 2 0 0 1 2 2v4h-4"/></svg>
        </div>
        <h3>Fuel efficiency tracking</h3>
        <p>Log every fill-up and watch your real MPG or L/100km trend over time — by tank, by month, by vehicle.</p>
      </div>
      <div>
        <div class="feature-grid__icon" aria-hidden="true">
          <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="6" y="5" width="20" height="24" rx="1"/><path d="M10 11h12M10 15h12M10 19h8"/></svg>
        </div>
        <h3>All-in-one expense tracking</h3>
        <p>Fuel, service, and general expenses in one ledger. Multi-vehicle and small-fleet support built in from day one.</p>
      </div>
      <div>
        <div class="feature-grid__icon" aria-hidden="true">
          <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="16" cy="16" r="11"/><path d="M16 9v7l5 3"/></svg>
        </div>
        <h3>Non-intrusive reminders</h3>
        <p>Maintenance reminders by mileage or by date — tire rotations, oil changes, registration. Set once, forget until it matters.</p>
      </div>
      <div>
        <div class="feature-grid__icon" aria-hidden="true">
          <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M8 6h12l4 4v16H8z"/><path d="M20 6v4h4"/><path d="M12 17l3 3 5-6"/></svg>
        </div>
        <h3>CSV / PDF export, one-tap import</h3>
        <p>Export your full history anytime. Switching from Fuelio or Drivvo? Import your existing records in one tap.</p>
      </div>
    </div>
  </div>
</section>

<section class="section section--dark" aria-label="Why local and ad-free matters">
  <div class="container">
    <span class="eyebrow">Why it's built this way</span>
    <h2>Most free trackers monetize you. This one doesn't.</h2>
    <p style="max-width: 60ch; color: var(--color-ink-on-graphite);">Ad-supported and freemium car-tracking apps pay for themselves with your attention and your data — banner ads between entries, subscription walls around basic export, or your usage patterns sold to advertisers. AutoMate has none of that: no ad SDKs, no account to create, no server your data has to round-trip through. Your fuel logs and service history live in a local database on your phone. If you export a CSV, that's the only copy that ever leaves the device — and only because you asked for it.</p>
  </div>
</section>

<section class="section" aria-label="Language support">
  <div class="container" style="text-align: center;">
    <span class="eyebrow">Available in</span>
    <h2 style="font-size: var(--text-xl);">7 languages, and counting</h2>
    <p style="margin: 0 auto;">English &middot; Spanish &middot; Portuguese &middot; and more — full localization, not machine-translated labels bolted onto an English app.</p>
  </div>
</section>

<section class="section" aria-label="Final call to action" style="text-align: center;">
  <div class="container">
    <h2>Your car. Your expenses. Your data.</h2>
    <a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play">Get it on Google Play</a>
  </div>
</section>

<footer class="footer">
  <div class="container">
    <a class="footer__wordmark" href="/">AutoMate</a>
    <ul class="footer__links">
      <li><a href="privacy-policy/">Privacy Policy</a></li>
      <li><a href="press-kit/">Press Kit</a></li>
      <li><a href="mailto:arctos.built@gmail.com">Contact</a></li>
    </ul>
    <p class="footer__copyright">&copy; 2026 Arctos Labs. AutoMate is built and maintained by a solo developer.</p>
  </div>
</footer>

</body>
</html>
```

- [ ] **Step 3: Run the test again — verify it passes**

Run:
```bash
tests/check-page.sh / \
  "<title>AutoMate" \
  "no ads, no account" \
  "play.google.com/store/apps/details?id=com.arctosbuilt.automate" \
  "vs-drivvo" \
  "press-kit"
```
Expected: `PASS: / contains all 5 required strings`

Note: the exact phrase in the file is "No ads. No account. No cloud lock-in." (capitalized, separate sentences) — if the grep is case-sensitive and fails on casing, adjust the test's needle to `"No ads. No account."` and re-run. Fix the test to match the shipped copy, don't rewrite the copy to match a guessed test string.

- [ ] **Step 4: Manual responsive check**

Run: `python3 -m http.server 8000 --bind 127.0.0.1 --directory .` then open `http://127.0.0.1:8000/` in a browser (or resize a headless screenshot tool) at 320px, 375px, 414px, 768px widths. Confirm: no horizontal scrollbar, nav wraps to two rows cleanly instead of overflowing, hero stat figure doesn't clip.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: build AutoMate homepage (Stat-Led hero, feature grid, why-local section)"
```

---

## Task 3: `/vs-drivvo` comparison page

**Files:**
- Create: `vs-drivvo/index.html`

**Interfaces:**
- Consumes: `.compare-table`, `.compare-table-wrap`, nav/footer block from Task 2 (copied, with `aria-current="page"` moved to the "vs. Drivvo" link and `<link rel="canonical">` updated).
- Produces: the comparison-table markup pattern Task 5 reuses for Fuelio (same `<table class="compare-table">` structure, different row data).

- [ ] **Step 1: Write the failing test**

```bash
tests/check-page.sh /vs-drivvo/ \
  "<title>AutoMate vs. Drivvo" \
  "compare-table" \
  "solo developer" \
  "play.google.com/store/apps/details?id=com.arctosbuilt.automate"
```

Run now — expected: `FAIL: could not fetch /vs-drivvo/`.

- [ ] **Step 2: Write `vs-drivvo/index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AutoMate vs. Drivvo — a straightforward comparison</title>
<meta name="description" content="Comparing AutoMate and Drivvo on ads, account requirements, data storage, price, and features — for anyone weighing a switch after Drivvo's price increase.">
<link rel="canonical" href="https://banderberg.github.io/arctoslabs/vs-drivvo/">
<link rel="icon" href="../assets/logo/automate-mark-dark.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;700&family=IBM+Plex+Sans:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../tokens.css">
<link rel="stylesheet" href="../styles.css">
</head>
<body>

<nav class="nav" aria-label="Primary">
  <a class="nav__wordmark" href="/" aria-label="AutoMate home">
    <img src="../assets/logo/automate-mark-dark.png" alt="" width="24" height="24">
    AutoMate
  </a>
  <ul class="nav__links">
    <li><a href="../vs-drivvo/" aria-current="page">vs. Drivvo</a></li>
    <li><a href="../vs-fuelio/">vs. Fuelio</a></li>
    <li><a href="../press-kit/">Press</a></li>
    <li><a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play">Get the app</a></li>
  </ul>
</nav>

<header class="section section--dark">
  <div class="container">
    <span class="eyebrow">Comparison</span>
    <h1 style="font-size: var(--text-display-s);">AutoMate vs. Drivvo</h1>
    <p style="color: var(--color-ink-on-graphite); max-width: 60ch;">If a recent price change sent you looking for an alternative, here's a factual side-by-side. AutoMate is a free, ad-free, offline-first alternative built by one developer, not a product team optimizing for upsells.</p>
    <a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play" style="margin-top: var(--space-lg); display: inline-flex;">Get it on Google Play</a>
  </div>
</header>

<section class="section">
  <div class="container">
    <h2 style="font-size: var(--text-xl);">Side by side</h2>
    <div class="compare-table-wrap">
      <table class="compare-table">
        <thead>
          <tr><th scope="col">&nbsp;</th><th scope="col">AutoMate</th><th scope="col">Drivvo</th></tr>
        </thead>
        <tbody>
          <tr><th scope="row">Ads</th><td class="no">None</td><td>Ad-supported free tier</td></tr>
          <tr><th scope="row">Account required</th><td class="no">No</td><td>Optional account for cloud sync</td></tr>
          <tr><th scope="row">Data storage</th><td>Local, on-device only</td><td>Local + optional cloud sync</td></tr>
          <tr><th scope="row">Price</th><td class="yes">Free</td><td>Free with ads; paid tier removes ads / unlocks features</td></tr>
          <tr><th scope="row">Multi-vehicle</th><td class="yes">Yes</td><td class="yes">Yes</td></tr>
          <tr><th scope="row">Fuel efficiency tracking</th><td class="yes">Yes</td><td class="yes">Yes</td></tr>
          <tr><th scope="row">Maintenance reminders</th><td class="yes">Yes — by mileage or date</td><td class="yes">Yes</td></tr>
          <tr><th scope="row">CSV / PDF export</th><td class="yes">Yes, both formats</td><td>Varies by plan</td></tr>
          <tr><th scope="row">One-tap import from Drivvo</th><td class="yes">Yes</td><td>&mdash;</td></tr>
        </tbody>
      </table>
    </div>
    <p style="font-size: var(--text-xs); color: var(--color-muted); margin-top: var(--space-sm);">Drivvo details reflect its publicly listed free-tier behavior as of this writing; check Drivvo's current Play Store listing for their latest pricing.</p>
  </div>
</section>

<section class="section" aria-label="Switching is easy">
  <div class="container">
    <span class="eyebrow">Switching</span>
    <h2 style="font-size: var(--text-xl);">Bring your history with you</h2>
    <ol style="max-width: 60ch; padding-left: 1.25rem;">
      <li>Export your data from Drivvo (Settings &rarr; Export/Backup).</li>
      <li>Open AutoMate &rarr; Import &rarr; select the exported file.</li>
      <li>Your fuel logs, service history, and vehicles carry over — nothing to re-enter by hand.</li>
    </ol>
  </div>
</section>

<section class="section section--dark" aria-label="Built by a solo developer">
  <div class="container">
    <span class="eyebrow">Who's behind it</span>
    <h2 style="font-size: var(--text-xl);">One developer, not a growth team</h2>
    <p style="color: var(--color-ink-on-graphite); max-width: 60ch;">AutoMate is built and maintained by a single developer. There's no roadmap built around upsells, no A/B-tested paywall timing, no growth team deciding when to start showing ads. The incentive is simply to make the app good enough that you keep using it.</p>
  </div>
</section>

<section class="section" aria-label="Final call to action" style="text-align: center;">
  <div class="container">
    <h2 style="font-size: var(--text-xl);">Try AutoMate</h2>
    <a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play">Get it on Google Play</a>
  </div>
</section>

<footer class="footer">
  <div class="container">
    <a class="footer__wordmark" href="/">AutoMate</a>
    <ul class="footer__links">
      <li><a href="../privacy-policy/">Privacy Policy</a></li>
      <li><a href="../press-kit/">Press Kit</a></li>
      <li><a href="mailto:arctos.built@gmail.com">Contact</a></li>
    </ul>
    <p class="footer__copyright">&copy; 2026 Arctos Labs. AutoMate is built and maintained by a solo developer.</p>
  </div>
</footer>

</body>
</html>
```

- [ ] **Step 3: Run the test — verify it passes**

Run the same command from Step 1. Expected: `PASS: /vs-drivvo/ contains all 4 required strings`.

- [ ] **Step 4: Commit**

```bash
git add vs-drivvo/
git commit -m "feat: build /vs-drivvo comparison page"
```

---

## Task 4: Research current Fuelio pricing/features (WebSearch — no code)

**Files:** none created; this task's output is a short fact sheet pasted into Task 5's plan context (below), not a repo file.

- [ ] **Step 1: Run a WebSearch for Fuelio's current Google Play listing**

Search: `Fuelio car maintenance fuel log app Google Play price features 2026`. Cross-check against the app's actual Play Store listing page if the search result links to it.

- [ ] **Step 2: Extract exactly these fields, with the source URL and today's date recorded next to each**

- Is Fuelio free, freemium, or paid? What does the free tier include/exclude?
- Does it show ads? On which tier?
- Does it require an account?
- Local-only storage, or cloud sync (optional or required)?
- Multi-vehicle support?
- Fuel efficiency tracking (native feature)?
- Maintenance reminders (native feature)?
- CSV/PDF export — native, or paid add-on?

- [ ] **Step 3: Flag anything that couldn't be confirmed**

If the Play Store listing is ambiguous about a field (e.g. export is mentioned but it's unclear if it's free or gated), write it into Task 5's table as "unconfirmed — verify before publishing" rather than guessing a yes/no. Do not fill the cell with a plausible-sounding default.

- [ ] **Step 4: Hand the fact sheet + source URL + date to Task 5**

No commit — this is research input, not a file change.

---

## Task 5: `/vs-fuelio` comparison page

**Files:**
- Create: `vs-fuelio/index.html`

**Interfaces:**
- Consumes: Task 4's fact sheet (exact field values + source URL + date); `.compare-table` markup pattern from Task 3.
- Produces: nothing consumed downstream.

- [ ] **Step 1: Write the failing test**

```bash
tests/check-page.sh /vs-fuelio/ \
  "<title>AutoMate vs. Fuelio" \
  "compare-table" \
  "play.google.com/store/apps/details?id=com.arctosbuilt.automate"
```

Run now — expected: `FAIL: could not fetch /vs-fuelio/`.

- [ ] **Step 2: Write `vs-fuelio/index.html`**

Copy the full structure of `vs-drivvo/index.html` (Task 3), with these required changes:
- `<title>`, `<meta name="description">`, `<link rel="canonical">` → Fuelio-specific.
- Nav: swap `aria-current="page"` to the "vs. Fuelio" link.
- Hero copy: reframe around Fuelio specifically (don't reuse "price increase" framing unless Task 4's research confirms Fuelio also raised prices — if it didn't, use neutral framing: "comparing your options").
- `<table class="compare-table">` body: replace every Drivvo-column value with the **exact fields Task 4 returned**, each one matching what Task 4 confirmed — not invented. Any field Task 4 flagged as unconfirmed gets the literal cell text `Unconfirmed — check Fuelio's current listing`, not a guess.
- Footnote under the table: cite Task 4's source URL and the access date, e.g. `Fuelio details reflect its public Google Play listing as of <date>, <source-url>. Check Fuelio's current listing for up-to-date pricing.`
- "Switching" section: adapt the 3-step list to Fuelio's actual export mechanism if Task 4 found it (e.g. a different menu path) — otherwise keep the generic "Settings → Export/Backup" phrasing since that's a reasonable default across this category of app, and don't state a specific menu path unless confirmed.

- [ ] **Step 3: Run the test — verify it passes**

Run the Step 1 command again. Expected: `PASS: /vs-fuelio/ contains all 3 required strings`.

- [ ] **Step 4: Read back the finished page once and confirm no cell states a fact Task 4 didn't actually confirm.** This is a manual check, not a script — the whole point of Task 4 was avoiding fabricated competitor claims, so this step exists to catch a drift back into guessing while writing the HTML.

- [ ] **Step 5: Commit**

```bash
git add vs-fuelio/
git commit -m "feat: build /vs-fuelio comparison page (sourced via WebSearch)"
```

---

## Task 6: `/privacy-policy` + redirect stub at the old `/privacy.html`

**Files:**
- Create: `privacy-policy/index.html`
- Modify: `privacy.html` (replace entire content with a redirect stub)

**Interfaces:**
- Consumes: confirmed fact — Crashlytics is in use (crash reporting must be disclosed). Confirmed facts — no account required, no analytics beyond what Play's Data Safety form discloses, all data local.
- Produces: nothing consumed downstream.

- [ ] **Step 1: Write the failing test**

```bash
tests/check-page.sh /privacy-policy/ \
  "<title>Privacy Policy" \
  "Crashlytics" \
  "does not require an account" \
  "local"
```

Run now — expected: `FAIL: could not fetch /privacy-policy/`.

- [ ] **Step 2: Write `privacy-policy/index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Privacy Policy — AutoMate</title>
<meta name="description" content="AutoMate's privacy policy: no account required, no data collection beyond anonymous crash reports, all car and expense data stored locally on your device.">
<link rel="canonical" href="https://banderberg.github.io/arctoslabs/privacy-policy/">
<link rel="icon" href="../assets/logo/automate-mark-dark.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;700&family=IBM+Plex+Sans:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../tokens.css">
<link rel="stylesheet" href="../styles.css">
</head>
<body>

<nav class="nav" aria-label="Primary">
  <a class="nav__wordmark" href="/" aria-label="AutoMate home">
    <img src="../assets/logo/automate-mark-dark.png" alt="" width="24" height="24">
    AutoMate
  </a>
  <ul class="nav__links">
    <li><a href="../vs-drivvo/">vs. Drivvo</a></li>
    <li><a href="../vs-fuelio/">vs. Fuelio</a></li>
    <li><a href="../press-kit/">Press</a></li>
    <li><a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play">Get the app</a></li>
  </ul>
</nav>

<header class="section">
  <div class="container">
    <span class="eyebrow">Legal</span>
    <h1 style="font-size: var(--text-display-s);">Privacy Policy</h1>
    <p style="color: var(--color-muted);">Last updated: <time datetime="2026-07-15">July 15, 2026</time></p>
  </div>
</header>

<section class="section">
  <div class="container" style="max-width: var(--measure);">

    <h2 style="font-size: var(--text-lg);">No account required</h2>
    <p>AutoMate does not require you to create an account, sign in, or provide any personal information to use the app. There is no user registration and no login system.</p>

    <h2 style="font-size: var(--text-lg);">Your data stays on your device</h2>
    <p>All vehicle, fuel, service, and expense data you enter is stored in a local database on your device. AutoMate does not upload this data to any server, and there is no cloud sync feature. If you use the CSV or PDF export feature, the exported file is created on your device and shared only through the share method you explicitly choose (e.g. email, a messaging app, or saving to a file).</p>

    <h2 style="font-size: var(--text-lg);">Crash reporting</h2>
    <p>AutoMate uses Firebase Crashlytics to collect anonymous crash reports when the app encounters an unexpected error. This helps identify and fix bugs. Crash reports may include technical information such as device model, OS version, and the state of the app at the time of the crash — they do not include your vehicle, fuel, or expense data.</p>

    <h2 style="font-size: var(--text-lg);">No ads, no ad tracking</h2>
    <p>AutoMate does not display ads and does not integrate any advertising SDK or ad-tracking library.</p>

    <h2 style="font-size: var(--text-lg);">Data safety details</h2>
    <p>For the complete, itemized breakdown of what data (if any) is collected and shared, see AutoMate's Data Safety section on its <a href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate">Google Play Store listing</a>, which is kept in sync with this policy.</p>

    <h2 style="font-size: var(--text-lg);">Permissions</h2>
    <p>AutoMate may request device permissions (such as camera, for scanning a document or barcode, or location, for tagging a fuel stop's place) strictly to power the corresponding in-app feature. Denying a permission disables only that feature — the rest of the app continues to work fully offline.</p>

    <h2 style="font-size: var(--text-lg);">Changes to this policy</h2>
    <p>If this policy changes, the "Last updated" date above will change accordingly. Continued use of the app after an update constitutes acceptance of the revised policy.</p>

    <h2 style="font-size: var(--text-lg);">Contact</h2>
    <p>Questions about this policy: <a href="mailto:arctos.built@gmail.com">arctos.built@gmail.com</a></p>

  </div>
</section>

<footer class="footer">
  <div class="container">
    <a class="footer__wordmark" href="/">AutoMate</a>
    <ul class="footer__links">
      <li><a href="../privacy-policy/">Privacy Policy</a></li>
      <li><a href="../press-kit/">Press Kit</a></li>
      <li><a href="mailto:arctos.built@gmail.com">Contact</a></li>
    </ul>
    <p class="footer__copyright">&copy; 2026 Arctos Labs. AutoMate is built and maintained by a solo developer.</p>
  </div>
</footer>

</body>
</html>
```

- [ ] **Step 3: Run the test — verify it passes**

Run the Step 1 command again. Expected: `PASS: /privacy-policy/ contains all 4 required strings`.

- [ ] **Step 4: Replace `privacy.html` with a redirect stub (preserves the old URL Play Console may already reference)**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="0; url=/arctoslabs/privacy-policy/">
<link rel="canonical" href="https://banderberg.github.io/arctoslabs/privacy-policy/">
<title>Privacy Policy — AutoMate (moved)</title>
</head>
<body>
<p>This page has moved. <a href="/arctoslabs/privacy-policy/">Continue to the AutoMate Privacy Policy</a>.</p>
</body>
</html>
```

- [ ] **Step 5: Test the redirect stub**

```bash
tests/check-page.sh /privacy.html "url=/arctoslabs/privacy-policy/" "Continue to the AutoMate Privacy Policy"
```
Expected: `PASS: /privacy.html contains all 2 required strings`.

- [ ] **Step 6: Commit**

```bash
git add privacy-policy/ privacy.html
git commit -m "feat: build /privacy-policy, redirect legacy /privacy.html"
```

- [ ] **Step 7: Flag to the user (no code change)** — after this task, tell the user: "the old `/privacy.html` URL now redirects to `/privacy-policy/`, so any existing link (e.g. in Play Console's Data Safety form) keeps working. When convenient, update that Play Console field to the new `/privacy-policy/` URL directly — not required immediately."

---

## Task 7: `/press-kit`

**Files:**
- Create: `press-kit/index.html`

**Interfaces:**
- Consumes: `assets/logo/automate-mark-dark.png`, `assets/logo/automate-mark-light.png`, all 4 files in `assets/screenshots/` from Task 1.
- Produces: nothing consumed downstream.

- [ ] **Step 1: Write the failing test**

```bash
tests/check-page.sh /press-kit/ \
  "<title>Press Kit" \
  "automate-mark-dark.png" \
  "automate-mark-light.png" \
  "dashboard.png" \
  "arctos.built@gmail.com"
```

Run now — expected: `FAIL: could not fetch /press-kit/`.

- [ ] **Step 2: Write `press-kit/index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Press Kit — AutoMate</title>
<meta name="description" content="AutoMate press kit: logo downloads, screenshots, short and long descriptions, and contact information for press inquiries.">
<link rel="canonical" href="https://banderberg.github.io/arctoslabs/press-kit/">
<link rel="icon" href="../assets/logo/automate-mark-dark.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;700&family=IBM+Plex+Sans:wght@400;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../tokens.css">
<link rel="stylesheet" href="../styles.css">
<style>
  .asset-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 14rem), 1fr)); gap: var(--space-lg); }
  .asset-card { border: 1px solid var(--color-rule); border-radius: var(--radius-md); padding: var(--space-md); text-align: center; }
  .asset-card img { max-width: 100%; height: 8rem; object-fit: contain; margin-bottom: var(--space-sm); }
  .asset-card--dark { background: var(--color-graphite); }
  .screenshot-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 12rem), 1fr)); gap: var(--space-lg); }
  .screenshot-grid img { width: 100%; border-radius: var(--radius-md); border: 1px solid var(--color-rule); }
</style>
</head>
<body>

<nav class="nav" aria-label="Primary">
  <a class="nav__wordmark" href="/" aria-label="AutoMate home">
    <img src="../assets/logo/automate-mark-dark.png" alt="" width="24" height="24">
    AutoMate
  </a>
  <ul class="nav__links">
    <li><a href="../vs-drivvo/">vs. Drivvo</a></li>
    <li><a href="../vs-fuelio/">vs. Fuelio</a></li>
    <li><a href="../press-kit/" aria-current="page">Press</a></li>
    <li><a class="btn btn--primary" href="https://play.google.com/store/apps/details?id=com.arctosbuilt.automate" aria-label="Get AutoMate on Google Play">Get the app</a></li>
  </ul>
</nav>

<header class="section">
  <div class="container">
    <span class="eyebrow">Press Kit</span>
    <h1 style="font-size: var(--text-display-s);">AutoMate</h1>
    <p style="color: var(--color-muted);">Everything you need to write about AutoMate.</p>
  </div>
</header>

<section class="section">
  <div class="container">
    <h2 style="font-size: var(--text-lg);">Descriptions</h2>
    <p><strong>Short:</strong> AutoMate is an ad-free, offline car expense and fuel tracker — no account required, all data stored on your device.</p>
    <p><strong>Long:</strong> AutoMate helps drivers track fuel efficiency, maintenance, and expenses across one or several vehicles without ads, accounts, or a cloud subscription. Every fill-up, service record, and expense is stored locally on the device — nothing is uploaded unless the user explicitly exports it. AutoMate supports multi-vehicle and small-fleet use, mileage- or date-based maintenance reminders, CSV/PDF export, and one-tap import from Drivvo and Fuelio. The app is available in 7 languages and is built and maintained by a solo developer.</p>
  </div>
</section>

<section class="section">
  <div class="container">
    <h2 style="font-size: var(--text-lg);">Logo</h2>
    <div class="asset-grid">
      <div class="asset-card">
        <img src="../assets/logo/automate-mark-light.png" alt="AutoMate logo, light background version">
        <a class="btn btn--secondary" href="../assets/logo/automate-mark-light.png" download>Download (light bg)</a>
      </div>
      <div class="asset-card asset-card--dark">
        <img src="../assets/logo/automate-mark-dark.png" alt="AutoMate logo, dark background version">
        <a class="btn btn--secondary" href="../assets/logo/automate-mark-dark.png" download style="color: var(--color-ink-on-graphite);">Download (dark bg)</a>
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <h2 style="font-size: var(--text-lg);">Screenshots</h2>
    <div class="screenshot-grid">
      <figure style="margin: 0;">
        <img src="../assets/screenshots/dashboard.png" alt="AutoMate dashboard showing total spent, cost per mile, average MPG, and projected annual cost">
        <figcaption class="eyebrow" style="margin-top: var(--space-sm);">Dashboard</figcaption>
      </figure>
      <figure style="margin: 0;">
        <img src="../assets/screenshots/efficiency-spending.png" alt="AutoMate fuel efficiency trend chart and monthly spending breakdown by category">
        <figcaption class="eyebrow" style="margin-top: var(--space-sm);">Fuel efficiency &amp; spending</figcaption>
      </figure>
      <figure style="margin: 0;">
        <img src="../assets/screenshots/history.png" alt="AutoMate expense history list, filterable by fuel, service, expense, and mileage">
        <figcaption class="eyebrow" style="margin-top: var(--space-sm);">History</figcaption>
      </figure>
      <figure style="margin: 0;">
        <img src="../assets/screenshots/reminders.png" alt="AutoMate maintenance reminders showing tire rotation, oil change, and registration status">
        <figcaption class="eyebrow" style="margin-top: var(--space-sm);">Reminders</figcaption>
      </figure>
    </div>
  </div>
</section>

<section class="section section--dark">
  <div class="container">
    <h2 style="font-size: var(--text-lg);">Contact</h2>
    <p style="color: var(--color-ink-on-graphite);">Press inquiries: <a href="mailto:arctos.built@gmail.com">arctos.built@gmail.com</a></p>
  </div>
</section>

<footer class="footer">
  <div class="container">
    <a class="footer__wordmark" href="/">AutoMate</a>
    <ul class="footer__links">
      <li><a href="../privacy-policy/">Privacy Policy</a></li>
      <li><a href="../press-kit/">Press Kit</a></li>
      <li><a href="mailto:arctos.built@gmail.com">Contact</a></li>
    </ul>
    <p class="footer__copyright">&copy; 2026 Arctos Labs. AutoMate is built and maintained by a solo developer.</p>
  </div>
</footer>

</body>
</html>
```

- [ ] **Step 3: Run the test — verify it passes**

Run the Step 1 command again. Expected: `PASS: /press-kit/ contains all 5 required strings`.

- [ ] **Step 4: Commit**

```bash
git add press-kit/
git commit -m "feat: build /press-kit with real logo and screenshot assets"
```

---

## Task 8: Cross-site QA pass

**Files:** none created; verifies Tasks 1–7 together.

- [ ] **Step 1: Run every page's test in sequence**

```bash
tests/check-page.sh / "<title>AutoMate"
tests/check-page.sh /vs-drivvo/ "<title>AutoMate vs. Drivvo"
tests/check-page.sh /vs-fuelio/ "<title>AutoMate vs. Fuelio"
tests/check-page.sh /privacy-policy/ "<title>Privacy Policy"
tests/check-page.sh /press-kit/ "<title>Press Kit"
tests/check-page.sh /privacy.html "url=/arctoslabs/privacy-policy/"
```
Expected: 6x `PASS`.

- [ ] **Step 2: Internal link check — every nav/footer link resolves**

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory . & SERVER=$!
sleep 0.5
for p in / /vs-drivvo/ /vs-fuelio/ /privacy-policy/ /press-kit/ /privacy.html /tokens.css /styles.css /assets/logo/automate-mark-dark.png /assets/logo/automate-mark-light.png /assets/screenshots/dashboard.png /assets/screenshots/efficiency-spending.png /assets/screenshots/history.png /assets/screenshots/reminders.png; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8000$p")
  echo "$code $p"
done
kill $SERVER
```
Expected: every line is `200 <path>`. Any non-200 is a broken link/asset — fix before continuing.

- [ ] **Step 3: Every page has exactly one `<h1>`**

```bash
for f in index.html vs-drivvo/index.html vs-fuelio/index.html privacy-policy/index.html press-kit/index.html; do
  count=$(grep -o "<h1" "$f" | wc -l)
  echo "$f: $count <h1>"
done
```
Expected: every file reports `1`. Fix any file reporting 0 or 2+.

- [ ] **Step 4: Meta title + description present on every page**

```bash
for f in index.html vs-drivvo/index.html vs-fuelio/index.html privacy-policy/index.html press-kit/index.html; do
  grep -q "<title>" "$f" && grep -q 'name="description"' "$f" && echo "$f: OK" || echo "$f: MISSING TITLE OR DESCRIPTION"
done
```
Expected: every file reports `OK`.

- [ ] **Step 5: Slop-test subset — no banned patterns snuck in**

```bash
grep -riE "gradient" *.html */index.html styles.css || echo "no gradient references — OK"
grep -riE "lorem ipsum|jane doe|john smith" *.html */index.html || echo "no placeholder copy — OK"
```
Expected: both checks print the "OK" line (i.e. no matches found).

- [ ] **Step 6: Manual responsive check on all 5 pages at 320 / 375 / 414 / 768px** — repeat Task 2 Step 4's check for `/vs-drivvo/`, `/vs-fuelio/`, `/privacy-policy/`, `/press-kit/`. Pay particular attention to the comparison tables: `.compare-table-wrap` must scroll horizontally inside itself at 320px, not force the page to scroll.

- [ ] **Step 7: Commit any fixes found during QA**

```bash
git add -A
git commit -m "fix: cross-site QA pass — links, headings, meta tags, responsive"
```

(Skip this commit if QA found nothing to fix.)

---

## Task 9: Local review handoff — STOP before pushing

**Files:** none.

- [ ] **Step 1: Summarize the diff for the user**

```bash
git log --oneline master..redesign-automate-site
git diff --stat master..redesign-automate-site
```

- [ ] **Step 2: Tell the user where the branch lives** (`/mnt/data/projects/arctoslabs-site`, branch `redesign-automate-site`) and that it has not been pushed.

- [ ] **Step 3: Ask explicitly** whether to (a) push the branch and open a PR against `master` for review, or (b) push directly to `master` since this is a solo-maintained repo with no CI/review process, or (c) hold — user will review the local files first. **Do not push or open a PR without an explicit answer to this question.**

- [ ] **Step 4 (only after explicit go-ahead):** push and, if a PR was requested:

```bash
git push -u origin redesign-automate-site
gh pr create --title "Redesign: AutoMate marketing site" --body "$(cat <<'EOF'
## Summary
- Replaces the generic Arctos Labs portfolio-card page with a dedicated 5-page AutoMate site
- Custom Hallmark theme: graphite + amber, JetBrains Mono / IBM Plex Sans, Stat-Led hero
- New pages: /vs-drivvo, /vs-fuelio (Fuelio facts sourced via WebSearch, cited), /privacy-policy (discloses Crashlytics), /press-kit (real logo + screenshots)
- Legacy /privacy.html now redirects to /privacy-policy/ to avoid breaking any existing Play Console link

## Test plan
- [ ] Merge and confirm Pages rebuilds at https://banderberg.github.io/arctoslabs/
- [ ] Click through all nav/footer links on the live site
- [ ] Confirm /privacy.html redirects correctly
- [ ] Spot-check on an actual phone at normal width
EOF
)"
```

If (b) direct-to-master was chosen instead, run `git checkout master && git merge redesign-automate-site && git push origin master` — still only after the explicit go-ahead from Step 3.

---

## Self-Review

**Spec coverage:**
- Hero + data-ownership pitch + Play badge above fold ✓ (Task 2)
- No-ads/no-account/no-cloud subhead ✓ (Task 2)
- 4 feature sections (fuel efficiency, all-in-one/multi-vehicle, reminders, export/import) ✓ (Task 2)
- Why ad-free/local matters section ✓ (Task 2)
- 7-language callout ✓ (Task 2)
- Footer with Privacy/Press/Contact + repeated Play badge ✓ (Task 2)
- `/vs-drivvo` comparison table + switching section + solo-dev section + CTAs top/bottom ✓ (Task 3)
- `/vs-fuelio` same structure, sourced facts, no fabrication ✓ (Tasks 4–5)
- `/privacy-policy` reflecting no-account/local/Crashlytics disclosure ✓ (Task 6)
- `/press-kit` with real logo + 4 real screenshots + descriptions + contact ✓ (Task 7)
- Mobile-responsive ✓ (checked every task + Task 8 Step 6)
- Per-page `<title>` + meta description ✓ (checked in Task 8 Step 4)
- Plain Play Store link, no invented UTM params ✓ (Global Constraints + every page)
- Flag assumptions instead of guessing silently ✓ (Task 4/5 unconfirmed-field handling, Task 6 Play-Console-URL flag)

**Placeholder scan:** no "TBD"/"add error handling"/"similar to Task N" phrasing anywhere above — every step has literal file content or literal commands. The one deliberately-unresolved item ("Unconfirmed — check Fuelio's current listing") is a spec-required behavior, not a plan placeholder.

**Type/interface consistency:** `.compare-table` markup shape (thead with 3 `<th>`, tbody rows of `<th scope="row">` + 2 `<td>`) is identical between Task 3 and Task 5. Nav/footer markup identical across Tasks 2–3, 5–7 except the `aria-current` link and relative asset paths (`../` prefix for pages one directory deep). Token names (`--color-*`, `--font-*`, `--text-*`, `--space-*`) used consistently from Task 1 through Task 7 with no renames.

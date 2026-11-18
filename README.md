# May's Games 🐰

Three little games in one page: **Paint Sudoku** (daily colour sudoku that reveals a painting), **Colouring Book**, and **Picture Logic** (nonograms).

Everything lives in `public/index.html` — no build step.

## Deploy on Cloudflare
- **Workers (Import a repository):** no settings needed — `wrangler.jsonc` serves `./public`.
- **Pages (Connect to Git):** Framework preset `None`, build command empty, build output directory `public`.

## Edit the personal notes
Open `public/index.html` and change `FOR_NAME`, `FROM_NAME` and the `NOTES` lists near the top of the script.

## May's Hair Studio (`/salon/`)
Salon game at `public/salon/index.html`, opened inside the main dashboard (no separate page for May).

## Seun's private dashboard (`/stats`)
`maysgame.pages.dev/stats` shows progress for every game, plus "does she need an update?" alerts.
Setup: Supabase → SQL Editor → paste `supabase/setup.sql`, set your passcode on the PASSCODE line, Run. Safe to re-run.
Connection details are in `public/config.js`.

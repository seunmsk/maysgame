# May's Games 🐰

Three little games in one page: **Paint Sudoku** (daily colour sudoku that reveals a painting), **Colouring Book**, and **Picture Logic** (nonograms).

Everything lives in `public/index.html` — no build step.

## Deploy on Cloudflare
- **Workers (Import a repository):** no settings needed — `wrangler.jsonc` serves `./public`.
- **Pages (Connect to Git):** Framework preset `None`, build command empty, build output directory `public`.

## Edit the personal notes
Open `public/index.html` and change `FOR_NAME`, `FROM_NAME` and the `NOTES` lists near the top of the script.

## May's Hair Studio (`/salon/`)
Salon game at `public/salon/index.html`. Seun's private progress dashboard: `/salon/stats.html` (uses the Owambe stats passcode).
Progress goes to Supabase: run `supabase/salon.sql` once in the SQL Editor. Connection details are in `public/config.js`.

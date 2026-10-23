# small-places.org

The website for the Small-Places Conference, hosted free on GitHub Pages.

## How it works

- `index.html` is the whole site. Speaker photos and the link-preview image are in `img/`.
- Every push to `main` republishes the site (`.github/workflows/deploy.yml`).
- `scripts/update-substack.ps1` runs once a day on Drew's PC. It reads
  https://smallplaces.substack.com/feed, saves the newest articles to
  `data/substack.json`, and pushes if anything changed. The Articles section on
  the site reads that file, so new Substack posts show up within a day.
  It runs on the PC because Substack refuses requests from GitHub's servers.
- Log: `%LOCALAPPDATA%\SmallPlaces\update-substack.log`

The Articles section starts with six planned articles marked "Coming soon."
When a post with a matching title appears on Substack, it replaces that card
and keeps the speaker's name as the byline. Other posts use the Substack
byline. To change the planned list, edit the `article soon` cards in `index.html`.

## One-time setup

1. **GitHub.** Create a repository named `small-places.org`, push this folder,
   then in **Settings → Pages** set **Source** to **GitHub Actions** and
   **Custom domain** to `small-places.org`. Tick **Enforce HTTPS** once it's offered.
2. **GoDaddy DNS** for small-places.org (My Products → small-places.org → DNS):
   - Delete any existing `A` record for `@` and any "Parked" or forwarding records.
   - Add four `A` records, Name `@`, pointing to:
     `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - Add a `CNAME` record, Name `www`, Value `buelldrew-afk.github.io`
   DNS can take up to a few hours to take effect.
3. **Daily article update.** Create a Windows scheduled task named
   "Small-Places - Update Substack" that runs daily at 7:00 am:
   `powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "<this folder>\scripts\update-substack.ps1"`

## Each year

Update the date, schedule, speakers, and registration link in `index.html`,
add new photos to `img/`, and push.

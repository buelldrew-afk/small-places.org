# Refreshes data/substack.json with the latest articles from the conference
# Substack and, if anything changed, commits and pushes it so GitHub redeploys
# small-places.org.
#
# Runs daily from the Windows scheduled task "Small-Places - Update Substack".
# It runs on this PC because Substack refuses requests from GitHub's servers.
# Log: %LOCALAPPDATA%\SmallPlaces\update-substack.log

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$out = Join-Path $repo 'data\substack.json'
$git = 'C:\Program Files\Git\cmd\git.exe'
$logDir = Join-Path $env:LOCALAPPDATA 'SmallPlaces'
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir 'update-substack.log'
function Log($msg) { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm}  {1}" -f (Get-Date), $msg) }

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object Net.WebClient
    $wc.Encoding = [Text.Encoding]::UTF8
    $wc.Headers.Add('User-Agent', 'small-places.org feed updater')
    [xml]$feed = $wc.DownloadString('https://smallplaces.substack.com/feed')

    # Skip Substack's automatic "Coming soon" placeholder post.
    $items = $feed.rss.channel.item | Where-Object { $_ -and "$($_.link)" -notmatch '/p/coming-soon$' }
    $posts = @($items | Select-Object -First 12 | ForEach-Object {
        $img = ($_.enclosure | Where-Object { $_.type -like 'image/*' } | Select-Object -First 1).url
        [ordered]@{
            title    = "$($_.title.InnerText)".Trim()
            subtitle = "$($_.description.InnerText)".Trim()
            author   = "$($_.creator.InnerText)".Trim()
            link     = "$($_.link)".Trim()
            date     = ([DateTimeOffset]::Parse($_.pubDate)).ToString('o')
            image    = $img
        }
    })

    $json = ConvertTo-Json @{ posts = $posts } -Depth 4
    if ($posts.Count -eq 0) { $json = '{ "posts": [] }' }
    [IO.File]::WriteAllText($out, $json, (New-Object Text.UTF8Encoding $false))

    $changed = & $git -C $repo status --porcelain -- data/substack.json
    if (-not $changed) { Log "No new articles ($($posts.Count) in feed)."; exit 0 }

    & $git -C $repo add -- data/substack.json
    & $git -C $repo commit -q -m "Update Small-Places Journal articles" -- data/substack.json
    & $git -C $repo push -q 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git push failed (exit $LASTEXITCODE)" }
    Log "Pushed articles; newest: $(if ($posts.Count) { $posts[0].title } else { 'none' })"
}
catch {
    Log "ERROR: $($_.Exception.Message)"
    exit 1
}

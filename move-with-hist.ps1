# NOTE: for internal use only
# This script moves a source file to a target file in repository,
# but ensures its history is preserved, i.e. commits, author date.

param (
    [Parameter(Mandatory=$true)][string]$source,
    [Parameter(Mandatory=$true)][string]$target
)

Write-Host("Source is {0}" -f $source) -ForegroundColor Green
Write-Host("Target is {0}" -f $target) -ForegroundColor Green

# get current branch
$branch = & git branch --show-current | Out-String
$branch = $branch.Trim()
Write-Host("Branch is {0}" -f $branch) -ForegroundColor Green

# get commit count for file
$length = & git rev-list --count $branch $source | Out-String
$length = $length.Trim()
Write-Host("Commit count is {0}" -f $length) -ForegroundColor Green

# make patches
Write-Host("Generating patches") -ForegroundColor Yellow
$patchs = & git format-patch -$length $source | Out-String
$patchs = $patchs.Trim()
foreach ($patch in $($patchs -split "`r`n"))
{
    $patch
}

# create target directory
$tgtdir = Split-Path $target | Out-String
$tgtdir = $tgtdir.Trim()
Write-Host("Creating target directory {0}" -f $tgtdir) -ForegroundColor Yellow
New-Item $tgtdir -ItemType Directory -Force | Out-Null

# apply patches, pass good syntax, add historical data, commit, cleanup
Write-Host("Applying patches") -ForegroundColor Yellow
$gitdir = $tgtdir.Substring(2).Replace("\","/")
$gitdir = $gitdir.Trim()
$dirlen = $gitdir.Split("/").Count
foreach ($patch in $($patchs -split "`r`n"))
{
    Write-Host("`Applying $patch".PadRight(80)) -BackgroundColor Magenta -ForegroundColor White
 
    $hash = (Get-Content $patch)[0].Substring(5, 40)
    $mail = (Get-Content $patch)[1].Substring(6)
    $date = (Get-Content $patch)[2].Substring(6)
    $text = (Get-Content $patch)[3].Substring(9)
    $data = "NOTE: auto-magically re-imported by HAL 9000`r`nHASH: {0} (original)" -f $hash
    $text = "[MIGRATED] {0}" -f $text

    Write-Host("Executing git apply") -BackgroundColor Green -ForegroundColor White
    & git apply --whitespace=nowarn --directory=$gitdir -p $dirlen "$patch"
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host("ERROR : `$LASTEXITCODE = $LASTEXITCODE") -BackgroundColor Red -ForegroundColor White
        exit
    }
            
    Write-Host("Executing git add") -BackgroundColor Green -ForegroundColor White
    git add -f "$target"
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host("ERROR : `$LASTEXITCODE = $LASTEXITCODE") -BackgroundColor Red -ForegroundColor White
        exit
    }

    Write-Host("Executing git commit") -BackgroundColor Green -ForegroundColor White
    Write-Host("    `$text = $text") -BackgroundColor Cyan -ForegroundColor White
    # Write-Host("    `$data = $data") -BackgroundColor Cyan -ForegroundColor White
    # Write-Host("    `$date = $date") -BackgroundColor Cyan -ForegroundColor White
    # Write-Host("    `$mail = $mail") -BackgroundColor Cyan -ForegroundColor White
    git commit -m "$text" -m "$data" --date="$date" --author="$mail"
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host("ERROR : `$LASTEXITCODE = $LASTEXITCODE") -BackgroundColor Red -ForegroundColor White
        exit
    }

    Remove-Item $patch
}

Write-Host("Removing original file {0}" -f $source) -ForegroundColor Yellow
& git rm $source
& git commit -m $("[MIGRATED] Delete {0}" -f $source) -m "NOTE: file deleted after being migrated with original history" $source

Write-Host("Complete") -ForegroundColor Green
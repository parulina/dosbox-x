# NOTE: for internal use only
# This script moves a source directory to a target directory in repository,
# but ensures its history is preserved, i.e. commits, author date.

param (
    [Parameter(Mandatory=$true)][string]$source,
    [Parameter(Mandatory=$true)][string]$target
)


Write-Host("Source is {0}" -f $source) -ForegroundColor Green
Write-Host("Target is {0}" -f $target) -ForegroundColor Green

$files = Get-ChildItem -path $source -Recurse -Attributes !Directory | Resolve-Path -Relative

foreach($file in $files)
{
    $dest = "{0}{1}" -f $target, $file.Substring(1)

    Write-Host("Moving '{0}' to '{1}'" -f $file, $dest) -BackgroundColor Cyan -ForegroundColor White
    
    .\move-with-hist.ps1 $file $dest

    if ($LASTEXITCODE -ne 0)
    {
        Write-Host("ERROR : `$LASTEXITCODE = $LASTEXITCODE") -BackgroundColor Red -ForegroundColor White
        exit
    }
}
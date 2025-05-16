param (
    [string]$exe,
    [string]$input,
    [string]$output
)

Write-Host "Wrapper executing: $exe $input $output"

if (-Not (Test-Path $exe)) {
    Write-Error "❌ Rust executable not found at path: $exe"
    exit 1
}

Start-Sleep -Milliseconds 100

Start-Process -FilePath $exe -ArgumentList "$input $output" -Wait -NoNewWindow

Start-Sleep -Milliseconds 200

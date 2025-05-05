function Measure-MemoryUsage {
    param (
        [string]$exePath,
        [string[]]$args
    )

    Write-Host "`nRunning: $exePath $($args -join ' ')"

    $proc = if ($args.Count -gt 0) {
        Start-Process -FilePath $exePath -ArgumentList ($args -join " ") -PassThru
    } else {
        Start-Process -FilePath $exePath -PassThru
    }

    Start-Sleep -Milliseconds 100

    $maxMemory = 0

    while (-not $proc.HasExited) {
        try {
            $current = (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue).WorkingSet64 / 1MB
            if ($current -gt $maxMemory) {
                $maxMemory = $current
            }
        } catch {}
        Start-Sleep -Milliseconds 100
    }

    Write-Host "Peak Memory Usage: $([math]::Round($maxMemory, 2)) MB"
}

# === RUN COMPARISON ===

Measure-MemoryUsage "E:\Education\Saxion\Internship\Projects\csv_processor_rust\target\release\csv_processor_rust.exe" @("large_input.csv", "output_rust.csv")

Measure-MemoryUsage "E:\Education\Saxion\Internship\Projects\CsvProcessor\bin\Release\net9.0\win-x64\publish\CsvProcessor.exe" @("large_input.csv", "output_csharp.csv")

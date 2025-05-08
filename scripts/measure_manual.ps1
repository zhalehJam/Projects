# Function to measure and average peak memory usage and CPU time across multiple runs
function Measure-AverageMemoryUsage {
    param (
        [string]$exePath,           # Path to the executable
        [string[]]$args,            # Arguments to pass to the executable
        [int]$iterations = 10       # Number of times to run the executable (default: 10)
    )

    # Initialize arrays to store memory and CPU results from each run
    [double[]]$memoryUsages = @()
    [double[]]$cpuTimes = @()

    Write-Host "`nRunning: $exePath $($args -join ' ') - $iterations iterations"

    # Repeat the measurement for the specified number of iterations
    for ($i = 1; $i -le $iterations; $i++) {
        # Set up process start info
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $exePath
        $startInfo.Arguments = $args -join " "
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true

        # Start the process
        $proc = [System.Diagnostics.Process]::Start($startInfo)

        $maxMemory = 0    # Tracks peak memory usage (in MB)
        $cpuTime = 0      # Tracks total CPU time (in ms)

        # Monitor the process while it's running
        while (-not $proc.HasExited) {
            try {
                $proc.Refresh()   # Refresh stats to get latest values
                $current = $proc.WorkingSet64 / 1MB  # Convert bytes to MB
                if ($current -gt $maxMemory) {
                    $maxMemory = $current           # Update peak memory
                }
            } catch {}
            Start-Sleep -Milliseconds 5             # Wait briefly to reduce polling load
        }

        try {
            $proc.Refresh()
            # TotalProcessorTime gives CPU time across all cores
            $cpuTime = [math]::Round($proc.TotalProcessorTime.TotalMilliseconds, 2)
        } catch {}

        # Save the results from this run
        $memoryUsages += [math]::Round($maxMemory, 2)
        $cpuTimes += $cpuTime
    }

    # Compute and display averages
    $avgMemory = [math]::Round(($memoryUsages | Measure-Object -Average).Average, 2)
    $avgCpu = [math]::Round(($cpuTimes | Measure-Object -Average).Average, 2)

    Write-Host "Average Peak Memory Usage: $avgMemory MB"
    Write-Host "Average CPU Time: $avgCpu ms"
}

# === RUN COMPARISON ===

# Measure Rust CLI tool
Measure-AverageMemoryUsage "E:\Education\Saxion\Internship\Projects\csv_processor_rust\target\release\cli_tool.exe" @("large_input.csv", "output_rust.csv")

# Measure C# CLI tool
Measure-AverageMemoryUsage "E:\Education\Saxion\Internship\Projects\CsvProcessor\bin\Release\net9.0\CsvProcessor.exe" @("large_input.csv", "output_csharp.csv")

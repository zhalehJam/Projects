# Define paths
$rustProjects = "E:\Education\Saxion\Internship\Projects\RustProjects"
$rustDllProjects = "E:\Education\Saxion\Internship\Projects\RustProjects_DLL"
$rustDllFile = Join-Path $rustDllProjects "target\release\rust_csv.dll"

$csharpDllTargets = @(
    "E:\Education\Saxion\Internship\Projects\CharpProjectsUseDLLRust\CsharptCsvBatchProcessorUseRustDll\bin\Release\net9.0",
    "E:\Education\Saxion\Internship\Projects\CharpProjectsUseDLLRust\CsharptCsvParallelBatchProcessorUseRustDll\bin\Release\net9.0",
    "E:\Education\Saxion\Internship\Projects\CharpProjectsUseDLLRust\CsharptCsvStreamProcessorUseRustDll\bin\Release\net9.0"
)

$csharpProjects = "E:\Education\Saxion\Internship\Projects\CSharpProjects"

Write-Host "Building Rust project in RustProjects..."
Push-Location $rustProjects
cargo build --release
Pop-Location

Write-Host " Building Rust project in RustProjects_DLL..."
Push-Location $rustDllProjects
cargo build --release
Pop-Location

if (Test-Path $rustDllFile) {
    foreach ($targetDir in $csharpDllTargets) {
        $targetDll = Join-Path $targetDir "rust_csv.dll"
        Write-Host "Copying DLL to $targetDll"
        Copy-Item -Path $rustDllFile -Destination $targetDll -Force
    }
} else {
    Write-Host "rust_csv.dll not found at expected path: $rustDllFile"
    exit 1
}

Write-Host "Building all C# projects in CSharpProjects..."
Push-Location $csharpProjects
dotnet build -c Release
Pop-Location

Write-Host " All builds and copy operations completed."

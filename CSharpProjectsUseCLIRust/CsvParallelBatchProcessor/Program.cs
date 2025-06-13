
using System;
using System.Diagnostics;

class Program
{
    static void Main(string[] args)
    {
        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: CsvProcessor <input.csv> <output.csv>");
            Environment.Exit(1);
        }

        var inputPath = args[0];
        var outputPath = args[1];
         
        var rustExePath = @"E:\Education\Saxion\Internship\Projects\RustProjects\target\release\batch_job_parallel.exe";

        var psi = new ProcessStartInfo
        {
            FileName = rustExePath,
            Arguments = $"\"{inputPath}\" \"{outputPath}",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(psi);
        process.WaitForExit();

        string stdout = process.StandardOutput.ReadToEnd();
        string stderr = process.StandardError.ReadToEnd();

        // Console.WriteLine("Rust CLI Output:\n" + stdout);
        // Console.WriteLine("Rust CLI Errors:\n" + stderr);
        // Console.WriteLine($"Exit code: {process.ExitCode}");
    }
}

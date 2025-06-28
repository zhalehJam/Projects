
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
         
        var rustExePath = @"E:\Education\Saxion\Internship\Projects\RustProjects\target\release\parallel_batch_job_for_huge_file.exe";

        var psi = new ProcessStartInfo
        {
            FileName = rustExePath,
            Arguments = $"\"{inputPath}\" \"{outputPath}",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
        var proc = Process.GetCurrentProcess();
        proc.Refresh();
        long baseMemory = proc.PrivateMemorySize64;
        var stopwatch = Stopwatch.StartNew();
        
        using var process = Process.Start(psi);
        process.WaitForExit();

        string stdout = process.StandardOutput.ReadToEnd();
        string stderr = process.StandardError.ReadToEnd();

        stopwatch.Stop();
        proc.Refresh();
        long peakMemory = proc.PeakWorkingSet64; // <-- Use this for real peak memory
        long netMemoryUsed = peakMemory - baseMemory;

        Console.Write($"peak m: {peakMemory / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"net m: {netMemoryUsed / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"t: {stopwatch.ElapsedMilliseconds} ms");
    }
}

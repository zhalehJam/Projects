using Services;
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
internal class Program
{
    private static void Main(string[] args)
    {
        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: CsvProcessor <input.csv> <output.csv>");
            Environment.Exit(1);
        }

        var inputPath = args[0];
        var outputPath = args[1];

        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
        var proc = Process.GetCurrentProcess();
        proc.Refresh();
        long baseMemory = proc.PrivateMemorySize64;
        var stopwatch = Stopwatch.StartNew();

        var processor = new BatchJob();
        processor.Run(inputPath, outputPath);


        stopwatch.Stop();
        proc.Refresh();
        long peakMemory = proc.PeakWorkingSet64; // <-- Use this for real peak memory
        long netMemoryUsed = peakMemory - baseMemory;

        Console.Write($"peak m: {peakMemory / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"net m: {netMemoryUsed / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"t: {stopwatch.ElapsedMilliseconds} ms");
    }
}
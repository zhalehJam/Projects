using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.IO;
using System.Text;
class Program
{
    [DllImport("rust_csv.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int run_batch_job(string inputPath, string outputPath);

    static void Main(string[] args)
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

        var sw = Stopwatch.StartNew();
        int result = run_batch_job(inputPath, outputPath);
        sw.Stop();

        stopwatch.Stop();
        proc.Refresh();
        long peakMemory = proc.PeakWorkingSet64; // <-- Use this for real peak memory
        long netMemoryUsed = peakMemory - baseMemory;

        Console.Write($"peak m: {peakMemory / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"net m: {netMemoryUsed / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"t: {stopwatch.ElapsedMilliseconds} ms");
    }
}

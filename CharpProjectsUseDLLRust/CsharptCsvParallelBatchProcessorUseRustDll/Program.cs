using System;
using System.Runtime.InteropServices;
using System.Text;
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
class Program
{
    [DllImport("kernel32", SetLastError = true)]
    static extern IntPtr LoadLibrary(string dllToLoad);

    [DllImport("rust_csv.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern int run_parallel_batch_job(IntPtr inputPath, IntPtr outputPath);

    [DllImport("rust_csv.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern int run_parallel_batch_job_for_huge_file(IntPtr inputPath, IntPtr outputPath);

    static unsafe void Main(string[] args)
    {
        if (args.Length < 2)
            Environment.Exit(1);

        LoadLibrary("rust_csv.dll");

        string inputPath = args[0];
        string outputPath = args[1];

        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
        var proc = Process.GetCurrentProcess();
        proc.Refresh();
        long baseMemory = proc.PrivateMemorySize64;
        var stopwatch = Stopwatch.StartNew();

        byte[] inputBytes = Encoding.ASCII.GetBytes(inputPath + "\0");
        byte[] outputBytes = Encoding.ASCII.GetBytes(outputPath + "\0");

        fixed (byte* pInput = inputBytes, pOutput = outputBytes)
        {
            // if (inputPath.IndexOf("huge", StringComparison.OrdinalIgnoreCase) >= 0)
            run_parallel_batch_job_for_huge_file((IntPtr)pInput, (IntPtr)pOutput);
            // else
            //     run_parallel_batch_job((IntPtr)pInput, (IntPtr)pOutput);
        }

        stopwatch.Stop();
        proc.Refresh();
        long peakMemory = proc.PeakWorkingSet64; // <-- Use this for real peak memory
        long netMemoryUsed = peakMemory - baseMemory;

        Console.Write($"peak m: {peakMemory / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"net m: {netMemoryUsed / 1024.0 / 1024.0:F4} MB , ");
        Console.Write($"t: {stopwatch.ElapsedMilliseconds} ms");
    }
}

using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

class Program
{
    [DllImport("rust_csv.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int run_parallel_batch_job(string inputPath, string outputPath);

    static void Main(string[] args)
    {
          if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: CsvProcessor <input.csv> <output.csv>");
            Environment.Exit(1);
        }

        var inputPath = args[0];
        var outputPath = args[1];

        // string input = @"E:\Education\Saxion\Internship\Projects\results\large_input.csv";
        // string output = @"E:\Education\Saxion\Internship\Projects\results\output_parallel_batch.csv";

        var sw = Stopwatch.StartNew();
        int result = run_parallel_batch_job(inputPath, outputPath);
        sw.Stop();

        // Console.WriteLine(result == 0
        //     ? $"[run_parallel_batch_job] Success in {sw.ElapsedMilliseconds} ms"
        //     : "[run_parallel_batch_job] Failed");
    }
}

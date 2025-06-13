using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

class Program
{
    [DllImport("rust_csv.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int csv_transform(string inputPath, string outputPath);

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
        // string output = @"E:\Education\Saxion\Internship\Projects\results\output_csv_transform.csv";

        var sw = Stopwatch.StartNew();
        int result = csv_transform(inputPath, outputPath);
        sw.Stop();

        // Console.WriteLine(result == 0
        //     ? $"[csv_transform] Success in {sw.ElapsedMilliseconds} ms"
        //     : "[csv_transform] Failed");
    }
}


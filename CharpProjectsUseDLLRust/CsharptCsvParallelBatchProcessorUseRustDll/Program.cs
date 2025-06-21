using System;
using System.Runtime.InteropServices;
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

        byte[] inputBytes = Encoding.ASCII.GetBytes(inputPath + "\0");
        byte[] outputBytes = Encoding.ASCII.GetBytes(outputPath + "\0");

        fixed (byte* pInput = inputBytes, pOutput = outputBytes)
        {
            if (inputPath.IndexOf("huge", StringComparison.OrdinalIgnoreCase) >= 0)
                run_parallel_batch_job_for_huge_file((IntPtr)pInput, (IntPtr)pOutput);
            else
                run_parallel_batch_job((IntPtr)pInput, (IntPtr)pOutput);
        }
    }
}

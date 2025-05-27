using System;
using System.Threading;

class Program
{
    static int sharedCounter = 0;
    static object lockObj = new object();
    static void Main()
    {
        Thread[] threads = new Thread[1000];

        for (int i = 0; i < threads.Length; i++)
        {
            threads[i] = new Thread(() =>
            {
                for (int j = 0; j < 10; j++)
                {
                    // Force context switches between reads and writes
                    int temp = sharedCounter;
                    Thread.Sleep(50); // 🔁 Yield control to another thread
                    // lock (lockObj)
                    // {
                        sharedCounter++; // Always correct
                    // }
                    // Console.WriteLine($"Final counter (should be 1000): {sharedCounter}");
                }
            });

            threads[i].Start();
        }

        foreach (Thread t in threads)
            t.Join();

        Console.WriteLine($"Final counter (should be 10000): {sharedCounter}");
    }
}

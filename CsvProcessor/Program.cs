﻿using Services;
using System;
using System.IO;

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

        // var service = new CsvService();
        // service.ProcessCsv(inputPath, outputPath); 
            
        var processor = new CsvProcessorManual();
        processor.Process(inputPath, outputPath);

        // var job = new BatchJob();
        // job.Run(args[0], args[1]);

        // var job = new Services.BatchJobParallel();
        // job.Run(args[0], args[1]);
    }
}

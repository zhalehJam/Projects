using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using System.Collections.Concurrent;
using System.Collections.Generic;

namespace Services
{
    public class BatchJobParallel
    {
        public void Run(string inputPath, string outputPath)
        {
            const int MaxGroups = 13;
            const int ChunkSize = 1000;
            const int MaxQueueSize = 50;

            var batchQueue = new BlockingCollection<List<string>>(MaxQueueSize);
            var localBatches = new ConcurrentBag<int[]>();

            // --- Producer Task: Streams file and batches lines lazily
            var producer = Task.Run(() =>
            {
                using var reader = new StreamReader(inputPath);
                _ = reader.ReadLine(); // Skip header

                var currentBatch = new List<string>(ChunkSize);
                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    if (line == null) continue;

                    currentBatch.Add(line);

                    if (currentBatch.Count >= ChunkSize)
                    {
                        batchQueue.Add(currentBatch);
                        currentBatch = new List<string>(ChunkSize);
                    }
                }

                if (currentBatch.Count > 0)
                    batchQueue.Add(currentBatch);

                batchQueue.CompleteAdding();
            });

            // --- Consumers: Process batches in parallel
            int consumerCount = Environment.ProcessorCount;
            var consumers = new Task[consumerCount];

            for (int i = 0; i < consumerCount; i++)
            {
                consumers[i] = Task.Run(() =>
                {
                    var localCounts = new int[MaxGroups];

                    foreach (var batch in batchQueue.GetConsumingEnumerable())
                    {
                        foreach (var line in batch)
                        {
                            var span = line.AsSpan();
                            int lastComma = span.LastIndexOf(',');
                            if (lastComma < 0) continue;

                            var ageSpan = span[(lastComma + 1)..];
                            if (!int.TryParse(ageSpan, out int age)) continue;

                            int groupIdx = age / 10;
                            if (groupIdx >= 0 && groupIdx < MaxGroups)
                                localCounts[groupIdx]++;
                        }
                    }

                    localBatches.Add(localCounts);
                });
            }

            Task.WaitAll(consumers);
            producer.Wait();

            // --- Reduce local counts into global count
            var globalCounts = new int[MaxGroups];
            foreach (var local in localBatches)
            {
                for (int i = 0; i < MaxGroups; i++)
                    globalCounts[i] += local[i];
            }

            // --- Output result
            using var writer = new StreamWriter(outputPath, false, Encoding.UTF8, 65536);
            writer.WriteLine("age_group,count");
            for (int i = 0; i < MaxGroups; i++)
            {
                writer.WriteLine($"{i * 10}-{i * 10 + 9},{globalCounts[i]}");
            }
        }
    }
}

using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using System.Threading;
using System.Linq;
using System.Collections.Concurrent;

namespace Services
{
    public class BatchJobParallel
    {
        public void Run(string inputPath, string outputPath)
        {
            const int MaxGroups = 13; // 0-9, 10-19, ..., 120-129
            int chunkSize = 2000;

            // Stream lines and skip header
            IEnumerable<string> dataLines = File.ReadLines(inputPath).Skip(1);

            // Chunker: yields lists of lines of size chunkSize
            static IEnumerable<List<string>> Chunker(IEnumerable<string> lines, int size)
            {
                List<string> chunk = new(size);
                foreach (var line in lines)
                {
                    chunk.Add(line);
                    if (chunk.Count == size)
                    {
                        yield return chunk;
                        chunk = new(size);
                    }
                }
                if (chunk.Count > 0)
                    yield return chunk;
            }

            // Use Partitioner for parallel chunk processing
            var partitioner = Partitioner.Create(Chunker(dataLines, chunkSize));

            int[] globalCounts = new int[MaxGroups];

            Parallel.ForEach(partitioner, () => new int[MaxGroups], (chunk, _, localCounts) =>
            {
                foreach (var line in chunk)
                {
                    var span = line.AsSpan();
                    int lastComma = span.LastIndexOf(',');
                    if (lastComma < 0) continue;
                    var ageSpan = span.Slice(lastComma + 1);
                    if (!int.TryParse(ageSpan, out int age)) continue;
                    int groupIdx = age / 10;
                    if (groupIdx >= 0 && groupIdx < MaxGroups)
                        localCounts[groupIdx]++;
                }
                return localCounts;
            },
            localCounts =>
            {
                // Aggregate local counts into globalCounts (single-threaded, safe)
                lock (globalCounts)
                {
                    for (int i = 0; i < MaxGroups; i++)
                        globalCounts[i] += localCounts[i];
                }
            });

            using var writer = new StreamWriter(outputPath, false, System.Text.Encoding.UTF8, 65536);
            writer.WriteLine("age_group,count");
            for (int i = 0; i < MaxGroups; i++)
            {
                int start = i * 10;
                int end = start + 9;
                writer.WriteLine($"{start}-{end},{globalCounts[i]}");
            }
        }
    }
}

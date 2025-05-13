using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace Services
{
    public class BatchJobParallel
    {
        public void Run(string inputPath, string outputPath)
        {
            var lines = File.ReadLines(inputPath).Skip(1); // Stream input

            var counts = new ConcurrentDictionary<string, int>();
            var localDictionaries = new ConcurrentBag<Dictionary<string, int>>();

            Parallel.ForEach(Partitioner.Create(lines), 
                () => new Dictionary<string, int>(), // local init
                (line, _, localMap) => // per item
                {
                    var parts = line.Split(',');
                    if (parts.Length == 4 && int.TryParse(parts[3], out int age))
                    {
                        string group = GetAgeGroup(age);
                        if (!localMap.TryAdd(group, 1))
                            localMap[group]++;
                    }
                    return localMap;
                },
                localMap => localDictionaries.Add(localMap) // thread final
            );

            // Merge local dictionaries into shared concurrent map
            foreach (var localMap in localDictionaries)
            {
                foreach (var kv in localMap)
                {
                    counts.AddOrUpdate(kv.Key, kv.Value, (_, existing) => existing + kv.Value);
                }
            }

            using var writer = new StreamWriter(outputPath, false, System.Text.Encoding.UTF8, 65536);
            writer.WriteLine("age_group,count");

            foreach (var kv in counts.OrderBy(k => k.Key))
            {
                writer.WriteLine($"{kv.Key},{kv.Value}");
            }

            //Console.WriteLine("✅ Optimized parallel batch job completed.");
        }

        private string GetAgeGroup(int age)
        {
            int baseAge = (age / 10) * 10;
            return $"{baseAge}-{baseAge + 9}";
        }
    }
}

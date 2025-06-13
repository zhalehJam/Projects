using System;
using System.Collections.Generic;
using System.IO;

namespace Services
{
    public class BatchJob
    {
        public void Run(string inputPath, string outputPath)
        {
            var counts = new SortedDictionary<string, int>();

            using var reader = new StreamReader(inputPath, System.Text.Encoding.UTF8, true, 65536);
            string? line;
            bool isFirst = true;

            while ((line = reader.ReadLine()) != null)
            {
                if (isFirst) { isFirst = false; continue; }

                var parts = line.Split(',');
                if (parts.Length != 4) continue;

                if (int.TryParse(parts[3], out int age))
                {
                    string group = GetAgeGroup(age);
                    if (!counts.ContainsKey(group))
                        counts[group] = 0;

                    counts[group]++;
                }
            }

            using var writer = new StreamWriter(outputPath, false, System.Text.Encoding.UTF8, 65536);
            writer.WriteLine("age_group,count");

            foreach (var kv in counts)
            {
                writer.WriteLine($"{kv.Key},{kv.Value}");
            }
        }

        private string GetAgeGroup(int age)
        {
            int baseAge = (age / 10) * 10;
            return $"{baseAge}-{baseAge + 9}";
        }
    }
}
using System;
using System.IO;

namespace Services
{
    public class BatchJob
    {
        public void Run(string inputPath, string outputPath)
        {
            const int MaxGroups = 13; // 0-9, 10-19, ..., 120-129
            int[] counts = new int[MaxGroups];

            using var reader = new StreamReader(inputPath, System.Text.Encoding.UTF8, true, 65536);
            string? line;
            bool isFirst = true;

            while ((line = reader.ReadLine()) != null)
            {
                if (isFirst) { isFirst = false; continue; }

                var span = line.AsSpan();
                int lastComma = span.LastIndexOf(',');
                if (lastComma < 0) continue;
                var ageSpan = span.Slice(lastComma + 1);
                if (!int.TryParse(ageSpan, out int age)) continue;

                int groupIdx = age / 10;
                if (groupIdx >= 0 && groupIdx < MaxGroups)
                    counts[groupIdx]++;
            }

            using var writer = new StreamWriter(outputPath, false, System.Text.Encoding.UTF8, 65536);
            writer.WriteLine("age_group,count");
            for (int i = 0; i < MaxGroups; i++)
            {
                int start = i * 10;
                int end = start + 9;
                writer.WriteLine($"{start}-{end},{counts[i]}");
            }
        }
    }
}
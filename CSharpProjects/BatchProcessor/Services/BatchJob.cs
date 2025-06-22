using System;
using System.IO;
using System.Text;

namespace Services
{
    public class BatchJob
    {
        private const int MaxGroups = 13;
        private const int ReadBufferSize = 128 * 1024;
        private const int WriteBufferSize = 64 * 1024;

        public void Run(string inputPath, string outputPath)
        {
            Span<int> groupCounts = stackalloc int[MaxGroups];

            using var reader = new StreamReader(inputPath, Encoding.UTF8, detectEncodingFromByteOrderMarks: true, bufferSize: ReadBufferSize);

            string? line = reader.ReadLine();
            if (line is null) return; // empty file

            while ((line = reader.ReadLine()) != null)
            {
                var span = line.AsSpan();
                int lastComma = span.LastIndexOf(',');
                if (lastComma <= 0 || lastComma >= span.Length - 1)
                    continue;

                var ageSpan = span[(lastComma + 1)..];
                if (!int.TryParse(ageSpan, out int age))
                    continue;

                int groupIdx = age / 10;
                if ((uint)groupIdx < (uint)MaxGroups)
                    groupCounts[groupIdx]++;
            }

            WriteOutput(outputPath, groupCounts);
        }

        private static void WriteOutput(string outputPath, ReadOnlySpan<int> groupCounts)
        {
            using var writer = new StreamWriter(outputPath, append: false, Encoding.UTF8, bufferSize: WriteBufferSize);
            writer.WriteLine("age_group,count");

            for (int i = 0; i < groupCounts.Length; i++)
            {
                writer.Write(i * 10);
                writer.Write('-');
                writer.Write(i * 10 + 9);
                writer.Write(',');
                writer.WriteLine(groupCounts[i]);
            }
        }
    }
}

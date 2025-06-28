using System;
using System.IO;
using System.Text;

namespace Services;

public class CsvProcessorManual
{
    public void Process(string inputPath, string outputPath)
    {
        const int BufferSize = 65536;
        using var reader = new StreamReader(inputPath, Encoding.UTF8, detectEncodingFromByteOrderMarks: true, bufferSize: BufferSize);
        using var writer = new StreamWriter(outputPath, append: false, Encoding.UTF8, bufferSize: BufferSize);
        int first = 0;
        int second = 0;
        int third = 0;
        string? line = reader.ReadLine();
        if (line is null) return;

        // Remove BOM if present and write header
        if (line.StartsWith('\uFEFF'))
            line = line.TrimStart('\uFEFF');
        writer.WriteLine(line);

        while ((line = reader.ReadLine()) != null)
        {
            first = 0;
            second = 0;
            third = 0;
            ReadOnlySpan<char> span = line.AsSpan();

            // Find first 4 commas (3 splits + age field)
            first = span.IndexOf(',');
            if (first < 0) continue;

            second = span.Slice(first + 1).IndexOf(',');
            if (second < 0) continue;
            second += first + 1;

            third = span.Slice(second + 1).IndexOf(',');
            if (third < 0) continue;
            third += second + 1;

            ReadOnlySpan<char> ageSpan = span[(third + 1)..];
            if (!int.TryParse(ageSpan, out int age) || age <= 30)
                continue;

            writer.WriteLine(line);
        }

        writer.Flush();
    }
}

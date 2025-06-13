// read → act → forget
using System;
using System.IO;
using System.Text;

namespace Services;

public class CsvProcessorManual
{
    public void Process(string inputPath, string outputPath)
    {
        const int BufferSize = 65536;
        using var reader = new StreamReader(inputPath, Encoding.UTF8, true, bufferSize: BufferSize);
        using var writer = new StreamWriter(outputPath, false, Encoding.UTF8, bufferSize: BufferSize);

        string? line = reader.ReadLine();
        if (line == null) return;

        // Write header, remove BOM if present
        line = line.TrimStart('\uFEFF');
        writer.WriteLine(line);

        while ((line = reader.ReadLine()) != null)
        {
            var span = line.AsSpan();
            int firstComma = span.IndexOf(',');
            if (firstComma < 0) continue;
            int secondComma = span.Slice(firstComma + 1).IndexOf(',') + firstComma + 1;
            if (secondComma <= firstComma) continue;
            int thirdComma = span.Slice(secondComma + 1).IndexOf(',') + secondComma + 1;
            if (thirdComma <= secondComma) continue;

            var ageSpan = span.Slice(thirdComma + 1);
            if (!int.TryParse(ageSpan, out int age) || age <= 30) continue;

            writer.WriteLine(line);
        }

        writer.Flush();
    }
}

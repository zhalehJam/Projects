// read → act → forget
using System;
using System.IO;
using System.Text;

namespace Services;

public class CsvProcessorManual
{
    public void Process(string inputPath, string outputPath)
    {
        using var reader = new StreamReader(inputPath, Encoding.UTF8, true, bufferSize: 65536);
        using var writer = new StreamWriter(outputPath, false, Encoding.UTF8, bufferSize: 65536);

        string? line;
        bool isFirst = true;

        while ((line = reader.ReadLine()) != null)
        {
            if (isFirst)
            {
                if (isFirst)
                {
                    line = line.TrimStart('\uFEFF'); // Remove BOM if present
                    writer.WriteLine(line);
                    isFirst = false;
                    continue;
                }
                isFirst = false;
                continue;
            }

            var parts = line.Split(',');

            if (parts.Length < 4) continue;

            if (int.TryParse(parts[3], out int age) && age > 30)
            {
                parts[1] = parts[1].ToUpperInvariant(); // Uppercase name
                writer.WriteLine(string.Join(",", parts));
            }
        }

        writer.Flush();
    }
}

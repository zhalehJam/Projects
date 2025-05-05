using CsvHelper;
using CsvHelper.Configuration;
using Models;
using System.Globalization;

namespace Services
{
    public class CsvService
    {
        public void ProcessCsv(string inputPath, string outputPath)
        {
            // Minimized reflection and strict config
            var config = new CsvConfiguration(CultureInfo.InvariantCulture)
            {
                HasHeaderRecord = true,
                PrepareHeaderForMatch = args => args.Header.ToLowerInvariant(),
                MissingFieldFound = null,
                HeaderValidated = null,
                TrimOptions = TrimOptions.Trim, // avoids whitespace issues
                IgnoreBlankLines = true,
                BufferSize = 65536, // 64KB buffer
            };

            using var reader = new StreamReader(inputPath, System.Text.Encoding.UTF8, detectEncodingFromByteOrderMarks: true, bufferSize: 65536);

            using var csvReader = new CsvReader(reader, config);

            using var writer = new StreamWriter(outputPath, false, System.Text.Encoding.UTF8, 65536);
            using var csvWriter = new CsvWriter(writer, CultureInfo.InvariantCulture);


            csvWriter.WriteHeader<User>();
            csvWriter.NextRecord();

            foreach (var user in csvReader.GetRecords<User>())
            {
                if (user.Age > 30)
                {
                    user.Name = user.Name.ToUpperInvariant();
                    csvWriter.WriteRecord(user);
                    csvWriter.NextRecord();
                }
            }

            writer.Flush();
        }
    }
}

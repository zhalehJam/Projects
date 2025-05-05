// Models/User.cs
using CsvHelper.Configuration.Attributes;
namespace Models
{
public class User
{
    [Index(0)] public int Id { get; set; }
    [Index(1)] public string Name { get; set; } = "";
    [Index(2)] public string Email { get; set; } = "";
    [Index(3)] public int Age { get; set; }
}
}
# python compare_csv_outputs.py small_output_rust.csv small_output_csharp.csv
# compare_csv_outputs.py
import csv
import sys

def load_csv(path):
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.reader(f)
        return list(reader)[1:]  # Skip header row

def compare_csv(file1, file2):
    data1 = load_csv(file1)
    data2 = load_csv(file2)

    if len(data1) != len(data2):
        print(f"❌ Row count mismatch (excluding header): {len(data1)} vs {len(data2)}")
        return False

    for i, (row1, row2) in enumerate(zip(data1, data2), start=2):
        if row1 != row2:
            print(f"❌ Row {i} differs:\n  {file1}: {row1}\n  {file2}: {row2}")
            return False

    print("✅ CSV contents match (excluding headers).")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python compare_csv_outputs.py rust_output.csv csharp_output.csv")
        sys.exit(1)

    file1, file2 = sys.argv[1], sys.argv[2]
    compare_csv(file1, file2)

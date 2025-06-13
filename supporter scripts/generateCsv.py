import pandas as pd
import random
from faker import Faker

fake = Faker()
random.seed(42)
Faker.seed(42)

rows = 100_000  
chunk_size = 10_000

with open("large_input.csv", "w") as f:
    f.write("id,name,email,age\n")
    id_counter = 1
    for _ in range(rows // chunk_size):
        names = [fake.first_name() for _ in range(chunk_size)]
        emails = [fake.email() for _ in range(chunk_size)]
        ages = [random.randint(18, 70) for _ in range(chunk_size)]

        for i in range(chunk_size):
            f.write(f"{id_counter},{names[i]},{emails[i]},{ages[i]}\n")
            id_counter += 1

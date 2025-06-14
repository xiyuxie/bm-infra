from google.cloud import spanner
from datetime import datetime
import csv
import pytz
import sys
import os
import socket
from google.api_core.exceptions import AlreadyExists

# Initialize Spanner client
spanner_client = spanner.Client(project=os.getenv("PROJECT_ID"))
instance = spanner_client.instance(os.getenv("SPANNER_INSTANCE"))
database = instance.database(os.getenv("SPANNER_DB"))
seattle_tz = pytz.timezone("America/Los_Angeles")

# os.getenv("HOSTNAME") won't work here.
hostname = socket.gethostname()
def parse_csv(file_path, run_type, model_name):
    records = []    
    with open(file_path, 'r') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            if len(row) == 0:
                continue
            if len(row) != 3:
                raise ValueError(f"Invalid row format: {row}")  
            run_time = datetime.strptime(row[0], "%Y%m%d_%H%M%S")
            run_time = seattle_tz.localize(run_time)
            code_hash = row[1]
            throughput = float(row[2]) if row[2] else 0.0
            # 'RunTime', 'ModelName', 'RunType', 'CodeHash', 'Throughput', 'Tag', 'VM'
            records.append((run_time, model_name, run_type, code_hash, throughput, row[0], hostname))
    return records

def insert_to_spanner(records):
    inserted = 0
    for record in records:        
        try:
            # Directly insert one record at a time without batch
            with database.batch() as batch:
                batch.insert(
                    table='ModelMetrics',
                    columns=('RunTime', 'ModelName', 'RunType', 'CodeHash', 'Throughput', 'Tag', 'VM'),
                    values=[record]
                )
            inserted += 1
        except AlreadyExists:  # Catch duplicate key error
            print(f"Duplicate key error encountered for record: {record}. Skipping.")
    print(f"{inserted} of {len(records)} inserted.")


def process_one_file(file_path, run_type,model_name, start_row):    
    records = parse_csv(file_path, run_type, model_name)
    records_to_process = records[start_row:]
    insert_to_spanner(records_to_process)
    return len(records)

if __name__ == "__main__":
    # if len(sys.argv) != 3:
    #     print("Usage: python upload_spanner.py $HOME/table.txt nightly")
    #     sys.exit(1)
    if len(sys.argv) != 2:
        print("Usage: python upload_spanner.py <state_file>")
        sys.exit(1)

    config_path = sys.argv[1]    
    configs = []
    with open(config_path, 'r') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            if len(row) != 4:
                raise ValueError(f"Invalid row format in config: {row}")  
            # result path, run_type, model_name, start_index
            configs.append((row[0],row[1], row[2], int(row[3])))

    write_back = configs[:]
    for ii, config in enumerate(configs):
        try:
            rows = process_one_file(config[0], config[1], config[2], config[3])
            write_back[ii] = (config[0], config[1], config[2], rows)
        except Exception as e:
            print(f"Error processing file {config[0]}: {e}")


    with open(config_path, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerows(write_back)
    

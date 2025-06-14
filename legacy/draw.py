import sys
import pandas as pd
import matplotlib.pyplot as plt
from google.cloud import spanner
from datetime import datetime, timedelta
import pytz
import os

INSTANCE_ID=os.getenv("SPANNER_INSTANCE")
DATABASE_ID=os.getenv("SPANNER_DB")
PROJECT_ID=os.getenv("PROJECT_ID")
DRAW_ALL=os.getenv("DRAW_ALL") # if 1, draw all nodes include 0.
DAYS=int(os.getenv("LAST_DAYS", 30))

seattle_tz = pytz.timezone("America/Los_Angeles")
def query_spanner(run_type, model_names):
    # Set up Spanner client
    spanner_client = spanner.Client(project=PROJECT_ID)
    instance_id = INSTANCE_ID
    database_id = DATABASE_ID
    instance = spanner_client.instance(instance_id)
    database = instance.database(database_id)

    # Calculate the date range for the last DAYS days
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=DAYS)

    # Create the list of models for the IN clause
    models_str = ", ".join([f"'{model}'" for model in model_names])

    # Query the database
    sql = f"""
        SELECT RunTime, ModelName, Throughput, CodeHash, Tag, VM
        FROM ModelMetrics
        WHERE RunType = @run_type
        AND ModelName IN ({models_str})
        AND RunTime BETWEEN @start_date AND @end_date
        ORDER BY RunTime ASC
    """

    params = {
        "run_type": run_type,
        "start_date": start_date,
        "end_date": end_date
    }
    param_types = {
        "run_type": spanner.param_types.STRING,
        "start_date": spanner.param_types.TIMESTAMP,
        "end_date": spanner.param_types.TIMESTAMP
    }

    # Run the query
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(sql, params=params, param_types=param_types)
        return results

def convert_model_name(model_str):
    base_name = model_str.replace("-", "")
    return (
        f"{base_name}_vllm_log.txt",
        f"{base_name}_bm_log.txt"
    )

log_host="https://storage.mtls.cloud.google.com/vllm-cb-storage"

# Create the log column with HTML <a> links using ModelName
def create_log_link(row):
    if row['VM'] and row['Tag'] and row['ModelName']:
        vllm_log, bm_log = convert_model_name(row['ModelName'])
        base_url = f"{log_host}/{row['VM']}/log/{row['Tag']}"
        return (
            f'<a href="{base_url}/{vllm_log}">vllm_log</a>, '
            f'<a href="{base_url}/{bm_log}">bm_log</a>'
        )
    return ''

def plot_data(results, output_image_path):
    # Convert query results to pandas DataFrame
    df = pd.DataFrame(results, columns=["RunTime", "ModelName", "Throughput", "CodeHash", "Tag", "VM"])
    if df.empty:
        print("no data to draw")
        return

    # convert to seattle time    
    df["RunTime"] = df["RunTime"].dt.tz_convert(seattle_tz)
    df_draw = df if DRAW_ALL == 1 else df[df["Throughput"] > 0]

    # Plot data
    plt.figure(figsize=(10, 6))
    for model in df_draw['ModelName'].unique():
        model_data = df_draw[df_draw['ModelName'] == model]
        plt.plot(model_data['RunTime'], model_data['Throughput'], label=model)

    plt.xlabel('Time')
    plt.ylabel(f'request/s')
    plt.title(f'Throughput in past {DAYS} days')
    plt.legend()
    plt.xticks(rotation=45)
    plt.tight_layout()

    # Save the plot as an image
    plt.savefig(output_image_path)
    plt.close()

    # Save the data to a csv file
    df = df.sort_values(by='RunTime', ascending=False)
    df.to_csv(output_image_path +".csv", index=False)

    df['Log'] = df.apply(create_log_link, axis=1)    
    df_html = df.drop(columns=["VM", "Tag"])
    df_html.to_html(output_image_path +".html", index=False, escape=False)


def main():
    if len(sys.argv) < 4:
        print("Usage: python draw.py <run_type> <output_image_path> <model_1> <model_2> ... <model_n>")
        sys.exit(1)

    run_type = sys.argv[1]
    output_image_path = sys.argv[2]
    model_names = sys.argv[3:]

    # Query the data
    results = query_spanner(run_type, model_names)

    # Plot and save the graph
    plot_data(results, output_image_path)
    print(f"Graph saved as {output_image_path}")

if __name__ == "__main__":
    main()
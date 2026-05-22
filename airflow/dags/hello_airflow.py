from datetime import datetime

from airflow.sdk import dag
from airflow.providers.standard.operators.bash import BashOperator


@dag(
    dag_id="hello_airflow",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["example"],
)
def hello_airflow():
    BashOperator(
        task_id="say_hello",
        bash_command="echo 'Hello from Airflow'",
    )


hello_airflow()
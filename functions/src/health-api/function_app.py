from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient, LogsQueryStatus
from azure.core.exceptions import HttpResponseError
from datetime import timedelta
import azure.functions as func
import logging
import os
import json

credential = DefaultAzureCredential()
client = LogsQueryClient(credential)

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
response_headers = { "Content-Type": "application/json" }
query = """availabilityResults | take 3 | project location, success"""

@app.route(route="http_trigger")
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    key = "TARGET_LOG_ANALYTICS_RESOURCE_ID"

    if key in os.environ.keys():
        log_resource_id = os.environ[key]
    else:
        message = "The key {} is not present in os.environ".format(key)
        logging.error(message)

        return func.HttpResponse(
             json.dumps({
                 'message': message,
                 'body': []
             }),
             status_code=500,
             headers=response_headers
        )

    try:
        response = client.query_resource(
            log_resource_id,
            query,
            timespan=timedelta(minutes=15)
        )

        if response.status == LogsQueryStatus.SUCCESS:
            data = response.tables
            struct = []

            for table in data:
                for row in table.rows:
                    list.append(struct, {"location": row[0], "success": bool(row[1])})

            logging.info(struct)

            return func.HttpResponse(
                json.dumps({
                    'message': response.status,
                    'body': struct
                }),
                status_code=200,
                headers=response_headers
            )
        else:
            error = response.partial_error
            data = response.partial_data
            logging.error(error)

            return func.HttpResponse(
                json.dumps({
                    'message': response.status,
                    'body': data
                }),
                status_code=400,
                headers=response_headers
            )

    except HttpResponseError as err:
        logging.error("something fatal happened")
        logging.error(err)

        return func.HttpResponse(
             json.dumps({
                'message': err,
                'body': []
            }),
            status_code=500,
            headers=response_headers
        )

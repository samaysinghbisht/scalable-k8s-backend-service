import boto3
from flask import Flask, request, jsonify
from botocore.exceptions import ClientError
import os

# Setting up dummy AWS credentials
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_DEFAULT_REGION = os.getenv('AWS_DEFAULT_REGION')
LOCALSTACK_HOST = os.getenv('LOCALSTACK_HOST')
LOCALSTACK_URL = os.getenv('LOCALSTACK_URL')

app = Flask(__name__)

# Assuming LocalStack runs on localhost and default ports
sqs = boto3.client(
    'sqs', 
    endpoint_url=LOCALSTACK_URL, 
    region_name=AWS_DEFAULT_REGION,
    aws_access_key_id=AWS_ACCESS_KEY_ID, 
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY
)

dynamodb = boto3.client(
    'dynamodb', 
    endpoint_url=LOCALSTACK_URL, 
    region_name=AWS_DEFAULT_REGION,
    aws_access_key_id=AWS_ACCESS_KEY_ID, 
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY
)

queue_url = None

# Function to create SQS queue
def create_sqs_queue():
    global queue_url
    try:
        response = sqs.create_queue(QueueName='MyQueue')
        queue_url = response['QueueUrl']
        print("Queue created at URL:", queue_url)
        return queue_url
    except ClientError as e:
        print(e)
        return None

# Function to create DynamoDB table
def create_dynamodb_table():
    try:
        dynamodb.create_table(
            TableName='Messages',
            KeySchema=[
                {'AttributeName': 'id', 'KeyType': 'HASH'},
            ],
            AttributeDefinitions=[
                {'AttributeName': 'id', 'AttributeType': 'S'},
            ],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )
        dynamodb.get_waiter('table_exists').wait(TableName='Messages')
        print("DynamoDB table created.")
    except ClientError as e:
        if e.response['Error']['Code'] == "ResourceInUseException":
            print("DynamoDB table already exists.")
        else:
            print(e)

# Endpoint to send message to SQS and put it in the DynamoDB table
@app.route('/process_message', methods=['POST'])
def process_message():
    # Send the message to SQS
    message_body = request.json
    sqs.send_message(QueueUrl=queue_url, MessageBody=str(message_body))

    # Retrieve and process the message from SQS
    messages = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1)
    if 'Messages' in messages:
        for message in messages['Messages']:
            body = message['Body']
            message_id = message['MessageId']
            # Store the message in DynamoDB
            dynamodb.put_item(
                TableName='Messages',
                Item={'id': {'S': message_id}, 'content': {'S': body}}
            )
            # Delete the message from the queue
            sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=message['ReceiptHandle'])
            return jsonify({"status": "success", "data": body}), 200

    return jsonify({"status": "error", "message": "No message received"}), 400

if __name__ == '__main__':
    # Create resources on startup
    create_sqs_queue()
    create_dynamodb_table()
    app.run(host='0.0.0.0', port=5001)

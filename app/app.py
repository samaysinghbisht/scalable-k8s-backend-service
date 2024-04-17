from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/message', methods=['POST'])
def message_handler():
    # Simulate parsing the message received via HTTP instead of SQS for simplicity
    message_content = request.json
    print("Received message:", message_content)
    # Here, you would have logic to write to DynamoDB
    return jsonify({"status": "success", "data": message_content}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)

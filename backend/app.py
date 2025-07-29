from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS so frontend can access the backend

@app.route('/api/data')
def get_data():
    return jsonify({"message": "Hello from Flask! I m ur backend server"})

if __name__ == '__main__':
    app.run(port=5000)

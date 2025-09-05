#!/bin/bash

# Update package lists
apt-get update -y

# Install Python and pip
apt-get install -y python3 python3-pip

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

# Install PM2 globally
npm install -g pm2

#################################
# Flask Backend
#################################
mkdir -p /opt/flask-app
cat > /opt/flask-app/app.py << 'EOF'
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/api/greeting')
def greeting():
    return jsonify({"message": "Hello from Flask Backend!", "time": "server-time-here"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Install Flask
pip3 install flask

# Start Flask with PM2
pm2 start python3 --name "flask-app" -- /opt/flask-app/app.py

#################################
# Express Frontend
#################################
mkdir -p /opt/express-app
cd /opt/express-app
npm init -y
npm install express axios

# Add start script to package.json
npm set-script start "node index.js"

# Express server (serves HTML + proxies to Flask)
cat > /opt/express-app/index.js << 'EOF'
const express = require('express');
const path = require('path');
const axios = require('axios');

const app = express();
const port = 3000;

// Serve static HTML from "public"
app.use(express.static(path.join(__dirname, 'public')));

// Proxy endpoint: Express → Flask
app.get('/api/backend', async (req, res) => {
  try {
    const r = await axios.get('http://127.0.0.1:5000/api/greeting', { timeout: 3000 });
    res.json(r.data);
  } catch (err) {
    console.error('Proxy error:', err.message);
    res.status(502).json({ error: 'Failed to reach backend' });
  }
});

app.listen(port, () => {
  console.log(`Express app listening at http://localhost:${port}`);
});
EOF

# Create public folder with simple HTML page
mkdir -p /opt/express-app/public
cat > /opt/express-app/public/index.html << 'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Express + Flask Demo</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    body { font-family: system-ui, Arial, sans-serif; margin: 2rem; }
    button { padding: 0.6rem 1rem; cursor: pointer; }
    pre { background: #f6f8fa; padding: 1rem; border-radius: 6px; }
  </style>
</head>
<body>
  <h1>Express → Flask fetch demo</h1>
  <p>This page is served by <strong>Express</strong>. Click the button to fetch data from the <strong>Flask</strong> backend via the Express proxy.</p>
  <button id="btn">Get Data</button>
  <pre id="out">Click the button…</pre>

  <script>
    const out = document.getElementById('out');
    document.getElementById('btn').addEventListener('click', async () => {
      out.textContent = 'Loading…';
      try {
        const r = await fetch('/api/backend');
        const data = await r.json();
        out.textContent = JSON.stringify(data, null, 2);
      } catch (e) {
        out.textContent = 'Error: ' + e.message;
      }
    });
  </script>
</body>
</html>
EOF

# Start Express with PM2
pm2 start npm --name "express-app" -- start --prefix /opt/express-app

#################################
# PM2 Startup
#################################
pm2 startup
pm2 save

const express = require('express');
const fetch = require('node-fetch'); // Or use native fetch in recent Node versions
const path = require('path');

const app = express();
const PORT = 3000;

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
    console.log(`Frontend running at http://localhost:${PORT}`);
});

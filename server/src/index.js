const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');

dotenv.config();

const app = express();
const port = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'dayforge-api',
    phase: 0,
  });
});

app.listen(port, () => {
  console.log(`DayForge API running on port ${port}`);
});

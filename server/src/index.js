const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');

dotenv.config();

const analyticsRoutes = require('./routes/analyticsRoutes');
const authRoutes = require('./routes/authRoutes');
const goalRoutes = require('./routes/goalRoutes');
const habitRoutes = require('./routes/habitRoutes');
const taskRoutes = require('./routes/taskRoutes');

const app = express();
const port = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());
app.use('/analytics', analyticsRoutes);
app.use('/auth', authRoutes);
app.use('/goals', goalRoutes);
app.use('/habits', habitRoutes);
app.use('/tasks', taskRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'dayforge-api',
    phase: 9,
  });
});

app.use((req, res) => {
  res.status(404).json({ message: 'Route was not found.' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: 'Something went wrong.' });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`DayForge API running on port ${port}`);
  });
}

module.exports = app;

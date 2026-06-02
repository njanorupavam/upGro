const express = require('express');
const analyticsController = require('../controllers/analyticsController');
const { requireAuth } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(requireAuth);

router.get('/dashboard', analyticsController.dashboardAnalytics);

module.exports = router;

const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ')
    ? authHeader.slice('Bearer '.length)
    : null;

  if (!token) {
    return res.status(401).json({ message: 'Authentication token is required.' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { id: payload.sub };
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Authentication token is invalid.' });
  }
}

module.exports = { requireAuth };

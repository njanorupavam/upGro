const bcrypt = require('bcryptjs');
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const prisma = require('../services/prisma');

const tokenExpiry = '7d';
const googleClient = new OAuth2Client();

function sanitizeUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

function createToken(user) {
  return jwt.sign(
    {
      email: user.email,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: tokenExpiry,
      subject: user.id,
    },
  );
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function getGoogleAudiences() {
  return (process.env.GOOGLE_CLIENT_ID || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

async function verifyGoogleToken(idToken) {
  const audiences = getGoogleAudiences();
  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: audiences.length === 1 ? audiences[0] : audiences,
  });

  return ticket.getPayload();
}

async function register(req, res, next) {
  try {
    const name = req.body.name?.trim();
    const email = req.body.email?.trim().toLowerCase();
    const password = req.body.password;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({ message: 'Please enter a valid email address.' });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters.' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });

    if (existingUser) {
      return res.status(409).json({ message: 'An account with this email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: passwordHash,
      },
    });

    return res.status(201).json({
      token: createToken(user),
      user: sanitizeUser(user),
    });
  } catch (error) {
    return next(error);
  }
}

async function login(req, res, next) {
  try {
    const email = req.body.email?.trim().toLowerCase();
    const password = req.body.password;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await prisma.user.findUnique({ where: { email } });
    const passwordsMatch = user
      ? await bcrypt.compare(password, user.password)
      : false;

    if (!user || !passwordsMatch) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    return res.status(200).json({
      token: createToken(user),
      user: sanitizeUser(user),
    });
  } catch (error) {
    return next(error);
  }
}

async function profile(req, res, next) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
    });

    if (!user) {
      return res.status(404).json({ message: 'User was not found.' });
    }

    return res.status(200).json({ user: sanitizeUser(user) });
  } catch (error) {
    return next(error);
  }
}

async function googleLogin(req, res, next) {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: 'Google ID token is required.' });
    }

    if (getGoogleAudiences().length === 0) {
      return res.status(503).json({ message: 'Google Sign-In is not configured on the server.' });
    }

    const payload = await verifyGoogleToken(idToken);
    const email = payload?.email?.trim().toLowerCase();
    const name = payload?.name?.trim();

    if (!email || !payload.email_verified) {
      return res.status(401).json({ message: 'Google account verification failed.' });
    }

    const emailLower = email;

    let user = await prisma.user.findUnique({ where: { email: emailLower } });
    if (!user) {
      const dummyPassword = `oauth-google-${payload.sub}`;
      const passwordHash = await bcrypt.hash(dummyPassword, 12);
      user = await prisma.user.create({
        data: {
          name: name || emailLower.split('@')[0],
          email: emailLower,
          password: passwordHash,
        },
      });
    } else if (name && user.name !== name) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { name },
      });
    }

    return res.status(200).json({
      token: createToken(user),
      user: sanitizeUser(user),
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  login,
  profile,
  register,
  googleLogin,
};

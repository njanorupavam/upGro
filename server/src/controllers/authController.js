const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../services/prisma');

const tokenExpiry = '7d';

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
    const { email, name, googleId } = req.body;

    if (!email || !name) {
      return res.status(400).json({ message: 'Email and name are required.' });
    }

    const emailLower = email.trim().toLowerCase();

    // Check if user exists
    let user = await prisma.user.findUnique({ where: { email: emailLower } });
    if (!user) {
      // Create a dummy password hash
      const dummyPassword = 'oauth-google-' + (googleId || Math.random().toString(36).substring(7));
      const passwordHash = await bcrypt.hash(dummyPassword, 12);
      user = await prisma.user.create({
        data: {
          name: name.trim(),
          email: emailLower,
          password: passwordHash,
        },
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

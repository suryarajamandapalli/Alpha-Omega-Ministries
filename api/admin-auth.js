const crypto = require('crypto');

// Rate limiting map: ip -> { count, resetTime }
const rateLimitMap = new Map();

function isRateLimited(ip) {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);
  if (!entry || now > entry.resetTime) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + 60000 });
    return false;
  }
  if (entry.count >= 6) {
    return true;
  }
  entry.count++;
  return false;
}

// Server-side Secret Key for HMAC Token Signing
const SECRET_KEY = process.env.ADMIN_JWT_SECRET || 'yotn2026_supreme_fest_secret_alpha_omega_777';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'yotn2026admin';

function createSessionToken() {
  const expiresAt = Date.now() + (12 * 60 * 60 * 1000); // 12 hours
  const payload = `yotn_admin:${expiresAt}`;
  const signature = crypto.createHmac('sha256', SECRET_KEY).update(payload).digest('hex');
  return `${Buffer.from(payload).toString('base64')}.${signature}`;
}

function verifySessionToken(token) {
  if (!token || typeof token !== 'string') return false;
  const parts = token.split('.');
  if (parts.length !== 2) return false;

  const [b64Payload, signature] = parts;
  const payload = Buffer.from(b64Payload, 'base64').toString('utf-8');
  const expectedSig = crypto.createHmac('sha256', SECRET_KEY).update(payload).digest('hex');

  if (signature !== expectedSig) return false;

  const [role, expStr] = payload.split(':');
  if (role !== 'yotn_admin') return false;

  const expiresAt = parseInt(expStr, 10);
  if (isNaN(expiresAt) || Date.now() > expiresAt) return false;

  return true;
}

module.exports = async (req, res) => {
  // CORS & Security Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';

  if (req.method === 'POST') {
    const { action, password, token } = req.body || {};

    if (action === 'verify') {
      const isValid = verifySessionToken(token);
      return res.status(200).json({ authenticated: isValid });
    }

    if (action === 'logout') {
      return res.status(200).json({ success: true });
    }

    // Login Action
    if (isRateLimited(clientIp)) {
      return res.status(429).json({ error: 'Too many login attempts. Please wait 1 minute.' });
    }

    if (!password || typeof password !== 'string') {
      return res.status(401).json({ error: 'Invalid admin credentials.' });
    }

    // Constant-time string comparison to prevent timing attacks
    const bufferA = Buffer.from(password.trim());
    const bufferB = Buffer.from(ADMIN_PASSWORD.trim());

    if (bufferA.length === bufferB.length && crypto.timingSafeEqual(bufferA, bufferB)) {
      const sessionToken = createSessionToken();
      return res.status(200).json({
        success: true,
        token: sessionToken,
        message: 'Admin authenticated successfully.'
      });
    } else {
      return res.status(401).json({ error: 'Invalid admin credentials.' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
};

const crypto = require('crypto');

const SECRET_KEY = process.env.ADMIN_JWT_SECRET || 'yotn2026_supreme_fest_secret_alpha_omega_777';
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://yqdtvfsxffhrxfabstsk.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxZHR2ZnN4ZmZocnhmYWJzdHNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3NjY1MTgsImV4cCI6MjEwMjM0MjUxOH0.586sYXYAnD5kiy3y9sASvOSOXWkP10jQVAhtjOTFlEI';

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

  // Verify Bearer Token / Header Token
  const authHeader = req.headers['authorization'] || '';
  const token = authHeader.replace(/^Bearer\s+/i, '') || (req.body && req.body.token);

  if (!verifySessionToken(token)) {
    return res.status(401).json({ error: 'Unauthorized. Admin session invalid or expired.' });
  }

  const { action, questionNumber, status } = req.body || {};

  try {
    if (action === 'set-status') {
      const qNum = parseInt(questionNumber, 10);
      if (isNaN(qNum) || qNum < 1 || qNum > 5) {
        return res.status(400).json({ error: 'Invalid question number' });
      }

      if (status === 'LIVE') {
        // 1. Transactionally set all other questions to is_active = false
        // Update all polls
        const updateAllReq = await fetch(`${SUPABASE_URL}/rest/v1/polls?question_number=neq.${qNum}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'Prefer': 'return=minimal'
          },
          body: JSON.stringify({ is_active: false })
        });

        // 2. Set target question to is_active = true, status = 'LIVE'
        const updateTargetReq = await fetch(`${SUPABASE_URL}/rest/v1/polls?question_number=eq.${qNum}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({ is_active: true, status: 'LIVE' })
        });

        const updatedData = await updateTargetReq.json();
        return res.status(200).json({ success: true, updated: updatedData });

      } else if (status === 'CLOSED') {
        // Set question to is_active = false, status = 'CLOSED'
        const updateCloseReq = await fetch(`${SUPABASE_URL}/rest/v1/polls?question_number=eq.${qNum}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({ is_active: false, status: 'CLOSED' })
        });

        const updatedData = await updateCloseReq.json();
        return res.status(200).json({ success: true, updated: updatedData });
      }
    }

    return res.status(400).json({ error: 'Invalid action specified' });

  } catch (err) {
    console.error('Admin poll API error:', err);
    return res.status(500).json({ error: 'Database update failed' });
  }
};

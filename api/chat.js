// Vercel function: POST /api/chat  { lang: 'en'|'hi'|'kn', messages: [{ role, text }] }
// Returns { answer, sources: [{ title, url }] }. The Gemini key stays here, never in the app.
import { askGemini, parseBody } from '../server/core.js';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Use POST' });

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const input = parseBody(body);
    const out = await askGemini(input, { apiKey: process.env.GEMINI_API_KEY });
    return res.status(200).json(out);
  } catch (e) {
    const status = e.status || 500;
    console.error('chat error', status, e.message);
    return res.status(status).json({ error: status === 400 ? e.message : 'Could not answer right now' });
  }
}

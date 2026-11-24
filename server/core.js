// EasyNet server logic: cleans the question, asks Gemini (with Google Search), returns answer + sources.

export const MODEL = process.env.GEMINI_MODEL || 'gemini-3.8-flash';
const LANG_NAMES = { en: 'English', hi: 'Hindi', kn: 'Kannada' };
const MAX_MESSAGES = 12;
const MAX_CHARS = 2000;

export function systemPrompt(lang) {
  const name = LANG_NAMES[lang] || 'English';
  return [
    'You are EasyNet, a patient helper for people in India who are new to the internet.',
    `Always reply in ${name}, in simple everyday words. Keep official names (websites, buttons, form names) as they appear on the site.`,
    'For a task, give short numbered steps (at most 8). Name the official website (for example a .gov.in site) and what to click.',
    'Say which documents or details the person should keep ready, and any official fee if one applies.',
    'Safety rules, always:',
    '- Never ask for passwords, OTPs, PINs, CVV, full card, bank account or Aadhaar numbers. If the user shares one, tell them not to share it.',
    '- You cannot pay, log in or submit forms for the user. Explain how they can do it themselves.',
    '- Warn about fake websites and agents who charge extra; prefer official sites.',
    '- If you are unsure or rules may have changed, say so and point to the official site.',
    'Formatting: plain text with numbered steps. Write website addresses plainly, like www.example.gov.in. Do not use markdown links or ** around addresses.',
  ].join('\n');
}

// Hide numbers that must never leave the phone to the AI.
export function redact(text) {
  let t = String(text);
  // OTP / PIN mentions: "OTP is 123456", "pin 1234"
  t = t.replace(/\b(otp|pin|cvv|password|passcode)\b(\s*(is|:|=|-)?\s*)(\S+)/gi, (_m, w, sep) => `${w}${sep}[hidden]`);
  // Card numbers: 13–19 digits, maybe spaced or dashed, that pass the Luhn check
  t = t.replace(/\b(?:\d[ -]?){12,18}\d\b/g, (m) => {
    const d = m.replace(/\D/g, '');
    if (d.length >= 13 && d.length <= 19 && luhn(d)) return '[card number hidden]';
    return m;
  });
  // Aadhaar: 12 digits, often written 4-4-4
  t = t.replace(/\b\d{4}[ -]?\d{4}[ -]?\d{4}\b/g, '[Aadhaar number hidden]');
  // Bank account: 9–18 digits when the words account / a/c are near
  t = t.replace(/\b(account|a\/c|acct|khata|ಖಾತೆ|खाता)(\D{0,20}?)(\d{9,18})\b/gi,
    (_m, w, mid) => `${w}${mid}[account number hidden]`);
  return t;
}

function luhn(d) {
  let sum = 0;
  let dbl = false;
  for (let i = d.length - 1; i >= 0; i--) {
    let n = d.charCodeAt(i) - 48;
    if (dbl) { n *= 2; if (n > 9) n -= 9; }
    sum += n;
    dbl = !dbl;
  }
  return sum % 10 === 0;
}

// Check the request body; returns { lang, messages } or throws Error with .status
export function parseBody(body) {
  const fail = (msg) => Object.assign(new Error(msg), { status: 400 });
  if (!body || typeof body !== 'object') throw fail('JSON body required');
  const lang = LANG_NAMES[body.lang] ? body.lang : 'en';
  if (!Array.isArray(body.messages) || body.messages.length === 0) throw fail('messages required');
  const messages = body.messages.slice(-MAX_MESSAGES).map((m) => ({
    role: m && m.role === 'model' ? 'model' : 'user',
    text: redact(String((m && m.text) || '').slice(0, MAX_CHARS)),
  })).filter((m) => m.text.trim());
  if (!messages.length || messages[messages.length - 1].role !== 'user') throw fail('last message must be from the user');
  return { lang, messages };
}

export async function askGemini({ lang, messages }, { apiKey, fetchFn = fetch, model = MODEL } = {}) {
  if (!apiKey) throw Object.assign(new Error('GEMINI_API_KEY is not set'), { status: 500 });
  const useSearch = process.env.GEMINI_SEARCH !== 'off';
  try {
    return await callWithRetry({ lang, messages, apiKey, fetchFn, model, useSearch });
  } catch (e) {
    // Google Search grounding is not in the free tier for Gemini 3.x: answer without it.
    if (useSearch && e.geminiStatus === 429) {
      return await callWithRetry({ lang, messages, apiKey, fetchFn, model, useSearch: false });
    }
    throw e;
  }
}

// Google sometimes answers 503 "high demand" for a moment: wait and try once more.
async function callWithRetry(args, waitMs = 2000) {
  try {
    return await callGemini(args);
  } catch (e) {
    if (e.geminiStatus === 503 || e.geminiStatus === 500) {
      await new Promise((r) => setTimeout(r, waitMs));
      return await callGemini(args);
    }
    throw e;
  }
}

async function callGemini({ lang, messages, apiKey, fetchFn, model, useSearch }) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  const payload = {
    systemInstruction: { parts: [{ text: systemPrompt(lang) }] },
    contents: messages.map((m) => ({ role: m.role, parts: [{ text: m.text }] })),
    generationConfig: { temperature: 0.3, maxOutputTokens: 1500 },
  };
  if (useSearch) payload.tools = [{ google_search: {} }];
  const res = await fetchFn(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw Object.assign(new Error(`Gemini error ${res.status}${useSearch ? '' : ' (no search)'}: ${detail.slice(0, 200)}`), { status: 502, geminiStatus: res.status });
  }
  const data = await res.json();
  const cand = (data.candidates || [])[0] || {};
  const answer = ((cand.content && cand.content.parts) || []).map((p) => p.text || '').join('').trim();
  if (!answer) throw Object.assign(new Error('Empty answer from Gemini'), { status: 502 });
  const seen = new Set();
  const sources = [];
  for (const ch of (cand.groundingMetadata && cand.groundingMetadata.groundingChunks) || []) {
    const w = ch.web;
    if (!w || !w.uri || seen.has(w.uri)) continue;
    seen.add(w.uri);
    sources.push({ title: w.title || '', url: w.uri });
    if (sources.length >= 5) break;
  }
  return { answer, sources };
}

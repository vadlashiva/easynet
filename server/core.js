// EasyNet server logic: cleans the question, asks Gemini (with Google Search when allowed),
// supports helper modes and one photo, returns answer + sources (+ reminder).

export const MODEL = process.env.GEMINI_MODEL || 'gemini-3.8-flash';
const LANG_NAMES = { en: 'English', hi: 'Hindi', kn: 'Kannada' };
const MAX_MESSAGES = 12;
const MAX_CHARS = 2000;
const MAX_IMAGE_B64 = 4_000_000; // about 3 MB photo; Vercel allows 4.5 MB requests

export const MODES = {
  general: [],
  scam: [
    'Task: SCAM CHECKER. The user shares a message, call script, link, website or photo they are unsure about.',
    'Start with one clear verdict line: "Likely scam", "Suspicious – be careful" or "Looks safe", then give the reasons as short points (fake links, urgency, asking for OTP/money, lottery or KYC threats, spelling, unknown sender).',
    'Then say exactly what to do now: do not click or pay, block the sender, and if money was lost call 1930 at once and report at www.cybercrime.gov.in.',
    'Never open or visit the link yourself; judge only from what is shown.',
  ],
  schemes: [
    'Task: SCHEME FINDER for Indian central and Karnataka government schemes.',
    'If you do not yet know the person\'s state, age group, work (farmer, student, worker, business, homemaker, senior citizen), and whether they hold a BPL/ration card, ask for the missing details first – at most 3 short questions in one message.',
    'When you have enough, list up to 5 schemes they may qualify for. For each: name, what they get, main eligibility, documents needed, and the official website. Say eligibility must be confirmed on the official site.',
  ],
  form: [
    'Task: FORM AND LETTER HELPER. The user shares a photo or text of a form, notice, bill or government letter.',
    'First say in one or two lines what the document is and who sent it. Then explain what it means for the person, any amount or last date, and what to do next.',
    'For a form, explain each field in simple words and give a checklist of documents to attach.',
    'If the photo shows Aadhaar, card or bank account numbers, never repeat them; refer to them only as "your Aadhaar number" etc.',
    'If the photo is unclear, ask for a clearer photo.',
  ],
  reminder: [
    'Task: REMINDER HELPER. The user shares a bill, notice, ticket, exam or appointment (text or photo).',
    'Find what must be done and the due date. Reply briefly: what it is, the due date, the amount if any, and how to pay or prepare.',
    'Then, on the very last line, write exactly: REMINDER: {"title": "<short title in the user\'s language>", "date": "YYYY-MM-DD"}',
    'Use the due date (or event date). If there is no date, ask for it and do not write the REMINDER line.',
  ],
  farmer: [
    'Task: FARMER HELPER for small farmers, mainly in Karnataka.',
    'If you do not know the crop, the district and the problem, ask briefly first.',
    'Give practical, low-cost advice in simple words: crop care, pests and diseases (from description or photo), fertiliser in general terms, water, and selling.',
    'For prices point to official sources such as maratavahini.karnataka.gov.in or enam.gov.in; for weather, mausam.imd.gov.in or the Meghdoot app; for schemes, pmkisan.gov.in and raitamitra.karnataka.gov.in. Suggest the Kisan Call Centre 1800-180-1551 for expert help.',
    'For pesticides always say to follow the label and ask the local agriculture officer or Raitha Samparka Kendra.',
  ],
  photo: [
    'Task: PHOTO SEARCH. The user sends a photo and maybe a question.',
    'Say what is in the photo in simple words. Then help with what they likely want: what it is used for, how to use it, where to get it or a fair price range, or what a sign, label, medicine strip or screen says.',
    'For medicines: give the name and common use only, and tell them to follow the doctor or pharmacist; never suggest doses.',
    'If you are not sure what it is, say so and ask for a closer photo.',
  ],
};

export function systemPrompt(lang, mode = 'general') {
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
    ...(MODES[mode] || []),
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
  const mode = MODES[body.mode] ? body.mode : 'general';
  let image = null;
  if (body.image != null) {
    const mime = String(body.image.mime || '');
    const data = String(body.image.data || '');
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(mime)) throw fail('image must be jpeg, png or webp');
    if (!data || data.length > MAX_IMAGE_B64 || !/^[A-Za-z0-9+/=]+$/.test(data)) throw fail('image too large or invalid');
    image = { mime, data };
  }
  return { lang, mode, messages, image };
}

export async function askGemini({ lang, mode = 'general', messages, image = null }, { apiKey, fetchFn = fetch, model = MODEL } = {}) {
  if (!apiKey) throw Object.assign(new Error('GEMINI_API_KEY is not set'), { status: 500 });
  const useSearch = process.env.GEMINI_SEARCH !== 'off';
  try {
    return await callWithRetry({ lang, mode, messages, image, apiKey, fetchFn, model, useSearch });
  } catch (e) {
    // Google Search grounding is not in the free tier for Gemini 3.x: answer without it.
    if (useSearch && e.geminiStatus === 429) {
      return await callWithRetry({ lang, mode, messages, image, apiKey, fetchFn, model, useSearch: false });
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

async function callGemini({ lang, mode = 'general', messages, image = null, apiKey, fetchFn, model, useSearch }) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  const payload = {
    systemInstruction: { parts: [{ text: systemPrompt(lang, mode) }] },
    contents: messages.map((m, i) => {
      const parts = [{ text: m.text }];
      // The photo goes with the latest user message only.
      if (image && i === messages.length - 1) parts.unshift({ inline_data: { mime_type: image.mime, data: image.data } });
      return { role: m.role, parts };
    }),
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
  const raw = ((cand.content && cand.content.parts) || []).map((p) => p.text || '').join('').trim();
  const { answer, reminder } = extractReminder(raw);
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
  return reminder ? { answer, sources, reminder } : { answer, sources };
}

// Pull the "REMINDER: {...}" line out of a reminder-helper answer.
export function extractReminder(text) {
  const m = String(text).match(/^\s*REMINDER:\s*(\{.*\})\s*$/m);
  if (!m) return { answer: String(text).trim(), reminder: null };
  const answer = String(text).replace(m[0], '').trim();
  try {
    const r = JSON.parse(m[1]);
    const title = String(r.title || '').trim().slice(0, 120);
    const date = String(r.date || '');
    if (!title || !/^\d{4}-\d{2}-\d{2}$/.test(date) || isNaN(Date.parse(date))) return { answer, reminder: null };
    return { answer, reminder: { title, date } };
  } catch {
    return { answer, reminder: null };
  }
}

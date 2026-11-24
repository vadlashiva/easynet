import { test } from 'node:test';
import assert from 'node:assert/strict';
import { askGemini, parseBody, redact, systemPrompt } from '../server/core.js';
import handler from '../api/chat.js';

test('redact hides card, Aadhaar, account numbers and OTPs but keeps PNR and phone', () => {
  const t = redact('card 4111 1111 1111 1111, aadhaar 2345 6789 0123, account no 123456789012345, OTP is 482913, PNR 4512367890, phone 9876543210');
  assert.match(t, /\[card number hidden\]/);
  assert.match(t, /\[Aadhaar number hidden\]/);
  assert.match(t, /\[account number hidden\]/);
  assert.match(t, /OTP is \[hidden\]/);
  assert.match(t, /4512367890/);
  assert.match(t, /9876543210/);
  assert.doesNotMatch(t, /4111|482913|123456789012345/);
});

test('parseBody keeps the last 12 messages and requires the user to speak last', () => {
  const many = Array.from({ length: 20 }, (_, i) => ({ role: i % 2 ? 'model' : 'user', text: `m${i}` }));
  many.push({ role: 'user', text: 'last' });
  const out = parseBody({ lang: 'kn', messages: many });
  assert.equal(out.messages.length, 12);
  assert.equal(out.lang, 'kn');
  assert.throws(() => parseBody({ messages: [{ role: 'model', text: 'x' }] }), /last message/);
  assert.equal(parseBody({ lang: 'xx', messages: [{ role: 'user', text: 'hi' }] }).lang, 'en');
});

test('system prompt names the reply language and the safety rules', () => {
  assert.match(systemPrompt('hi'), /Hindi/);
  assert.match(systemPrompt('kn'), /Kannada/);
  assert.match(systemPrompt('en'), /Never ask for passwords, OTPs/);
});

function fakeGemini(captured) {
  return async (url, opts) => {
    captured.url = url;
    captured.body = JSON.parse(opts.body);
    captured.key = opts.headers['x-goog-api-key'];
    return {
      ok: true,
      json: async () => ({
        candidates: [{
          content: { parts: [{ text: '1. Open incometax.gov.in' }] },
          groundingMetadata: { groundingChunks: [
            { web: { uri: 'https://a.example', title: 'A' } },
            { web: { uri: 'https://a.example', title: 'A again' } },
            { web: { uri: 'https://b.example', title: 'B' } },
          ] },
        }],
      }),
    };
  };
}

test('askGemini sends search tool + key, returns answer and unique sources', async () => {
  const cap = {};
  const out = await askGemini({ lang: 'en', messages: [{ role: 'user', text: 'PAN?' }] },
    { apiKey: 'k', fetchFn: fakeGemini(cap) });
  assert.equal(out.answer, '1. Open incometax.gov.in');
  assert.deepEqual(out.sources.map((s) => s.url), ['https://a.example', 'https://b.example']);
  assert.equal(cap.key, 'k');
  assert.deepEqual(cap.body.tools, [{ google_search: {} }]);
  assert.match(cap.url, /generateContent$/);
});

test('askGemini reports a missing key and Gemini errors', async () => {
  await assert.rejects(askGemini({ lang: 'en', messages: [] }, {}), /GEMINI_API_KEY/);
  const bad = async () => ({ ok: false, status: 429, text: async () => 'quota' });
  await assert.rejects(askGemini({ lang: 'en', messages: [{ role: 'user', text: 'x' }] }, { apiKey: 'k', fetchFn: bad }), /429/);
});

function fakeRes() {
  const r = { code: 0, json_: null, headers: {} };
  r.setHeader = (k, v) => { r.headers[k] = v; };
  r.status = (c) => { r.code = c; return r; };
  r.json = (j) => { r.json_ = j; return r; };
  r.end = () => r;
  return r;
}

test('handler: rejects GET, answers CORS preflight, 400 on bad body', async () => {
  let r = fakeRes(); await handler({ method: 'GET' }, r); assert.equal(r.code, 405);
  r = fakeRes(); await handler({ method: 'OPTIONS' }, r); assert.equal(r.code, 204);
  assert.equal(r.headers['Access-Control-Allow-Origin'], '*');
  r = fakeRes(); await handler({ method: 'POST', body: { messages: [] } }, r); assert.equal(r.code, 400);
});

test('handler: hides the error detail when the key is missing', async () => {
  const saved = process.env.GEMINI_API_KEY; delete process.env.GEMINI_API_KEY;
  const r = fakeRes();
  await handler({ method: 'POST', body: { lang: 'en', messages: [{ role: 'user', text: 'hi' }] } }, r);
  assert.equal(r.code, 500);
  assert.equal(r.json_.error, 'Could not answer right now');
  if (saved) process.env.GEMINI_API_KEY = saved;
});

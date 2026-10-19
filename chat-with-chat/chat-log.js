#!/usr/bin/env node
import puppeteer from 'puppeteer-core';
import fs from 'fs';

async function main() {
  const system = process.argv[2];
  const urlPattern = process.argv[3];
  const assistantSelector = process.argv[4];
  const outputFile = process.argv[5];

  if (!system || !urlPattern || !assistantSelector || !outputFile) {
    console.error('Usage: chat-log.js <system> <url-pattern> <assistant-selector> <output-file>');
    process.exit(1);
  }

  const browser = await puppeteer.connect({
    browserURL: 'http://localhost:9222',
    defaultViewport: null,
  });

  const pages = await browser.pages();
  const page = pages.find(p => p.url().includes(urlPattern) && !p.url().includes('stripe'));

  if (!page) {
    console.error(`No ${system} tab found matching ${urlPattern}`);
    await browser.disconnect();
    process.exit(1);
  }

  const messages = await page.evaluate((assistantSel) => {
    const selectors = [
      '[class*="message"]',
      '[class*="bubble"]',
      '[data-testid*="message"]',
      '[data-testid*="chat-message"]',
      assistantSel
    ];

    const seen = new Set();
    const elements = [];

    for (const sel of selectors) {
      try {
        const found = Array.from(document.querySelectorAll(sel));
        for (const el of found) {
          if (!seen.has(el)) {
            seen.add(el);
            elements.push(el);
          }
        }
      } catch (e) {}
    }

    elements.sort((a, b) => {
      const pos = a.compareDocumentPosition(b);
      return pos & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1;
    });

    return elements.map((el, i) => {
      const text = (el.innerText || '').trim();
      if (text.length < 2) return null;

      let sender = 'unknown';
      if (el.matches(assistantSel) || el.closest(assistantSel)) {
        sender = 'assistant';
      } else {
        sender = 'user';
      }

      return { index: i + 1, sender, text };
    }).filter(Boolean);
  }, assistantSelector);

  const timestamp = new Date().toISOString();
  const lines = [
    `# ${system} conversation — ${timestamp}`,
    `# ${messages.length} messages`,
    ''
  ];

  for (const m of messages) {
    lines.push(`[${m.sender}] #${m.index}`);
    lines.push(m.text);
    lines.push('');
  }

  const output = lines.join('\n');

  fs.writeFileSync(outputFile, output);
  console.log(output);

  await browser.disconnect();
}

main().catch(e => {
  console.error(e.message);
  process.exit(1);
});

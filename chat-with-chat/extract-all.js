import puppeteer from "puppeteer-core";

async function main() {
  const browser = await puppeteer.connect({
    browserURL: "http://localhost:9222",
    defaultViewport: null,
  });
  
  const pages = await browser.pages();
  const grokPage = pages.find(p => p.url().includes('grok.com') && !p.url().includes('stripe'));
  
  if (!grokPage) {
    console.log("No Grok tab found");
    await browser.disconnect();
    return;
  }

  const result = await grokPage.evaluate(() => {
    const bubbles = document.querySelectorAll('[class*="message"]');
    const messages = [];
    bubbles.forEach((m, i) => {
      const text = (m.innerText || '').trim();
      if (text.length > 20) {
        messages.push('=== MSG ' + i + ' ===\n' + text);
      }
    });
    return messages.join('\n\n');
  });
  
  console.log(result);
  await browser.disconnect();
}

main().catch(e => { console.error(e.message); process.exit(1); });

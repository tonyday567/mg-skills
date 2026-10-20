#!/usr/bin/env node
// Upload files to a page's file input.
// Usage: chat-upload.js [--url <pattern>] <file1> [file2 ...]

import puppeteer from "puppeteer-core";

const args = process.argv.slice(2);

let urlPattern = null;
if (args[0] === "--url") {
	urlPattern = args[1];
	args.splice(0, 2);
}

const files = args;

if (files.length === 0) {
	console.log("Usage: chat-upload.js [--url <pattern>] <file1> [file2 ...]");
	process.exit(1);
}

const browser = await puppeteer.connect({
	browserURL: "http://localhost:9222",
	defaultViewport: null,
});

const pages = await browser.pages();
let page;
if (urlPattern) {
	page = pages.find((x) => x.url().toLowerCase().includes(urlPattern.toLowerCase()));
	if (!page) {
		console.error(`✗ No tab found matching '${urlPattern}'`);
		await browser.disconnect();
		process.exit(1);
	}
} else {
	page = pages[pages.length - 1];
}

const fileInput = await page.$('input[type="file"]');
if (!fileInput) {
	console.error("✗ No file input found on current page");
	await browser.disconnect();
	process.exit(1);
}

await fileInput.uploadFile(...files);
console.log(`✓ Uploaded ${files.length} file(s):`, files.join(", "));

await browser.disconnect();

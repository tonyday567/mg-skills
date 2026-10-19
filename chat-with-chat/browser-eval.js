#!/usr/bin/env node

import puppeteer from "puppeteer-core";

const args = process.argv.slice(2);
let urlPattern = null;
if (args[0] === "--url") {
	urlPattern = args[1];
	args.splice(0, 2);
}
const code = args.join(" ");
if (!code) {
	console.log("Usage: browser-eval.js [--url <pattern>] 'code'");
	console.log("\nExamples:");
	console.log('  browser-eval.js "document.title"');
	console.log('  browser-eval.js --url grok.com "document.querySelectorAll(\'a\').length"');
	process.exit(1);
}

const b = await Promise.race([
	puppeteer.connect({
		browserURL: "http://localhost:9222",
		defaultViewport: null,
	}),
	new Promise((_, reject) => setTimeout(() => reject(new Error("timeout")), 5000)),
]).catch((e) => {
	console.error("✗ Could not connect to browser:", e.message);
	console.error("  Run: browser-start.js");
	process.exit(1);
});

const pages = await b.pages();
let p;
if (urlPattern) {
	p = pages.find((x) => x.url().toLowerCase().includes(urlPattern.toLowerCase()) && !x.url().includes("stripe"));
	if (!p) {
		console.error(`✗ No tab found matching '${urlPattern}'`);
		process.exit(1);
	}
} else {
	p = pages.at(-1);
	if (!p) {
		console.error("✗ No active tab found");
		process.exit(1);
	}
}

const result = await p.evaluate((c) => {
	const AsyncFunction = (async () => {}).constructor;
	return new AsyncFunction(`return (${c})`)();
}, code);

if (Array.isArray(result)) {
	for (let i = 0; i < result.length; i++) {
		if (i > 0) console.log("");
		for (const [key, value] of Object.entries(result[i])) {
			console.log(`${key}: ${value}`);
		}
	}
} else if (typeof result === "object" && result !== null) {
	for (const [key, value] of Object.entries(result)) {
		console.log(`${key}: ${value}`);
	}
} else {
	console.log(result);
}

await b.disconnect();

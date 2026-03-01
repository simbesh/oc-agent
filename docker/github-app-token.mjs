#!/usr/bin/env node

import { createSign } from "node:crypto"

function toBase64Url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
}

function fail(message) {
  process.stderr.write(`${message}\n`)
  process.exit(1)
}

const appId = process.env.GITHUB_APP_ID
const installationId = process.env.GITHUB_APP_INSTALLATION_ID

const privateKey =
  process.env.GITHUB_APP_PRIVATE_KEY ||
  (process.env.GITHUB_APP_PRIVATE_KEY_B64
    ? Buffer.from(process.env.GITHUB_APP_PRIVATE_KEY_B64, "base64").toString("utf8")
    : "")

if (!appId) fail("Missing GITHUB_APP_ID")
if (!installationId) fail("Missing GITHUB_APP_INSTALLATION_ID")
if (!privateKey) {
  fail("Missing GITHUB_APP_PRIVATE_KEY or GITHUB_APP_PRIVATE_KEY_B64")
}

const now = Math.floor(Date.now() / 1000)
const header = { alg: "RS256", typ: "JWT" }
const payload = {
  iat: now - 60,
  exp: now + 9 * 60,
  iss: appId,
}

const unsignedToken = `${toBase64Url(JSON.stringify(header))}.${toBase64Url(JSON.stringify(payload))}`

const signer = createSign("RSA-SHA256")
signer.update(unsignedToken)
signer.end()

const signature = signer
  .sign(privateKey)
  .toString("base64")
  .replace(/=/g, "")
  .replace(/\+/g, "-")
  .replace(/\//g, "_")

const jwt = `${unsignedToken}.${signature}`

const response = await fetch(
  `https://api.github.com/app/installations/${installationId}/access_tokens`,
  {
    method: "POST",
    headers: {
      Authorization: `Bearer ${jwt}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      "User-Agent": "opencode-gh-app-token",
    },
  },
)

if (!response.ok) {
  const text = await response.text()
  fail(`Failed to mint installation token (${response.status}): ${text}`)
}

const json = await response.json()

if (!json.token) fail("GitHub API response did not include token")

process.stdout.write(json.token)

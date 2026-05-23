# Vite + NimLeptos Counter Example

This example demonstrates bundling a NimLeptos client app with **Vite**.

## Prerequisites

- [Nim](https://nim-lang.org/) >= 2.0.0
- [Node.js](https://nodejs.org/) >= 18

## Quick Start

```bash
cd examples/vite_counter

# 1. Install Vite
npm install

# 2. Compile Nim to JS
nim js -p:../../src -o:counter.js counter.nim

# 3. Start Vite dev server
npx vite
```

Open http://localhost:5173 in your browser.

## Production Build

```bash
npm run build
```

Output goes to `dist/` with source maps enabled.

## Nim JS Compiler Flags

For smaller bundles in production:

```bash
nim js -d:release --opt:size -p:../../src -o:counter.js counter.nim
```

## Source Maps

Enable Nim source maps with `-g`:

```bash
nim js -g -p:../../src -o:counter.js counter.nim
```

Vite will pick up the `.js.map` file automatically in dev mode.

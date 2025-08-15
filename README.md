# md2html — Markdown To HTML

A command-line tool for converting Markdown files to HTML.  
Watches for changes and rebuilds automatically; opens the result in your default browser (tested with Safari only).

## Requirements

- macOS 13 or later
- Swift 6
- Xcode Command Line Tools installed

## Installation

```bash
# Clone the repository
git clone https://github.com/1mash0/md2html.git

cd md2html

# Build & install (installs to /usr/local/bin by default)
make install

# Uninstall
make uninstall
```

> The provided `Makefile` installs the compiled binary as `md2h`.

## Usage

```bash
# `<input>` — Path to the input Markdown file.
md2h <input>
```

## Arguments & Options

### Positional Arguments

- `input`:  
  Path to the input Markdown file.

## Examples

Watch the Markdown file; the generated HTML opens in your default browser and auto‑updates on each change:

```bash
md2h ~/Documents/markdown.md
```

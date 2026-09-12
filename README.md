# Markdown Quick Look

[![Build](https://github.com/matrunchyk/markdown-quick-look/actions/workflows/build.yml/badge.svg)](https://github.com/matrunchyk/markdown-quick-look/actions/workflows/build.yml)

A lightweight, native Quick Look extension that renders Markdown directly in macOS Finder. Select a Markdown file, press Space, and read the formatted document instead of raw source.

No package dependencies, JavaScript libraries, analytics, or network-loaded assets.

## Features

- Headings, paragraphs, emphasis, strikethrough, and inline code
- Fenced code blocks with language metadata
- Block quotes, horizontal rules, ordered lists, unordered lists, and task lists
- GitHub-style pipe tables with column alignment
- Markdown links, automatic links for bare URLs, and email links
- Local images
- Automatic light and dark appearance
- Native universal binary for Intel and Apple-silicon Macs
- Raw HTML escaping and a restrictive content security policy

## Requirements

- macOS 13 or newer

## Install

Download the latest universal DMG from [GitHub Releases](https://github.com/matrunchyk/markdown-quick-look/releases/latest), open it, and drag **MarkdownQuickLook** to **Applications**. Launch the app once so macOS discovers the extension.

GitHub Releases are signed with a Developer ID certificate and notarized by Apple for a normal Gatekeeper installation experience.

If macOS does not enable it automatically, open **System Settings → General → Login Items & Extensions → Quick Look** and enable **Markdown Preview**.

Select a `.md`, `.markdown`, `.mdown`, `.mkd`, or `.mkdn` file in Finder and press Space.

## Build from source

This requires Xcode with the macOS SDK and command-line tools.

Build the universal app locally:

```sh
./scripts/build.sh
```

Install the resulting app and launch it once:

```sh
ditto .build/DerivedData/Build/Products/Release/MarkdownQuickLook.app \
  /Applications/MarkdownQuickLook.app
open /Applications/MarkdownQuickLook.app
```

## Development

Run the renderer smoke tests:

```sh
./scripts/test.sh
```

Or open `MarkdownQuickLook.xcodeproj` in Xcode and run the **MarkdownQuickLook** scheme on **My Mac**.

The local build script creates an ad-hoc signed universal app by default. Every push to `main` is tested, signed with Developer ID and Hardened Runtime, packaged as a versioned DMG, notarized and stapled, then published as a GitHub Release.

## Troubleshooting

After replacing an existing build, Finder may retain its previous Quick Look provider. Refresh it with:

```sh
qlmanage -r
killall QuickLookUIService 2>/dev/null || true
killall Finder
```

Confirm that the extension is registered and enabled:

```sh
pluginkit -m -A -D -v -i com.matrunchyk.MarkdownQuickLook.Preview
```

An enabled extension is prefixed with `+`.

## Security and privacy

Markdown is rendered entirely on-device. Raw HTML is escaped, scripts are disabled, and remote page resources are blocked. Clicking an external link hands it to the default browser.

The extension is sandboxed and requests read-only access to the file being previewed. Its network-client entitlement is required for WebKit's sandboxed content process; the preview page's content security policy blocks remote resource loading.

## License

[MIT](LICENSE)

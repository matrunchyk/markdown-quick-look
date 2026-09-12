import Foundation

enum MarkdownRenderer {
    static func document(_ markdown: String, title: String) -> String {
        let body = blocks(markdown.replacingOccurrences(of: "\r\n", with: "\n"))
        return """
        <!doctype html>
        <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src file: data:; style-src 'unsafe-inline'">
        <title>\(escape(title))</title>
        <style>
        :root { color-scheme: light dark; --fg:#24292f; --muted:#57606a; --border:#d0d7de; --code:#f6f8fa; --quote:#656d76; --link:#0969da; }
        @media(prefers-color-scheme:dark){:root{--fg:#e6edf3;--muted:#8b949e;--border:#30363d;--code:#161b22;--quote:#8b949e;--link:#58a6ff}}
        *{box-sizing:border-box} body{margin:0;color:var(--fg);background:transparent;font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;overflow-wrap:break-word}
        article{max-width:860px;margin:auto;padding:38px 46px 70px} h1,h2,h3,h4,h5,h6{line-height:1.25;margin:1.35em 0 .55em;font-weight:650} h1{font-size:2em;border-bottom:1px solid var(--border);padding-bottom:.3em} h2{font-size:1.5em;border-bottom:1px solid var(--border);padding-bottom:.3em} h3{font-size:1.25em}
        p{margin:0 0 1em} a{color:var(--link);text-decoration:none} a:hover{text-decoration:underline} code{font:85% ui-monospace,SFMono-Regular,Menlo,monospace;background:var(--code);padding:.18em .38em;border-radius:5px} pre{background:var(--code);padding:16px;overflow:auto;border-radius:8px;line-height:1.45} pre code{padding:0;background:none;font-size:13px}
        blockquote{margin:0 0 1em;padding:0 1em;color:var(--quote);border-left:4px solid var(--border)} ul,ol{padding-left:2em;margin:.4em 0 1em} li+li{margin-top:.25em} hr{height:1px;border:0;background:var(--border);margin:24px 0} img{max-width:100%;height:auto;border-radius:6px}
        table{border-collapse:collapse;margin:0 0 1em;display:block;overflow:auto} th,td{border:1px solid var(--border);padding:6px 13px} th{font-weight:600;background:var(--code)} .task{list-style:none}.task input{margin:0 .5em 0 -1.4em} @media(max-width:600px){article{padding:24px}}
        </style></head><body><article>\(body)</article></body></html>
        """
    }

    private static func blocks(_ source: String) -> String {
        let lines = source.components(separatedBy: "\n")
        var html: [String] = []
        var paragraph: [String] = []
        var quote: [String] = []
        var listKind: String?
        var inCode = false
        var codeLanguage = ""
        var code: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            html.append("<p>\(inline(paragraph.joined(separator: "\n")).replacingOccurrences(of: "\n", with: "<br>"))</p>")
            paragraph.removeAll()
        }
        func flushQuote() {
            guard !quote.isEmpty else { return }
            html.append("<blockquote>\(blocks(quote.joined(separator: "\n")))</blockquote>")
            quote.removeAll()
        }
        func closeList() {
            if let kind = listKind { html.append("</\(kind)>"); listKind = nil }
        }

        var lineIndex = 0
        while lineIndex < lines.count {
            let line = lines[lineIndex]
            defer { lineIndex += 1 }

            if inCode {
                if line.hasPrefix("```") || line.hasPrefix("~~~") {
                    let language = codeLanguage.isEmpty ? "" : " class=\"language-\(escapeAttribute(codeLanguage))\""
                    html.append("<pre><code\(language)>\(escape(code.joined(separator: "\n")))</code></pre>")
                    inCode = false; code.removeAll(); codeLanguage = ""
                } else { code.append(line) }
                continue
            }

            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                flushParagraph(); flushQuote(); closeList()
                inCode = true; codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushParagraph(); flushQuote(); closeList()
            } else if let heading = match(line, #"^(#{1,6})\s+(.+?)\s*#*$"#) {
                flushParagraph(); flushQuote(); closeList()
                let level = heading[1].count
                html.append("<h\(level)>\(inline(heading[2]))</h\(level)>")
            } else if line.range(of: #"^\s*((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$"#, options: .regularExpression) != nil {
                flushParagraph(); flushQuote(); closeList(); html.append("<hr>")
            } else if lineIndex + 1 < lines.count,
                      line.contains("|"),
                      isTableDivider(lines[lineIndex + 1]) {
                flushParagraph(); flushQuote(); closeList()
                let headers = tableCells(line)
                let dividers = tableCells(lines[lineIndex + 1])
                let alignments = dividers.map(tableAlignment)
                var table = "<table><thead><tr>"
                for (column, header) in headers.enumerated() {
                    let alignment = column < alignments.count ? alignments[column] : "left"
                    table += "<th style=\"text-align:\(alignment)\">\(inline(header))</th>"
                }
                table += "</tr></thead><tbody>"

                var rowIndex = lineIndex + 2
                while rowIndex < lines.count,
                      !lines[rowIndex].trimmingCharacters(in: .whitespaces).isEmpty,
                      lines[rowIndex].contains("|") {
                    table += "<tr>"
                    for (column, cell) in tableCells(lines[rowIndex]).enumerated() {
                        let alignment = column < alignments.count ? alignments[column] : "left"
                        table += "<td style=\"text-align:\(alignment)\">\(inline(cell))</td>"
                    }
                    table += "</tr>"
                    rowIndex += 1
                }
                table += "</tbody></table>"
                html.append(table)
                lineIndex = rowIndex - 1
            } else if let item = match(line, #"^\s*[-+*]\s+(.+)$"#) {
                flushParagraph(); flushQuote()
                if listKind != "ul" { closeList(); html.append("<ul>"); listKind = "ul" }
                html.append(listItem(item[1]))
            } else if let item = match(line, #"^\s*\d+[.)]\s+(.+)$"#) {
                flushParagraph(); flushQuote()
                if listKind != "ol" { closeList(); html.append("<ol>"); listKind = "ol" }
                html.append(listItem(item[1]))
            } else if let quoted = match(line, #"^\s*>\s?(.*)$"#) {
                flushParagraph(); closeList(); quote.append(quoted[1])
            } else {
                flushQuote(); closeList(); paragraph.append(line)
            }
        }
        if inCode { html.append("<pre><code>\(escape(code.joined(separator: "\n")))</code></pre>") }
        flushParagraph(); flushQuote(); closeList()
        return html.joined(separator: "\n")
    }

    private static func tableCells(_ row: String) -> [String] {
        var value = row.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("|") { value.removeFirst() }
        if value.hasSuffix("|") { value.removeLast() }

        var cells: [String] = []
        var cell = ""
        var escaped = false
        for character in value {
            if character == "|" && !escaped {
                cells.append(cell.trimmingCharacters(in: .whitespaces))
                cell = ""
            } else {
                cell.append(character)
            }
            escaped = character == "\\" && !escaped
        }
        cells.append(cell.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private static func isTableDivider(_ row: String) -> Bool {
        let cells = tableCells(row)
        return !cells.isEmpty && cells.allSatisfy {
            $0.range(of: #"^:?-{3,}:?$"#, options: .regularExpression) != nil
        }
    }

    private static func tableAlignment(_ divider: String) -> String {
        if divider.hasPrefix(":") && divider.hasSuffix(":") { return "center" }
        if divider.hasSuffix(":") { return "right" }
        return "left"
    }

    private static func listItem(_ text: String) -> String {
        if let task = match(text, #"^\[([ xX])\]\s+(.+)$"#) {
            let checked = task[1] == " " ? "" : " checked"
            return "<li class=\"task\"><input type=\"checkbox\" disabled\(checked)>\(inline(task[2]))</li>"
        }
        return "<li>\(inline(text))</li>"
    }

    private static func inline(_ source: String) -> String {
        var value = escape(source)
        value = replacing(value, #"!\[([^\]]*)\]\(([^\s)]+)(?:\s+&quot;[^&]*&quot;)?\)"#, #"<img src="$2" alt="$1">"#)
        value = replacing(value, #"\[([^\]]+)\]\(([^\s)]+)(?:\s+&quot;[^&]*&quot;)?\)"#, #"<a href="$2" target="_blank" rel="noreferrer">$1</a>"#)
        value = replacing(value, #"`([^`]+)`"#, #"<code>$1</code>"#)
        value = replacing(value, #"\*\*([^*]+)\*\*|__([^_]+)__"#, #"<strong>$1$2</strong>"#)
        value = replacing(value, #"~~([^~]+)~~"#, #"<del>$1</del>"#)
        value = replacing(value, #"(?<!\*)\*([^*\n]+)\*(?!\*)|(?<!_)_([^_\n]+)_(?!_)"#, #"<em>$1$2</em>"#)
        value = replacing(value, #"(^|[\s—>])((?:https?://)[A-Za-z0-9._~:/?#\[\]@!$&amp;'()*+,;=%-]+)"#, #"$1<a href="$2" target="_blank" rel="noreferrer">$2</a>"#)
        value = replacing(value, #"(^|[\s—>])([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})"#, #"$1<a href="mailto:$2" target="_blank">$2</a>"#)
        return value
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func escapeAttribute(_ value: String) -> String {
        escape(value).replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func match(_ value: String, _ pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let result = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              result.range.location == 0, result.range.length == value.utf16.count else { return nil }
        return (0..<result.numberOfRanges).map { index in
            let range = result.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: value) else { return "" }
            return String(value[swiftRange])
        }
    }

    private static func replacing(_ value: String, _ pattern: String, _ template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return value }
        return regex.stringByReplacingMatches(in: value, range: NSRange(value.startIndex..., in: value), withTemplate: template)
    }
}

import Foundation

@main
enum RendererSmoke {
    static func main() {
        let markdown = """
        # Preview

        **Bold**, *italic*, and `code`.

        - [x] Finished
        - Plain item

        > A quote

        | Left | Center | Right |
        |:-----|:------:|------:|
        | A | B | C |

        [OpenAI](https://openai.com/) and https://example.com/path

        Contact test@example.com

        ```swift
        print("safe")
        ```

        <script>alert("never")</script>
        """

        let html = MarkdownRenderer.document(markdown, title: "Smoke & Test")
        let expected = [
            "<h1>Preview</h1>",
            "<strong>Bold</strong>",
            "<em>italic</em>",
            "<code>code</code>",
            "type=\"checkbox\" disabled checked",
            "<blockquote>",
            "<table><thead><tr>",
            "text-align:center",
            "text-align:right",
            "href=\"https://openai.com/\"",
            "href=\"https://example.com/path\"",
            "href=\"mailto:test@example.com\"",
            "class=\"language-swift\"",
            "&lt;script&gt;alert(&quot;never&quot;)&lt;/script&gt;",
            "Smoke &amp; Test",
            "Content-Security-Policy"
        ]

        for fragment in expected where !html.contains(fragment) {
            fputs("Missing expected output: \(fragment)\n", stderr)
            exit(1)
        }
        guard !html.contains("<script>") else {
            fputs("Raw HTML was not escaped\n", stderr)
            exit(1)
        }

        print("Renderer smoke test passed")
    }
}

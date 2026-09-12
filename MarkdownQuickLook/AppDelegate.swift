import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Markdown Quick Look"
        window.center()

        let title = NSTextField(labelWithString: "Markdown Quick Look is installed")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.alignment = .center

        let body = NSTextField(wrappingLabelWithString: "Keep this app in Applications. In Finder, select a .md or .markdown file and press Space to see the formatted preview.\n\nIf macOS asks, enable the extension in System Settings → General → Login Items & Extensions → Quick Look.")
        body.font = .systemFont(ofSize: 14)
        body.alignment = .center
        body.textColor = .secondaryLabelColor
        body.maximumNumberOfLines = 0

        let stack = NSStackView(views: [title, body])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 42),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -42),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

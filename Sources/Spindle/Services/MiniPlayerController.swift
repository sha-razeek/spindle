import AppKit
import SwiftUI

@MainActor
public final class MiniPlayerController: NSObject, NSWindowDelegate {
    public static let shared = MiniPlayerController()

    private var panel: NSPanel?
    private weak var mainWindow: NSWindow?

    public var isMiniPlayerVisible: Bool {
        panel?.isVisible ?? false
    }

    public func showMiniPlayer() {
        // Find and remember the active main window before hiding it
        if let current = NSApplication.shared.windows.first(where: { $0 !== panel && $0.canBecomeMain }) {
            mainWindow = current
        }

        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 160),
                styleMask: [
                    .titled,
                    .closable,
                    .fullSizeContentView,
                    .nonactivatingPanel,
                    .utilityWindow
                ],
                backing: .buffered,
                defer: false
            )
            p.isFloatingPanel = true
            p.level = .floating
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.titlebarAppearsTransparent = true
            p.titleVisibility = .hidden
            p.isMovableByWindowBackground = true
            p.backgroundColor = .clear
            p.hasShadow = true
            p.delegate = self

            let hostingView = NSHostingView(
                rootView: MiniPlayerView(player: AudioPlayer.shared) { [weak self] in
                    self?.expandToFullPlayer()
                }
            )
            p.contentView = hostingView
            p.center()
            self.panel = p
        }

        guard let p = panel else { return }

        // Hide main window so the compact widget sits on the desktop
        mainWindow?.orderOut(nil)

        // Show floating mini player panel
        p.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func expandToFullPlayer() {
        panel?.orderOut(nil)

        // Restore main Spindle window
        if let main = mainWindow {
            main.makeKeyAndOrderFront(nil)
        } else if let first = NSApplication.shared.windows.first(where: { $0 !== panel }) {
            first.makeKeyAndOrderFront(nil)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func toggleMiniPlayer() {
        if isMiniPlayerVisible {
            expandToFullPlayer()
        } else {
            showMiniPlayer()
        }
    }

    // MARK: - NSWindowDelegate
    public func windowWillClose(_ notification: Notification) {
        if let closedWindow = notification.object as? NSWindow, closedWindow === panel {
            // Restore main window if mini player is closed with the traffic light
            if let main = mainWindow {
                main.makeKeyAndOrderFront(nil)
            }
        }
    }
}

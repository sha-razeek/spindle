import SwiftUI
import AppKit

@main
struct TunesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandMenu("Playback") {
                Button("Play / Pause") {
                    AudioPlayer.shared.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Next Track") {
                    AudioPlayer.shared.nextTrack()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])

                Button("Previous Track") {
                    AudioPlayer.shared.previousTrack()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])

                Divider()

                Button("Toggle Shuffle") {
                    AudioPlayer.shared.isShuffleEnabled.toggle()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Cycle Repeat Mode") {
                    AudioPlayer.shared.cycleRepeatMode()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Stay running in background for audio playback like Apple Music!
    }
}

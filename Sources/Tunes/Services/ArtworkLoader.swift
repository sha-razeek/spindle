import Foundation
import AppKit
import iTunesLibrary
import AVFoundation

@MainActor
public final class ArtworkLoader: ObservableObject {
    public static let shared = ArtworkLoader()

    private let cache = NSCache<NSString, NSImage>()
    private var itunesLibrary: ITLibrary?

    public init() {
        cache.countLimit = 500
    }

    public func setLibrary(_ library: ITLibrary?) {
        self.itunesLibrary = library
    }

    public func cachedImage(for song: Song) -> NSImage? {
        cache.object(forKey: song.id as NSString)
    }

    public func loadArtwork(for song: Song) async -> NSImage? {
        let key = song.id as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // Try ITLibrary directly
        if let library = itunesLibrary {
            let pidNumber = NSNumber(value: song.persistentID)
            if let itItem = library.allMediaItems.first(where: { $0.persistentID == pidNumber }) {
                if let art = itItem.artwork {
                    if let img = art.image {
                        cache.setObject(img, forKey: key)
                        return img
                    } else if let data = art.imageData, let img = NSImage(data: data) {
                        cache.setObject(img, forKey: key)
                        return img
                    }
                }
            }
        }

        // Fallback: extract embedded artwork directly from the audio file using AVAsset
        if let location = song.location {
            if let img = await extractArtworkFromFile(url: location) {
                cache.setObject(img, forKey: key)
                return img
            }
        }

        return nil
    }

    private func extractArtworkFromFile(url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        do {
            let metadata = try await asset.load(.metadata)
            let artItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork)
            for item in artItems {
                if let data = try? await item.load(.dataValue), let image = NSImage(data: data) {
                    return image
                }
            }
        } catch {
            // Silently ignore extraction errors
        }
        return nil
    }
}

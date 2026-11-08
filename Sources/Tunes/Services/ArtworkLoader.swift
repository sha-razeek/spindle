import Foundation
import AppKit
import SwiftUI
import iTunesLibrary
import AVFoundation
import ImageIO

public final class SpineColors: NSObject {
    public let bg: Color
    public let text: Color
    public init(bg: Color, text: Color) {
        self.bg = bg
        self.text = text
    }
}

@MainActor
public final class ArtworkLoader: ObservableObject {
    public static let shared = ArtworkLoader()

    private let cache = NSCache<NSString, NSImage>()
    private let colorCache = NSCache<NSString, SpineColors>()
    private var itunesLibrary: ITLibrary?
    private var itemsByPID: [UInt64: ITLibMediaItem] = [:]

    public init() {
        cache.countLimit = 1500
        colorCache.countLimit = 3000
    }

    public func setLibrary(_ library: ITLibrary?) {
        self.itunesLibrary = library
        guard let library = library else {
            self.itemsByPID = [:]
            return
        }
        var map: [UInt64: ITLibMediaItem] = [:]
        map.reserveCapacity(library.allMediaItems.count)
        for item in library.allMediaItems {
            map[item.persistentID.uint64Value] = item
        }
        self.itemsByPID = map
    }

    public func cachedImage(for song: Song) -> NSImage? {
        cache.object(forKey: song.id as NSString)
    }

    public func loadArtwork(for song: Song) async -> NSImage? {
        let key = song.id as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // Instant O(1) lookup via PID index
        if let itItem = itemsByPID[UInt64(song.persistentID)], let art = itItem.artwork {
            if let data = art.imageData, let img = createThumbnail(from: data, maxPixelSize: 600) {
                cache.setObject(img, forKey: key)
                let colors = extractSpineColor(from: img)
                colorCache.setObject(SpineColors(bg: colors.bg, text: colors.text), forKey: key)
                return img
            } else if let img = art.image {
                let thumb = downsample(image: img, maxPixelSize: 600)
                cache.setObject(thumb, forKey: key)
                let colors = extractSpineColor(from: thumb)
                colorCache.setObject(SpineColors(bg: colors.bg, text: colors.text), forKey: key)
                return thumb
            }
        }

        // Fallback: extract embedded artwork directly from the audio file using AVAsset
        if let location = song.location {
            if let img = await extractArtworkFromFile(url: location) {
                let thumb = downsample(image: img, maxPixelSize: 600)
                cache.setObject(thumb, forKey: key)
                let colors = extractSpineColor(from: thumb)
                colorCache.setObject(SpineColors(bg: colors.bg, text: colors.text), forKey: key)
                return thumb
            }
        }

        return nil
    }

    private func createThumbnail(from data: Data, maxPixelSize: CGFloat = 600) -> NSImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return NSImage(data: data)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return NSImage(data: data)
        }
        return NSImage(cgImage: cgThumb, size: NSSize(width: maxPixelSize, height: maxPixelSize))
    }

    private func downsample(image: NSImage, maxPixelSize: CGFloat = 600) -> NSImage {
        guard let tiff = image.tiffRepresentation,
              let source = CGImageSourceCreateWithData(tiff as CFData, nil) else {
            return image
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return image
        }
        return NSImage(cgImage: cgThumb, size: NSSize(width: maxPixelSize, height: maxPixelSize))
    }

    public func spineColors(for song: Song?, fallbackID: String) -> (bg: Color, text: Color) {
        guard let song = song else {
            return defaultPalette(for: fallbackID)
        }
        let key = song.id as NSString
        if let cached = colorCache.object(forKey: key) {
            return (cached.bg, cached.text)
        }
        if let image = cache.object(forKey: key) {
            let colors = extractSpineColor(from: image)
            colorCache.setObject(SpineColors(bg: colors.bg, text: colors.text), forKey: key)
            return colors
        }
        return defaultPalette(for: fallbackID)
    }

    public func extractSpineColor(from image: NSImage) -> (bg: Color, text: Color) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return (.gray, .white)
        }

        let width = 16
        let height = 16
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (.gray, .white)
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var count: CGFloat = 0

        // Sample the top rows (y: 10 to 15, where y=15 is the top edge in CGContext)
        for y in 10..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let a = CGFloat(rawData[offset + 3]) / 255.0
                if a > 0.1 {
                    totalR += CGFloat(rawData[offset]) / 255.0 / a
                    totalG += CGFloat(rawData[offset + 1]) / 255.0 / a
                    totalB += CGFloat(rawData[offset + 2]) / 255.0 / a
                    count += 1
                }
            }
        }

        guard count > 0 else { return (.gray, .white) }

        let r = totalR / count
        let g = totalG / count
        let b = totalB / count

        // Perceived luminance formula (ITU-R BT.601)
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        let isLight = lum > 0.55

        let textColor = isLight ? Color.black.opacity(0.88) : Color.white.opacity(0.95)
        return (Color(red: r, green: g, blue: b), textColor)
    }

    public func defaultPalette(for id: String) -> (bg: Color, text: Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.90, green: 0.65, blue: 0.75), .black.opacity(0.85)), // Soft Pink
            (Color(red: 0.82, green: 0.85, blue: 0.87), .black.opacity(0.85)), // Clean Grey
            (Color(red: 0.30, green: 0.58, blue: 0.42), .white.opacity(0.95)), // Jade Green
            (Color(red: 0.96, green: 0.72, blue: 0.30), .black.opacity(0.85)), // Warm Amber
            (Color(red: 0.95, green: 0.93, blue: 0.88), .black.opacity(0.85)), // Cream
            (Color(red: 0.93, green: 0.88, blue: 0.80), .black.opacity(0.85)), // Sand
            (Color(red: 0.78, green: 0.46, blue: 0.35), .white.opacity(0.95)), // Terracotta
            (Color(red: 0.62, green: 0.80, blue: 0.90), .black.opacity(0.85)), // Sky Blue
            (Color(red: 0.72, green: 0.64, blue: 0.78), .white.opacity(0.95)), // Lavender
            (Color(red: 0.88, green: 0.54, blue: 0.46), .black.opacity(0.85)), // Coral
            (Color(red: 0.55, green: 0.70, blue: 0.64), .white.opacity(0.95)), // Sage
            (Color(red: 0.85, green: 0.75, blue: 0.55), .black.opacity(0.85))  // Warm Ochre
        ]
        let hash = abs(id.hashValue)
        return palettes[hash % palettes.count]
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

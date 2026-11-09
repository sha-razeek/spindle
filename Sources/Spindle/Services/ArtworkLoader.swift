import Foundation
import AppKit
import SwiftUI
import iTunesLibrary
import AVFoundation
import ImageIO

public final class SpineColors: NSObject, @unchecked Sendable {
    public let bg: Color
    public let text: Color
    public init(bg: Color, text: Color) {
        self.bg = bg
        self.text = text
    }
}

public final class BackdropPalette: NSObject, @unchecked Sendable {
    public let primary: Color
    public let top: Color
    public let mid: Color
    public let bottom: Color
    public init(primary: Color, top: Color, mid: Color, bottom: Color) {
        self.primary = primary
        self.top = top
        self.mid = mid
        self.bottom = bottom
    }
}

public final class ArtworkLoader: @unchecked Sendable {
    public static let shared = ArtworkLoader()

    private let cache = NSCache<NSString, NSImage>()
    private let colorCache = NSCache<NSString, SpineColors>()
    private let backdropCache = NSCache<NSString, BackdropPalette>()
    private var itunesLibrary: ITLibrary?
    private var itemsByPID: [UInt64: ITLibMediaItem] = [:]
    private var inFlightTasks: [String: Task<NSImage?, Never>] = [:]
    private let lock = NSLock()

    public init() {
        cache.countLimit = 2500
        colorCache.countLimit = 5000
        backdropCache.countLimit = 5000
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    public func setLibrary(_ library: ITLibrary?) {
        withLock {
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
    }

    public func cachedImage(for song: Song) -> NSImage? {
        cache.object(forKey: song.id as NSString)
    }

    public func loadArtwork(for song: Song) async -> NSImage? {
        if Task.isCancelled { return nil }

        let key = song.id as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let pid = song.persistentID
        let itItem = withLock { itemsByPID[UInt64(pid)] }
        let location = song.location
        let songID = song.id

        // Process image extraction, thumbnail decoding and palette analysis completely in the background
        let task = withLock { () -> Task<NSImage?, Never> in
            if let existing = self.inFlightTasks[songID] {
                return existing
            }
            let newTask = Task.detached(priority: .userInitiated) { [weak self, itItem, location, songID] () -> NSImage? in
                guard let self = self else { return nil }
                if Task.isCancelled { return nil }

                var loadedImage: NSImage? = nil

                // 1. Try reading iTunes Library artwork data
                if let itItem = itItem, let art = itItem.artwork {
                    if let data = art.imageData, let img = self.createThumbnail(from: data, maxPixelSize: 1200) {
                        loadedImage = img
                    } else if let img = art.image {
                        loadedImage = self.downsample(image: img, maxPixelSize: 1200)
                    }
                }

                // 2. Fallback: extract embedded artwork directly from the audio file using AVAsset
                if loadedImage == nil, let location = location {
                    if let img = await self.extractArtworkFromFile(url: location) {
                        loadedImage = self.downsample(image: img, maxPixelSize: 1200)
                    }
                }

                guard let img = loadedImage else { return nil }
                if Task.isCancelled { return nil }

                let cacheKey = songID as NSString
                self.cache.setObject(img, forKey: cacheKey)

                // Pre-calculate colors and backdrop palette in background thread
                let colors = self.extractSpineColor(from: img)
                self.colorCache.setObject(SpineColors(bg: colors.bg, text: colors.text), forKey: cacheKey)

                let backdrop = self.extractBackdropPalette(from: img)
                self.backdropCache.setObject(backdrop, forKey: cacheKey)

                return img
            }
            self.inFlightTasks[songID] = newTask
            return newTask
        }

        let result = await task.value

        withLock {
            _ = self.inFlightTasks.removeValue(forKey: songID)
        }

        if Task.isCancelled { return nil }
        return result
    }

    private func createThumbnail(from data: Data, maxPixelSize: CGFloat = 1200) -> NSImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return NSImage(data: data)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return NSImage(data: data)
        }
        return NSImage(cgImage: cgThumb, size: NSSize(width: maxPixelSize, height: maxPixelSize))
    }

    private func downsample(image: NSImage, maxPixelSize: CGFloat = 1200) -> NSImage {
        guard let tiff = image.tiffRepresentation else { return image }
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(tiff as CFData, sourceOptions as CFDictionary) else {
            return image
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
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

    public var defaultBackdropPalette: BackdropPalette {
        BackdropPalette(
            primary: Color(red: 0.25, green: 0.35, blue: 0.45),
            top: Color(red: 0.18, green: 0.26, blue: 0.32),
            mid: Color(red: 0.13, green: 0.19, blue: 0.24),
            bottom: Color(red: 0.09, green: 0.14, blue: 0.18)
        )
    }

    public func derivePalette(from color: Color) -> BackdropPalette {
        let nsColor = NSColor(color)
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        var bri: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.usingColorSpace(.deviceRGB)?.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)

        if sat < 0.08 {
            return BackdropPalette(
                primary: Color(white: 0.38),
                top: Color(white: 0.25),
                mid: Color(white: 0.14),
                bottom: Color(white: 0.07)
            )
        }

        let richSat = min(max(sat, 0.45), 0.88)
        let primary = Color(hue: Double(hue), saturation: Double(richSat), brightness: 0.65)
        let topColor = Color(hue: Double(hue), saturation: Double(richSat * 0.85), brightness: 0.42)
        let midColor = Color(hue: Double((hue + 0.03).truncatingRemainder(dividingBy: 1.0)), saturation: Double(richSat * 0.75), brightness: 0.22)
        let bottomColor = Color(hue: Double(hue), saturation: Double(richSat * 0.60), brightness: 0.10)

        return BackdropPalette(primary: primary, top: topColor, mid: midColor, bottom: bottomColor)
    }

    public func extractBackdropPalette(from image: NSImage) -> BackdropPalette {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return defaultBackdropPalette
        }

        let width = 24
        let height = 24
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
            return defaultBackdropPalette
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totR: CGFloat = 0
        var totG: CGFloat = 0
        var totB: CGFloat = 0
        var totWeight: CGFloat = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let a = CGFloat(rawData[offset + 3]) / 255.0
                guard a > 0.15 else { continue }

                let r = (CGFloat(rawData[offset]) / 255.0) / a
                let g = (CGFloat(rawData[offset + 1]) / 255.0) / a
                let b = (CGFloat(rawData[offset + 2]) / 255.0) / a

                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let sat = maxC > 0.01 ? (maxC - minC) / maxC : 0.0
                let weight = 0.20 + sat * 0.80

                totR += r * weight
                totG += g * weight
                totB += b * weight
                totWeight += weight
            }
        }

        guard totWeight > 0 else { return defaultBackdropPalette }

        let avgR = totR / totWeight
        let avgG = totG / totWeight
        let avgB = totB / totWeight

        let nsColor = NSColor(red: avgR, green: avgG, blue: avgB, alpha: 1.0)
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        var bri: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)

        if sat < 0.08 {
            return BackdropPalette(
                primary: Color(white: 0.38),
                top: Color(white: 0.25),
                mid: Color(white: 0.14),
                bottom: Color(white: 0.07)
            )
        }

        let richSat = min(max(sat, 0.45), 0.88)
        let primary = Color(hue: Double(hue), saturation: Double(richSat), brightness: 0.65)
        let topColor = Color(hue: Double(hue), saturation: Double(richSat * 0.85), brightness: 0.42)
        let midColor = Color(hue: Double((hue + 0.03).truncatingRemainder(dividingBy: 1.0)), saturation: Double(richSat * 0.75), brightness: 0.22)
        let bottomColor = Color(hue: Double(hue), saturation: Double(richSat * 0.60), brightness: 0.10)

        return BackdropPalette(primary: primary, top: topColor, mid: midColor, bottom: bottomColor)
    }

    public func backdropPalette(for song: Song?, fallbackID: String) -> BackdropPalette {
        guard let song = song else {
            return defaultBackdropPalette
        }
        let key = song.id as NSString
        if let cached = backdropCache.object(forKey: key) {
            return cached
        }
        if let image = cache.object(forKey: key) {
            let palette = extractBackdropPalette(from: image)
            backdropCache.setObject(palette, forKey: key)
            return palette
        }
        // Fallback: immediately derive from spine color (O(1) instant from iTunes metadata)
        let spine = spineColors(for: song, fallbackID: fallbackID)
        let palette = derivePalette(from: spine.bg)
        backdropCache.setObject(palette, forKey: key)
        return palette
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

import Foundation
import AVFoundation

public final class AudioSpectrogramLoader {
    public static let shared = AudioSpectrogramLoader()

    private let cache = NSCache<NSString, NSArray>()

    private init() {
        cache.countLimit = 300
    }

    public func spectrogram(for song: Song, bucketCount: Int = 140) async -> [CGFloat] {
        let key = song.id as NSString
        if let cached = cache.object(forKey: key) as? [CGFloat] {
            return cached
        }

        // Fast deterministic profile first
        let fallback = generateEnvelope(for: song, count: bucketCount)

        guard let url = song.location else {
            return fallback
        }

        // Asynchronously extract RMS amplitudes directly from the audio file
        if let extracted = await extractRMS(from: url, bucketCount: bucketCount) {
            cache.setObject(extracted as NSArray, forKey: key)
            return extracted
        }

        cache.setObject(fallback as NSArray, forKey: key)
        return fallback
    }

    private func extractRMS(from url: URL, bucketCount: Int) async -> [CGFloat]? {
        let asset = AVURLAsset(url: url)
        guard let tracks = try? await asset.loadTracks(withMediaType: .audio),
              let audioTrack = tracks.first else {
            return nil
        }

        guard let reader = try? AVAssetReader(asset: asset) else {
            return nil
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(trackOutput)

        guard reader.startReading() else {
            return nil
        }

        var sampleMagnitudes: [Float] = []
        sampleMagnitudes.reserveCapacity(2048)

        // Read audio buffers in background
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            let length = CMBlockBufferGetDataLength(blockBuffer)
            var data = [Int16](repeating: 0, count: length / 2)
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &data)

            var sum: Float = 0
            let strideStep = max(1, data.count / 32)
            var count = 0
            for i in stride(from: 0, to: data.count, by: strideStep) {
                let val = Float(data[i]) / 32768.0
                sum += val * val
                count += 1
            }
            if count > 0 {
                let rms = sqrt(sum / Float(count))
                sampleMagnitudes.append(rms)
            }

            if sampleMagnitudes.count > 1000 {
                break
            }
        }
        reader.cancelReading()

        guard !sampleMagnitudes.isEmpty else { return nil }

        var buckets: [CGFloat] = []
        buckets.reserveCapacity(bucketCount)
        let blockSize = Double(sampleMagnitudes.count) / Double(bucketCount)

        for b in 0..<bucketCount {
            let start = Int(Double(b) * blockSize)
            let end = min(sampleMagnitudes.count, Int(Double(b + 1) * blockSize))
            if start < end {
                var maxVal: Float = 0
                for idx in start..<end {
                    maxVal = max(maxVal, sampleMagnitudes[idx])
                }
                buckets.append(CGFloat(maxVal))
            } else if let last = buckets.last {
                buckets.append(last)
            } else {
                buckets.append(0.2)
            }
        }

        guard let maxAmp = buckets.max(), maxAmp > 0.001 else {
            return nil
        }

        let normalized = buckets.map { val -> CGFloat in
            let n = val / maxAmp
            return CGFloat(max(0.12, min(0.92, Double(n))))
        }

        return normalized
    }

    /// Generates a realistic deterministic audio profile envelope based on song metadata
    public func generateEnvelope(for song: Song, count: Int) -> [CGFloat] {
        let seed = abs(Double(song.persistentID % 10000))
        var values: [CGFloat] = []
        values.reserveCapacity(count)

        for i in 0..<count {
            let norm = Double(i) / Double(count - 1)
            let edgeTaper = sin(norm * .pi)

            let verseHarmonic = sin(norm * 14.0 + seed * 0.1) * 0.20
            let chorusPeak = sin(norm * 6.0 + seed * 0.05) * 0.25
            let beatRhythm = cos(norm * 32.0 + seed) * 0.14
            let microTexture = sin(norm * 64.0) * 0.08

            let rawAmp = 0.40 + verseHarmonic + chorusPeak + beatRhythm + microTexture
            let amp = max(0.15, min(0.92, (rawAmp * 0.85 + 0.15) * (edgeTaper * 0.75 + 0.25)))
            values.append(CGFloat(amp))
        }

        return values
    }
}

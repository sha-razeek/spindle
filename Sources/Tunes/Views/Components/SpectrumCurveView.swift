import SwiftUI

public struct SpectrumCurveView: View {
    let isPlaying: Bool
    let accentColor: Color
    let secondaryColor: Color

    public init(
        isPlaying: Bool,
        accentColor: Color = .purple,
        secondaryColor: Color = .blue
    ) {
        self.isPlaying = isPlaying
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
    }

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height

                ZStack(alignment: .bottom) {
                    // Layer 1: Background Ambient Spectrum Fill & Wave
                    let points1 = computeSpectrumPoints(
                        width: width,
                        height: height,
                        time: time,
                        speedMultiplier: 1.0,
                        phaseOffset: 0.0,
                        amplitudeScale: isPlaying ? 0.85 : 0.05
                    )

                    SpectrumShape(points: points1, closed: true, height: height)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.28),
                                    secondaryColor.opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    SpectrumShape(points: points1, closed: false, height: height)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.45),
                                    secondaryColor.opacity(0.55),
                                    accentColor.opacity(0.35)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )

                    // Layer 2: Main Foreground Crisp Spectrum Curve with Glow
                    let points2 = computeSpectrumPoints(
                        width: width,
                        height: height,
                        time: time,
                        speedMultiplier: 1.35,
                        phaseOffset: 1.85,
                        amplitudeScale: isPlaying ? 1.0 : 0.05
                    )

                    SpectrumShape(points: points2, closed: true, height: height)
                        .fill(
                            LinearGradient(
                                colors: [
                                    secondaryColor.opacity(0.20),
                                    accentColor.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    SpectrumShape(points: points2, closed: false, height: height)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.90),
                                    Color.white.opacity(0.95),
                                    secondaryColor.opacity(0.90),
                                    accentColor.opacity(0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: accentColor.opacity(0.65), radius: 10, x: 0, y: -2)
                        .shadow(color: secondaryColor.opacity(0.40), radius: 16, x: 0, y: -4)
                }
            }
        }
    }

    /// Computes frequency spectrum points across the full width using Catmull-Rom spline input points
    private func computeSpectrumPoints(
        width: CGFloat,
        height: CGFloat,
        time: Double,
        speedMultiplier: Double,
        phaseOffset: Double,
        amplitudeScale: Double
    ) -> [CGPoint] {
        let count = 48
        guard count > 1 && width > 0 else { return [] }

        var points: [CGPoint] = []
        points.reserveCapacity(count)

        let t = time * speedMultiplier + phaseOffset

        for i in 0..<count {
            let normX = Double(i) / Double(count - 1)
            let x = CGFloat(normX) * width

            // Frequency envelope: taper smoothly to 0 at extreme left and right edges
            let envelope = sin(normX * .pi)

            // 1. Bass pulsation (prominent on left 0.0 .. 0.35)
            let bassFactor = max(0.0, 1.0 - normX * 2.2)
            let bassWave = (sin(t * 3.8 + normX * 5.0) * 0.5 + 0.5) *
                           (cos(t * 1.9 + normX * 3.0) * 0.4 + 0.6) * bassFactor

            // 2. Midrange dynamics (active around 0.25 .. 0.75)
            let midCenter = 0.45
            let midDist = abs(normX - midCenter)
            let midFactor = max(0.0, 1.0 - midDist * 2.5)
            let midWave = (sin(t * 6.2 - normX * 12.0) * 0.45 + 0.5) *
                          (sin(t * 9.1 + normX * 8.0) * 0.35 + 0.5) * midFactor

            // 3. Treble shimmer (higher frequency fine ripples on 0.5 .. 1.0)
            let trebleFactor = max(0.0, (normX - 0.4) * 1.6)
            let trebleWave = (sin(t * 12.5 + normX * 26.0) * 0.3 + 0.35) *
                             (cos(t * 16.0 - normX * 18.0) * 0.2 + 0.3) * trebleFactor

            // Combined frequency amplitude
            let totalAmp = (bassWave * 0.85 + midWave * 0.70 + trebleWave * 0.50 + 0.08) * envelope * amplitudeScale

            // Clamp max height to avoid clipping
            let peakY = CGFloat(totalAmp) * (height * 0.82)
            let y = height - peakY

            points.append(CGPoint(x: x, y: y))
        }

        return points
    }
}

/// Smooth Catmull-Rom spline curve shape connecting all spectrum points
private struct SpectrumShape: Shape {
    let points: [CGPoint]
    let closed: Bool
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = (i + 2 < points.count) ? points[i + 2] : p2

            // Catmull-Rom to Cubic Bezier control points
            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6.0,
                y: p1.y + (p2.y - p0.y) / 6.0
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6.0,
                y: p2.y - (p3.y - p1.y) / 6.0
            )

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }

        return path
    }
}

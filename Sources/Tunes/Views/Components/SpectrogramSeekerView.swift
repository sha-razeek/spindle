import SwiftUI

public struct SpectrogramSeekerView: View {
    let song: Song
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let accentColor: Color
    let secondaryColor: Color
    let onSeek: (TimeInterval) -> Void

    @State private var points: [CGFloat] = []
    @State private var isDragging: Bool = false
    @State private var dragProgress: CGFloat = 0
    @State private var isHovered: Bool = false
    @State private var hoverX: CGFloat = 0

    public init(
        song: Song,
        currentTime: TimeInterval,
        duration: TimeInterval,
        isPlaying: Bool,
        accentColor: Color,
        secondaryColor: Color,
        onSeek: @escaping (TimeInterval) -> Void
    ) {
        self.song = song
        self.currentTime = currentTime
        self.duration = duration
        self.isPlaying = isPlaying
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
        self.onSeek = onSeek
    }

    private var activeProgress: CGFloat {
        if isDragging {
            return dragProgress
        }
        guard duration > 0 else { return 0 }
        return CGFloat(max(0, min(1, currentTime / duration)))
    }

    private var activeTime: TimeInterval {
        if isDragging {
            return Double(dragProgress) * duration
        }
        return currentTime
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let progressX = activeProgress * width

            ZStack(alignment: .bottomLeading) {
                // Interactive backdrop
                Color.clear
                    .contentShape(Rectangle())

                if !points.isEmpty {
                    let splinePoints = makeSplinePoints(width: width, height: height)

                    // MARK: - 1. Unplayed / Background Spectrogram (Dim)
                    SplineCurve(points: splinePoints, closed: true, height: height)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    SplineCurve(points: splinePoints, closed: false, height: height)
                        .stroke(
                            Color.white.opacity(0.22),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                        )

                    // MARK: - 2. Played / Revealed Spectrogram (Vibrant, Glowing)
                    // Clipped to the active progress width
                    ZStack(alignment: .bottomLeading) {
                        SplineCurve(points: splinePoints, closed: true, height: height)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.42),
                                        secondaryColor.opacity(0.20),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        SplineCurve(points: splinePoints, closed: false, height: height)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        accentColor,
                                        secondaryColor,
                                        Color.white.opacity(0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                            .shadow(color: accentColor.opacity(0.65), radius: 8, x: 0, y: -2)
                    }
                    .frame(width: max(0, progressX), alignment: .leading)
                    .clipped()

                    // MARK: - 3. Playhead Cursor & Beacon
                    if progressX > 0 && progressX <= width {
                        let cursorY = sampleYAt(x: progressX, splinePoints: splinePoints, height: height)

                        // Vertical Playhead Line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.4), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 2, height: height - cursorY + 10)
                            .position(x: progressX, y: cursorY + (height - cursorY) / 2)
                            .shadow(color: .white.opacity(0.8), radius: 4)

                        // Glowing Playhead Knob at the curve surface
                        Circle()
                            .fill(Color.white)
                            .frame(width: isDragging ? 12 : 9, height: isDragging ? 12 : 9)
                            .shadow(color: accentColor, radius: 8)
                            .shadow(color: .white, radius: 4)
                            .position(x: progressX, y: cursorY)
                    }
                }

                // MARK: - 4. Timestamps & Dragging Tooltip
                VStack(spacing: 0) {
                    HStack {
                        // Current or Scrub Time
                        HStack(spacing: 4) {
                            Text(formatSeconds(activeTime))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.90))

                            if isDragging {
                                Text("• SEEKING")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(accentColor)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.65)))

                        Spacer()

                        // Remaining Time
                        Text(formatRemaining(duration: duration, current: activeTime))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.65)))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    Spacer()
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let fraction = max(0, min(1, value.location.x / width))
                        dragProgress = fraction
                    }
                    .onEnded { value in
                        let fraction = max(0, min(1, value.location.x / width))
                        let targetTime = Double(fraction) * duration
                        onSeek(targetTime)
                        isDragging = false
                    }
            )
            .onHover { hovering in
                isHovered = hovering
            }
        }
        .task(id: song.id) {
            await loadPoints()
        }
    }

    private func loadPoints() async {
        let loaded = await AudioSpectrogramLoader.shared.spectrogram(for: song, bucketCount: 140)
        await MainActor.run {
            self.points = loaded
        }
    }

    private func makeSplinePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard points.count > 1 else { return [] }
        var result: [CGPoint] = []
        result.reserveCapacity(points.count)

        let topPadding: CGFloat = 26
        let bottomPadding: CGFloat = 8
        let availableHeight = height - topPadding - bottomPadding

        for (i, val) in points.enumerated() {
            let x = CGFloat(i) / CGFloat(points.count - 1) * width
            let y = height - bottomPadding - (val * availableHeight)
            result.append(CGPoint(x: x, y: y))
        }

        return result
    }

    private func sampleYAt(x: CGFloat, splinePoints: [CGPoint], height: CGFloat) -> CGFloat {
        guard splinePoints.count >= 2 else { return height / 2 }
        for i in 0..<(splinePoints.count - 1) {
            let p1 = splinePoints[i]
            let p2 = splinePoints[i + 1]
            if x >= p1.x && x <= p2.x {
                let range = p2.x - p1.x
                guard range > 0 else { return p1.y }
                let t = (x - p1.x) / range
                return p1.y + t * (p2.y - p1.y)
            }
        }
        return splinePoints.last?.y ?? height / 2
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatRemaining(duration: TimeInterval, current: TimeInterval) -> String {
        let remaining = max(0, duration - current)
        return "-" + formatSeconds(remaining)
    }
}

/// Catmull-Rom Smooth Spline Shape
private struct SplineCurve: Shape {
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

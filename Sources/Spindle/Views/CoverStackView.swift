import SwiftUI

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct CoverStackView: View {
    let albums: [Album]
    @ObservedObject var player: AudioPlayer

    @State private var selectedAlbumForDetail: Album?
    @State private var poppedOutAlbumID: String? = nil
    @State private var lastScrollY: CGFloat = 0
    @State private var isProgrammaticScroll: Bool = false
    @State private var programmaticScrollTask: Task<Void, Never>? = nil

    // Alphabet Index State
    private let alphabet: [String] = ["#"] + (65...90).map { String(UnicodeScalar($0)!) }
    @State private var activeLetter: String? = nil
    @State private var hoveredLetter: String? = nil
    @State private var letterMap: [String: Album] = [:]
    @State private var letterIndices: [String: Int] = [:]
    @State private var showLetterHUD: Bool = false
    @State private var hudLetter: String? = nil
    @State private var hudDismissTask: Task<Void, Never>? = nil

    // Quick Scrubber Bar State
    @State private var scrubFraction: CGFloat = 0.0
    @State private var isScrubbing: Bool = false
    @State private var isHoveringScrubber: Bool = false
    @State private var scrubbingAlbum: Album? = nil
    @State private var lastScrolledAlbumID: String? = nil
    @State private var scrubTask: Task<Void, Never>? = nil

    // Now Playing Header Button State
    @State private var isHoveringNowPlaying: Bool = false

    private var currentBackdrop: BackdropPalette {
        if let song = player.currentSong {
            return ArtworkLoader.shared.backdropPalette(for: song, fallbackID: song.id)
        }
        return ArtworkLoader.shared.defaultBackdropPalette
    }

    private var currentlyPlayingAlbum: Album? {
        guard let song = player.currentSong else { return nil }
        if let match = albums.first(where: { $0.songs.contains(where: { $0.id == song.id }) }) {
            return match
        }
        let songArtist = song.albumArtistName.isEmpty ? song.artistName : song.albumArtistName
        return albums.first(where: {
            $0.title.localizedCaseInsensitiveCompare(song.albumTitle) == .orderedSame &&
            ($0.artistName.localizedCaseInsensitiveCompare(songArtist) == .orderedSame ||
             $0.artistName.localizedCaseInsensitiveCompare(song.artistName) == .orderedSame)
        })
    }

    public init(albums: [Album], player: AudioPlayer) {
        self.albums = albums
        self.player = player
    }

    public var body: some View {
        if let album = selectedAlbumForDetail {
            AlbumDetailView(album: album, player: player) {
                selectedAlbumForDetail = nil
            }
        } else {
            let backdrop = currentBackdrop

            ZStack {
                // MARK: - Dynamic Playing Album Backdrop
                ZStack {
                    backdrop.bottom.ignoresSafeArea()

                    LinearGradient(
                        colors: [
                            backdrop.top,
                            backdrop.mid,
                            backdrop.bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // Atmospheric glowing radial spotlight radiating from upper-center
                    RadialGradient(
                        colors: [
                            backdrop.primary.opacity(0.40),
                            backdrop.mid.opacity(0.18),
                            Color.clear
                        ],
                        center: .init(x: 0.5, y: 0.30),
                        startRadius: 70,
                        endRadius: 750
                    )
                    .ignoresSafeArea()

                    // Ambient glowing color aura for rich visual depth
                    Circle()
                        .fill(backdrop.primary.opacity(0.30))
                        .frame(width: 650, height: 650)
                        .offset(x: 100, y: -70)
                        .blur(radius: 120)
                        .allowsHitTesting(false)
                }
                .animation(.easeInOut(duration: 0.80), value: player.currentSong?.id)
                .contentShape(Rectangle())
                .onTapGesture {
                    retractPoppedOutAlbum()
                }
                .task(id: player.currentSong?.id) {
                    if let song = player.currentSong {
                        _ = await ArtworkLoader.shared.loadArtwork(for: song)
                    }
                }

                if albums.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No albums found")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    ScrollViewReader { proxy in
                        ZStack {
                            // MARK: - 1. 3D Albums Stack ScrollView
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    // Scroll tracker anchor at the top
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: ScrollOffsetKey.self,
                                                value: geo.frame(in: .named("CoverScrollSpace")).minY
                                            )
                                    }
                                    .frame(height: 0)

                                    // Dynamic Top breathing room to ensure any album (even the first) can be centered
                                    Color.clear.frame(height: poppedOutAlbumID != nil ? 380 : 100)

                                    // Drawer Albums Stack
                                    LazyVStack(spacing: 0) {
                                        ForEach(albums) { album in
                                            albumSlabRow(for: album, proxy: proxy)
                                        }
                                    }

                                    // Dynamic Bottom breathing room to ensure any album (even the last) can be centered
                                    Color.clear.frame(height: poppedOutAlbumID != nil ? 440 : 180)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .coordinateSpace(name: "CoverScrollSpace")
                            // Track scroll offset changes -> Real-time scrub fraction and manual scroll retraction
                            .onPreferenceChange(ScrollOffsetKey.self) { currentY in
                                if !isScrubbing, albums.count > 1 {
                                    let estimatedContentHeight = max(1.0, CGFloat(albums.count) * 96.0 - 250.0)
                                    let progress = min(max(0.0, -currentY / estimatedContentHeight), 1.0)
                                    scrubFraction = progress
                                    let index = min(max(0, Int(progress * CGFloat(albums.count - 1))), albums.count - 1)
                                    activeLetter = initialLetter(for: albums[index].title)
                                }

                                guard poppedOutAlbumID != nil else { return }
                                if isProgrammaticScroll {
                                    lastScrollY = currentY
                                    return
                                }
                                if abs(currentY - lastScrollY) > 3.0 {
                                    retractPoppedOutAlbum()
                                    lastScrollY = currentY
                                }
                            }
                            .onAppear {
                                buildLetterMap()
                                scrollToPlayingAlbum(proxy: proxy, force: true)
                            }
                            .onChange(of: albums.count) { _, newCount in
                                buildLetterMap()
                                if newCount > 0 && poppedOutAlbumID == nil {
                                    scrollToPlayingAlbum(proxy: proxy, force: false)
                                }
                            }
                            .onChange(of: player.currentSong?.id) { _, newSongID in
                                guard newSongID != nil else { return }
                                if let playingAlbum = currentlyPlayingAlbum, playingAlbum.id != poppedOutAlbumID {
                                    scrollToPlayingAlbum(proxy: proxy, force: false)
                                }
                            }

                            // MARK: - 2. Left Alphabet Jump Index (A-Z)
                            HStack {
                                alphabetStrip(proxy: proxy)
                                    .padding(.leading, 12)
                                Spacer()
                            }

                            // MARK: - 3. Right Quick-Scrubber Pill
                            HStack {
                                Spacer()
                                scrubBar(proxy: proxy)
                                    .padding(.trailing, 8)
                            }

                            // MARK: - 4. Floating Header
                            VStack {
                                HStack(spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.stack.3d.up.fill")
                                            .font(.system(size: 13))
                                        Text("VINYL DRAWER")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(1)
                                        Text("• \(albums.count) albums")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)

                                    // Quick "Now Playing" jump button
                                    if let playingAlbum = currentlyPlayingAlbum {
                                        let isFocused = (poppedOutAlbumID == playingAlbum.id)
                                        Button {
                                            scrollToPlayingAlbum(proxy: proxy, force: true)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "play.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(isFocused ? .white : Color.accentColor)

                                                Text("NOW PLAYING")
                                                    .font(.system(size: 10.5, weight: .bold))
                                                    .tracking(0.6)

                                                Text("• \(playingAlbum.title)")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.85))
                                                    .lineLimit(1)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(isHoveringNowPlaying ? Color.white.opacity(0.20) : Color.clear)
                                                    .background(Capsule().fill(.ultraThinMaterial))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(isFocused ? Color.white.opacity(0.40) : Color.white.opacity(0.18), lineWidth: 1)
                                                    )
                                            )
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 2)
                                        }
                                        .buttonStyle(.plain)
                                        .onHover { h in
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                isHoveringNowPlaying = h
                                            }
                                        }
                                        .help("Jump back to now playing album: \(playingAlbum.title)")
                                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                                    }

                                    Spacer()
                                }
                                .padding(.leading, 24)
                                .padding(.top, 16)

                                Spacer()
                            }
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentlyPlayingAlbum?.id)

                            // MARK: - 5. Center HUD Flash on Alphabet Jump
                            if showLetterHUD, let letter = hudLetter {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 8)
                                        .frame(width: 90, height: 90)

                                    Text(letter)
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .allowsHitTesting(false)
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                                .zIndex(1000)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Left Alphabet Strip View
    @ViewBuilder
    private func alphabetStrip(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 1.5) {
            ForEach(alphabet, id: \.self) { letter in
                let hasAlbums = (letterMap[letter] != nil)
                let isSelected = (activeLetter == letter)
                let isHovered = (hoveredLetter == letter)

                Text(letter)
                    .font(.system(size: 9.5, weight: isSelected ? .bold : (hasAlbums ? .semibold : .regular), design: .rounded))
                    .foregroundColor(
                        isSelected ? .white :
                        (hasAlbums ? (isHovered ? .white : .white.opacity(0.85)) : .white.opacity(0.20))
                    )
                    .frame(width: 18, height: 14)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : (isHovered && hasAlbums ? Color.white.opacity(0.18) : Color.clear))
                            .frame(width: 15, height: 15)
                    )
                    .contentShape(Rectangle())
                    .onHover { h in
                        if h && hasAlbums {
                            hoveredLetter = letter
                        } else if hoveredLetter == letter {
                            hoveredLetter = nil
                        }
                    }
                    .onTapGesture {
                        if hasAlbums {
                            jumpToLetter(letter, proxy: proxy)
                        }
                    }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 2, y: 2)
        )
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { gesture in
                    let y = gesture.location.y - 8
                    let itemTotalHeight: CGFloat = 15.5
                    let index = Int(y / itemTotalHeight)
                    if index >= 0 && index < alphabet.count {
                        let letter = alphabet[index]
                        if letter != activeLetter && letterMap[letter] != nil {
                            jumpToLetter(letter, proxy: proxy)
                        }
                    }
                }
        )
    }

    // MARK: - Right Quick Scrubber Bar View
    @ViewBuilder
    private func scrubBar(proxy: ScrollViewProxy) -> some View {
        GeometryReader { geo in
            let topInset: CGFloat = 65
            let bottomInset: CGFloat = 45
            let availableHeight = max(100, geo.size.height - topInset - bottomInset)
            let pillHeight: CGFloat = 44
            let travelDistance = max(1.0, availableHeight - pillHeight)
            let pillY = topInset + travelDistance * scrubFraction

            ZStack(alignment: .topTrailing) {
                // Interactive Hit Zone & Track Line
                Color.clear
                    .frame(width: 32, height: availableHeight)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(isHoveringScrubber || isScrubbing ? 0.22 : 0.08))
                            .frame(width: (isHoveringScrubber || isScrubbing) ? 4.5 : 3, height: availableHeight)
                            .animation(.easeInOut(duration: 0.15), value: isHoveringScrubber || isScrubbing)
                    )
                    .offset(y: topInset)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isScrubbing {
                                    isScrubbing = true
                                    retractPoppedOutAlbum()
                                }
                                let currentY = value.location.y - topInset
                                let fraction = min(max(0.0, currentY / availableHeight), 1.0)
                                handleScrubUpdate(fraction: fraction, proxy: proxy)
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.22)) {
                                    isScrubbing = false
                                }
                            }
                    )
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHoveringScrubber = hovering
                        }
                    }

                // Sliding Pill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isScrubbing ? 0.98 : (isHoveringScrubber ? 0.85 : 0.55)),
                                Color.white.opacity(isScrubbing ? 0.85 : (isHoveringScrubber ? 0.70 : 0.40))
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.75)
                    )
                    .frame(
                        width: (isHoveringScrubber || isScrubbing) ? 9 : 5,
                        height: pillHeight
                    )
                    .shadow(
                        color: Color.black.opacity(isScrubbing ? 0.45 : 0.25),
                        radius: isScrubbing ? 6 : 3,
                        x: 0,
                        y: 1.5
                    )
                    .offset(x: -11, y: pillY)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.15), value: isHoveringScrubber || isScrubbing)

                // Floating Preview Callout (displayed during scrubbing)
                if isScrubbing, let album = scrubbingAlbum {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.accentColor.opacity(0.90))
                                .frame(width: 32, height: 32)
                            Text(initialLetter(for: album.title))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(album.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(album.artistName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.80))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 190, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.50), radius: 14, x: 0, y: 6)
                    )
                    .offset(x: -42, y: min(max(topInset, pillY - 4), topInset + availableHeight - 48))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .frame(width: 38)
    }

    // MARK: - Navigation & Layout Helpers
    private func initialLetter(for title: String) -> String {
        let stripped = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'`“‘([{")))
        guard let firstChar = stripped.first else { return "#" }
        let s = String(firstChar).uppercased()
        if s >= "A" && s <= "Z" {
            return s
        }
        return "#"
    }

    private func buildLetterMap() {
        var map: [String: Album] = [:]
        var indices: [String: Int] = [:]
        for (index, album) in albums.enumerated() {
            let letter = initialLetter(for: album.title)
            if map[letter] == nil {
                map[letter] = album
                indices[letter] = index
            }
        }
        self.letterMap = map
        self.letterIndices = indices
    }

    private func jumpToLetter(_ letter: String, proxy: ScrollViewProxy) {
        guard let targetAlbum = letterMap[letter] else { return }
        activeLetter = letter
        retractPoppedOutAlbum()

        // Trigger brief Center HUD flash
        hudLetter = letter
        withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
            showLetterHUD = true
        }
        hudDismissTask?.cancel()
        hudDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            withAnimation(.easeOut(duration: 0.28)) {
                showLetterHUD = false
            }
        }

        // Align right scrub pill fraction
        if let index = letterIndices[letter], albums.count > 1 {
            scrubFraction = CGFloat(index) / CGFloat(albums.count - 1)
        }

        // Scroll directly to target album section
        isProgrammaticScroll = true
        programmaticScrollTask?.cancel()
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(targetAlbum.id, anchor: .top)
        }
        programmaticScrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            isProgrammaticScroll = false
        }
    }

    private func handleScrubUpdate(fraction: CGFloat, proxy: ScrollViewProxy) {
        guard !albums.isEmpty else { return }
        let index = min(max(0, Int(fraction * CGFloat(albums.count - 1))), albums.count - 1)
        let album = albums[index]

        scrubFraction = fraction
        scrubbingAlbum = album
        activeLetter = initialLetter(for: album.title)

        if lastScrolledAlbumID != album.id {
            lastScrolledAlbumID = album.id
            isProgrammaticScroll = true

            scrubTask?.cancel()
            scrubTask = Task { @MainActor in
                proxy.scrollTo(album.id, anchor: .center)
                try? await Task.sleep(nanoseconds: 70_000_000)
                isProgrammaticScroll = false
            }
        }
    }

    @ViewBuilder
    private func albumSlabRow(for album: Album, proxy: ScrollViewProxy) -> some View {
        let isPopped = (poppedOutAlbumID == album.id)
        let isCurrent = (currentlyPlayingAlbum?.id == album.id)
        AlbumSlabView(
            album: album,
            isPoppedOut: isPopped,
            isCurrentlyPlayingThisAlbum: isCurrent,
            isPlaying: player.isPlaying,
            player: player,
            onTogglePopOut: {
                handleAlbumClick(album: album, proxy: proxy)
            },
            onSelectDetail: {
                selectedAlbumForDetail = album
            }
        )
        .equatable()
        .id(album.id)
        .zIndex(isPopped ? 999 : 0)
    }

    private func centerAlbum(_ album: Album, proxy: ScrollViewProxy, animated: Bool = true) {
        isProgrammaticScroll = true
        programmaticScrollTask?.cancel()

        // Sync active letter & scrubber fraction to centered album
        activeLetter = initialLetter(for: album.title)
        if let idx = albums.firstIndex(where: { $0.id == album.id }), albums.count > 1 {
            scrubFraction = CGFloat(idx) / CGFloat(albums.count - 1)
        }

        withAnimation(animated ? .spring(response: 0.42, dampingFraction: 0.80) : nil) {
            poppedOutAlbumID = album.id
            proxy.scrollTo(album.id, anchor: .center)
        }

        programmaticScrollTask = Task { @MainActor in
            // Stage 1: Quick frame to prime lazy elements around target
            try? await Task.sleep(nanoseconds: 60_000_000)
            withAnimation(animated ? .spring(response: 0.42, dampingFraction: 0.80) : nil) {
                proxy.scrollTo(album.id, anchor: .center)
            }

            // Stage 2: Secondary refinement once slab expansion (614pt) and breathing room settle
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(animated ? .spring(response: 0.42, dampingFraction: 0.80) : nil) {
                proxy.scrollTo(album.id, anchor: .center)
            }

            // Stage 3: Hold the programmatic scroll guard until inertia and spring animation settle
            try? await Task.sleep(nanoseconds: 480_000_000)
            isProgrammaticScroll = false
        }
    }

    private func scrollToPlayingAlbum(proxy: ScrollViewProxy, force: Bool = false) {
        guard let album = currentlyPlayingAlbum else { return }
        if force || poppedOutAlbumID != album.id {
            centerAlbum(album, proxy: proxy)
        }
    }

    private func handleAlbumClick(album: Album, proxy: ScrollViewProxy) {
        let isAlreadyPlayingThisAlbum = player.currentSong != nil && album.songs.contains(where: { $0.id == player.currentSong?.id })

        if poppedOutAlbumID == album.id {
            // Already popped out: toggle playback
            player.togglePlayPause()
        } else {
            centerAlbum(album, proxy: proxy)

            if isAlreadyPlayingThisAlbum {
                // Already playing: continue playing without starting over!
                if !player.isPlaying {
                    player.togglePlayPause()
                }
            } else {
                // Not playing: start album from the first track
                if let first = album.songs.first {
                    player.play(song: first, inContext: album.songs)
                }
            }
        }
    }

    private func retractPoppedOutAlbum() {
        guard poppedOutAlbumID != nil else { return }
        programmaticScrollTask?.cancel()
        isProgrammaticScroll = false
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            poppedOutAlbumID = nil
        }
    }
}

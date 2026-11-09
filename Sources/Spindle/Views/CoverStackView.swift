import SwiftUI

// MARK: - Isolated Backdrop View (Equatable to prevent redundant re-renders)
private struct CoverBackdropView: View, Equatable {
    let backdrop: BackdropPalette
    let songID: String?

    static func == (lhs: CoverBackdropView, rhs: CoverBackdropView) -> Bool {
        lhs.songID == rhs.songID
    }

    var body: some View {
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

            // Atmospheric glowing radial spotlight radiating from the turntable deck
            RadialGradient(
                colors: [
                    backdrop.primary.opacity(0.42),
                    backdrop.mid.opacity(0.20),
                    Color.clear
                ],
                center: .init(x: 0.35, y: 0.40),
                startRadius: 80,
                endRadius: 800
            )
            .ignoresSafeArea()

            // Ambient glowing color aura
            Circle()
                .fill(backdrop.primary.opacity(0.35))
                .frame(width: 700, height: 700)
                .offset(x: -60, y: -40)
                .blur(radius: 130)
                .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 0.80), value: songID)
        .allowsHitTesting(false)
    }
}

public struct CoverStackView: View {
    let albums: [Album]
    @ObservedObject var player: AudioPlayer

    @State private var deckAlbum: Album?
    @State private var selectedAlbumForDetail: Album?

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
    @State private var lastScrubTimestamp: CFTimeInterval = 0

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

    private var activeDeckAlbum: Album? {
        deckAlbum ?? currentlyPlayingAlbum ?? albums.first
    }

    private var currentBackdrop: BackdropPalette {
        let song = player.currentSong ?? activeDeckAlbum?.representativeSong
        if let song = song {
            return ArtworkLoader.shared.backdropPalette(for: song, fallbackID: song.id)
        }
        return ArtworkLoader.shared.defaultBackdropPalette
    }

    public init(albums: [Album], player: AudioPlayer) {
        self.albums = albums
        self.player = player
    }

    public var body: some View {
        if let album = selectedAlbumForDetail {
            AlbumDetailView(album: album, player: player, backTitle: "3D Turntable") {
                selectedAlbumForDetail = nil
            }
        } else {
            let backdrop = currentBackdrop

            ZStack {
                // MARK: - Dynamic Playing Album Backdrop
                CoverBackdropView(backdrop: backdrop, songID: player.currentSong?.id ?? activeDeckAlbum?.id)
                    .equatable()
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
                    HStack(spacing: 0) {
                        // MARK: - LEFT STAGE: Turntable Deck (Sleeve + Record + Tonearm)
                        VStack(spacing: 0) {
                            Spacer()

                            TurntableDeckView(
                                album: activeDeckAlbum,
                                isPlaying: isCurrentlyPlayingActiveDeckAlbum,
                                player: player,
                                onTogglePlay: {
                                    handleDeckPlayToggle()
                                },
                                onSelectDetail: {
                                    if let album = activeDeckAlbum {
                                        selectedAlbumForDetail = album
                                    }
                                }
                            )

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Hairline glass separator
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.04),
                                        Color.white.opacity(0.18),
                                        Color.white.opacity(0.04)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 1)
                            .ignoresSafeArea()

                        // MARK: - RIGHT COLUMN: Independent 3D Album List (Vinyl Crate)
                        rightAlbumCrate
                    }
                }
            }
            .onAppear {
                buildLetterMap()
                if deckAlbum == nil {
                    deckAlbum = currentlyPlayingAlbum ?? albums.first
                }
            }
            .onChange(of: albums.count) { _, _ in
                buildLetterMap()
                if deckAlbum == nil {
                    deckAlbum = currentlyPlayingAlbum ?? albums.first
                }
            }
            .onChange(of: player.currentSong?.id) { _, newSongID in
                guard newSongID != nil else { return }
                if let playing = currentlyPlayingAlbum {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        deckAlbum = playing
                    }
                }
            }
        }
    }

    private var isCurrentlyPlayingActiveDeckAlbum: Bool {
        guard let current = player.currentSong, let deck = activeDeckAlbum else { return false }
        return deck.songs.contains(where: { $0.id == current.id }) && player.isPlaying
    }

    private func handleDeckPlayToggle() {
        guard let target = activeDeckAlbum else { return }
        let isAlreadyPlayingThis = player.currentSong != nil && target.songs.contains(where: { $0.id == player.currentSong?.id })
        if isAlreadyPlayingThis {
            player.togglePlayPause()
        } else if let first = target.songs.first {
            player.play(song: first, inContext: target.songs)
        }
    }

    private func handleAlbumSelect(album: Album) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            deckAlbum = album
        }

        let isAlreadyPlayingThis = player.currentSong != nil && album.songs.contains(where: { $0.id == player.currentSong?.id })
        if isAlreadyPlayingThis {
            if !player.isPlaying {
                player.togglePlayPause()
            }
        } else {
            if let first = album.songs.first {
                player.play(song: first, inContext: album.songs)
            }
        }
    }

    // MARK: - Right Column Album Crate
    private var rightAlbumCrate: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                VStack(spacing: 0) {
                    // Crate Header
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 12))
                            Text("VINYL DRAWER")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1)
                            Text("• \(albums.count)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)

                        Spacer()

                        // Quick "Now Playing" jump button
                        if let playing = currentlyPlayingAlbum {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    deckAlbum = playing
                                    proxy.scrollTo(playing.id, anchor: .center)
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "play.fill")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(Color.accentColor)
                                    Text("Now Playing")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .help("Jump to currently playing album: \(playing.title)")
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    // Scrollable 3D LP Album Crate (Real stacked LPs with 3D perspective)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 14)

                            LazyVStack(spacing: 0) {
                                ForEach(albums) { album in
                                    let isSelected = (activeDeckAlbum?.id == album.id)
                                    let isPlayingThis = (currentlyPlayingAlbum?.id == album.id && player.isPlaying)

                                    CrateLPSlabView(
                                        album: album,
                                        isSelected: isSelected,
                                        isPlaying: isPlayingThis,
                                        onSelect: {
                                            handleAlbumSelect(album: album)
                                        }
                                    )
                                    .equatable()
                                    .id(album.id)
                                }
                            }

                            Color.clear.frame(height: 140)
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 26) // Space for scrubber & index
                    }
                }
                .frame(width: 345)

                // Left Alphabet Jump Index overlay
                HStack {
                    alphabetStrip(proxy: proxy)
                        .padding(.leading, 6)
                    Spacer()
                }

                // Quick Scrubber Bar on right edge
                scrubBar(proxy: proxy)
                    .padding(.trailing, 4)

                // Center HUD Flash on Alphabet Jump
                if showLetterHUD, let letter = hudLetter {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 6)
                            .frame(width: 80, height: 80)

                        Text(letter)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .allowsHitTesting(false)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .padding(.trailing, 140)
                    .zIndex(1000)
                }
            }
            .frame(width: 355)
            .background(Color.black.opacity(0.18))
        }
    }

    // MARK: - Alphabet Index Strip
    @ViewBuilder
    private func alphabetStrip(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 1.2) {
            ForEach(alphabet, id: \.self) { letter in
                let hasAlbums = (letterMap[letter] != nil)
                let isSelected = (activeLetter == letter)
                let isHovered = (hoveredLetter == letter)

                Text(letter)
                    .font(.system(size: 8.5, weight: isSelected ? .bold : (hasAlbums ? .semibold : .regular), design: .rounded))
                    .foregroundColor(
                        isSelected ? .white :
                        (hasAlbums ? (isHovered ? .white : .white.opacity(0.85)) : .white.opacity(0.20))
                    )
                    .frame(width: 14, height: 11)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : (isHovered && hasAlbums ? Color.white.opacity(0.18) : Color.clear))
                            .frame(width: 12, height: 12)
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
        .padding(.vertical, 6)
        .padding(.horizontal, 3)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 8, x: 1, y: 1)
        )
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { gesture in
                    let y = gesture.location.y - 6
                    let itemTotalHeight: CGFloat = 12.2
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

    // MARK: - Right Quick Scrubber Bar
    @ViewBuilder
    private func scrubBar(proxy: ScrollViewProxy) -> some View {
        GeometryReader { geo in
            let topInset: CGFloat = 60
            let bottomInset: CGFloat = 30
            let availableHeight = max(100, geo.size.height - topInset - bottomInset)
            let pillHeight: CGFloat = 38
            let travelDistance = max(1.0, availableHeight - pillHeight)
            let pillY = topInset + travelDistance * scrubFraction

            ZStack(alignment: .topTrailing) {
                // Interactive hit area
                Color.clear
                    .frame(width: 24, height: availableHeight)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(isHoveringScrubber || isScrubbing ? 0.22 : 0.08))
                            .frame(width: (isHoveringScrubber || isScrubbing) ? 4 : 2.5, height: availableHeight)
                    )
                    .offset(y: topInset)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isScrubbing {
                                    isScrubbing = true
                                }
                                let currentY = value.location.y - topInset
                                let fraction = min(max(0.0, currentY / availableHeight), 1.0)
                                handleScrubUpdate(fraction: fraction, proxy: proxy)
                            }
                            .onEnded { _ in
                                finishScrubbing(proxy: proxy)
                            }
                    )
                    .onHover { h in isHoveringScrubber = h }

                // Sliding Pill
                Capsule()
                    .fill(Color.white.opacity(isScrubbing ? 0.95 : (isHoveringScrubber ? 0.80 : 0.45)))
                    .frame(width: (isHoveringScrubber || isScrubbing) ? 7 : 4, height: pillHeight)
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                    .offset(x: -8, y: pillY)
                    .allowsHitTesting(false)

                // Floating Preview Callout during scrub
                if isScrubbing, let album = scrubbingAlbum {
                    HStack(spacing: 8) {
                        Text(initialLetter(for: album.title))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor)
                            .cornerRadius(5)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(album.title)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(album.artistName)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 140, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 4)
                    )
                    .offset(x: -30, y: min(max(topInset, pillY - 4), topInset + availableHeight - 40))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .frame(width: 26)
    }

    // MARK: - Alphabet & Scrubber Helpers
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

        if let index = letterIndices[letter], albums.count > 1 {
            scrubFraction = CGFloat(index) / CGFloat(albums.count - 1)
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(targetAlbum.id, anchor: .top)
        }
    }

    private func handleScrubUpdate(fraction: CGFloat, proxy: ScrollViewProxy) {
        guard !albums.isEmpty else { return }
        let index = min(max(0, Int(fraction * CGFloat(albums.count - 1))), albums.count - 1)
        let album = albums[index]

        scrubFraction = fraction
        scrubbingAlbum = album

        let letter = initialLetter(for: album.title)
        if letter != activeLetter {
            activeLetter = letter
        }

        let now = CACurrentMediaTime()
        if now - lastScrubTimestamp >= 0.032 {
            lastScrubTimestamp = now
            if lastScrolledAlbumID != album.id {
                lastScrolledAlbumID = album.id
                proxy.scrollTo(album.id, anchor: .center)
            }
        } else {
            scrubTask?.cancel()
            scrubTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 35_000_000)
                guard !Task.isCancelled else { return }
                lastScrubTimestamp = CACurrentMediaTime()
                if lastScrolledAlbumID != album.id {
                    lastScrolledAlbumID = album.id
                    proxy.scrollTo(album.id, anchor: .center)
                }
            }
        }
    }

    private func finishScrubbing(proxy: ScrollViewProxy) {
        scrubTask?.cancel()
        if let target = scrubbingAlbum {
            lastScrolledAlbumID = target.id
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                proxy.scrollTo(target.id, anchor: .center)
            }
        }
        withAnimation(.easeOut(duration: 0.20)) {
            isScrubbing = false
        }
    }
}

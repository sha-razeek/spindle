# Tunes — Native macOS Local Music Player

A lightweight, high-performance native macOS music player built in SwiftUI. **Tunes** interfaces directly with your existing Apple Music library, giving you instant access to your entire music collection with **zero storage duplication**.

---

## Can It Access the Same Library as Apple Music Without Duplication?

**Yes, completely and natively.**

Apple provides the official **`iTunesLibrary.framework` (`ITLibrary`)** on macOS for this exact purpose:

1. **Zero Database Duplication**: `Tunes` loads metadata directly from Apple Music's central library (`ITLibrary(apiVersion: "1.0")`). Songs, album titles, artists, genres, track numbers, and playlists are read directly from the existing database.
2. **Zero Audio File Duplication**: Every track in `ITLibrary` provides a `location` URL pointing to the actual local audio file on your disk (e.g. `~/Music/Music/Media.localized/...` or an external drive like `/Volumes/Vault/...`). Playback streams directly from the existing files via `AVPlayer`.
3. **Zero Artwork Duplication**: `ITLibArtwork` provides cached album art (`art.image` / `art.imageData`) directly from Apple Music's cache. If a track's artwork is embedded in the audio file tags instead, `Tunes` automatically extracts it on demand without saving duplicate copies.
4. **Local vs DRM Files**:
   - **Local Files (MP3, AAC/M4A, ALAC, WAV, AIFF, ripped CDs, purchases)**: Fully accessible and playable.
   - **Apple Music Streaming Cache (FairPlay DRM `.m4p`)**: DRM-protected streaming subscription tracks cannot be decoded outside Apple's FairPlay pipeline. `Tunes` filters or identifies these so your player focuses smoothly on your DRM-free local library.

---

## App Features

- **Direct Apple Music Integration**: Automatically imports your local songs, albums, artists, and playlists.
- **High-Fidelity Audio Engine**: Built on `AVFoundation` with instant seeking, volume control, repeat modes (Off, All, One), and shuffle.
- **Now Playing & Keyboard Controls**:
  - Full macOS **Control Center** and **Touch Bar / Media Key** integration via `MPRemoteCommandCenter` (F7 Prev, F8 Play/Pause, F9 Next, Spacebar).
  - macOS **Now Playing** info center (`MPNowPlayingInfoCenter`) updating track title, artist, elapsed time, and artwork.
- **Sleek macOS UI**:
  - **3D Cover Stack View**: An immersive 3D cascading perspective browser inspired by physical record stacks with color-sampled front spines, studio lighting, and smooth scrolling.
  - **Songs View**: Sortable table with Title, Artist, Album, and Duration with search filtering.
  - **Albums View**: Responsive album cover grid with view switcher between Grid and 3D Stack.
  - **Artists View**: Two-pane discography browser by artist.
  - **Playlists View**: Preserves playlist order from Apple Music.
  - **Up Next Queue**: Flyout popover showing upcoming tracks with instant track selection.
  - **Reveal in Finder**: Direct button to locate the original audio file in Finder.

---

## Quick Start

### 1. Launch the Pre-built App
```bash
open build/Tunes.app
```
*(Or drag `build/Tunes.app` to `/Applications`)*

### 2. Building from Source
Run the included build script to compile the release binary, generate the app icon, and assemble the `.app` bundle:
```bash
./scripts/build_app.sh
```

Or build with Swift Package Manager:
```bash
swift build
```

---

## Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Space` | Play / Pause |
| `Cmd + Right Arrow` | Next Track |
| `Cmd + Left Arrow` | Previous Track |
| `Cmd + Shift + S` | Toggle Shuffle |
| `Cmd + Shift + R` | Cycle Repeat Mode |

---

## Project Structure

```
Tunes/
├── Package.swift                  # Swift Package Manager definition
├── Sources/
│   └── Tunes/
│       ├── App.swift              # App entry point & menu shortcuts
│       ├── Models/
│       │   ├── Song.swift         # Song model wrapping ITLibMediaItem
│       │   ├── Album.swift        # Album grouping & sorting
│       │   ├── Artist.swift       # Artist discography grouping
│       │   └── Playlist.swift     # Playlist representation
│       ├── Services/
│       │   ├── LibraryManager.swift # ITLibrary loader & search index
│       │   ├── AudioPlayer.swift    # AVPlayer, MPRemoteCommandCenter
│       │   └── ArtworkLoader.swift  # Thread-safe artwork cache
│       └── Views/
│           ├── ContentView.swift    # NavigationSplitView & sidebar
│           ├── SongsListView.swift  # Sortable songs table
│           ├── AlbumsGridView.swift # Album grid
│           ├── AlbumDetailView.swift# Album detail page
│           ├── ArtistsView.swift    # Artist discography view
│           ├── PlaylistDetailView.swift # Playlist tracklist
│           ├── NowPlayingBar.swift  # Bottom transport bar & scrubber
│           ├── QueuePopoverView.swift # Up Next queue popover
│           └── Components/
│               └── ArtworkView.swift # Async album art display
├── Resources/
│   ├── Info.plist                 # Permissions & bundle metadata
│   └── AppIcon.icns               # Multi-resolution macOS app icon
├── scripts/
│   ├── build_app.sh               # App bundle packaging & codesign
│   └── generate_icon.swift        # Icon generator script
└── build/
    └── Tunes.app                  # Standalone runnable macOS Application
```

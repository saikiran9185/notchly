import Foundation

struct NowPlayingInfo: Equatable {
    let title: String
    let artist: String
    let isPlaying: Bool

    var displayLine: String {
        artist.isEmpty ? title : "\(title) · \(artist)"
    }
}

final class NowPlayingMonitor: NSObject, @unchecked Sendable {
    var onUpdate: ((NowPlayingInfo?) -> Void)?
    private(set) var current: NowPlayingInfo?

    func start() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleMusic(_:)),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSpotify(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    func stop() {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func handleMusic(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let state = info["Player State"] as? String ?? ""
        let isPlaying = state == "Playing"

        if let title = info["Name"] as? String, !title.isEmpty {
            let artist = info["Artist"] as? String ?? ""
            let nowPlaying = isPlaying ? NowPlayingInfo(title: title, artist: artist, isPlaying: true) : nil
            DispatchQueue.main.async { [weak self] in
                self?.current = nowPlaying
                self?.onUpdate?(nowPlaying)
            }
        } else if !isPlaying {
            DispatchQueue.main.async { [weak self] in
                self?.current = nil
                self?.onUpdate?(nil)
            }
        }
    }

    @objc private func handleSpotify(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let isPlaying = info["Playing"] as? Bool ?? false
        let title = info["Name"] as? String ?? ""
        let artist = info["Artist"] as? String ?? ""

        if isPlaying && !title.isEmpty {
            let nowPlaying = NowPlayingInfo(title: title, artist: artist, isPlaying: true)
            DispatchQueue.main.async { [weak self] in
                self?.current = nowPlaying
                self?.onUpdate?(nowPlaying)
            }
        } else if !isPlaying {
            DispatchQueue.main.async { [weak self] in
                self?.current = nil
                self?.onUpdate?(nil)
            }
        }
    }
}

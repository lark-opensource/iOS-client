//
//  DriveVideoPlayer.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/1/13.
//

// 播放器的封装类
// 业务不直接依赖具体播放器

protocol DriveVideoPlayer: AnyObject {
    var delegate: DriveVideoPlayerDelegate? { get set }
    var muted: Bool { get set }

    var playerView: UIView { get }
    var currentPlaybackTime: Double { get }
    var duration: Double { get }
    var playbackState: DriveVideoPlaybackState { get }
    var isLandscapeVideo: Bool { get }
    var mediaType: DriveMediaType { get }

    func setup(directUrl url: String, taskKey: String, shouldPlayForCover: Bool)
    func setup(cacheUrl url: URL, shouldPlayForCover: Bool)
    func play()
    func stop()
    func pause()
    func seek(progress: Float, completion: ((Bool) -> Void)?)
    func removeTimeObserver()
    func close()
    func resume(_ url: String, taskKey: String)
    func addRemoteCommandObserverIfNeeded()
    func removeRemoteCommandObserverIfNeeded()
}

protocol DriveVideoPlayerDelegate: AnyObject {
    func videoPlayerDidFinish(_ videoEngine: DriveVideoPlayer)

    func videoPlayerPrepared(_ videoEngine: DriveVideoPlayer)

    func videoPlayerPlayFail(_ videoEngine: DriveVideoPlayer, error: Error?, localPath: URL?)

    func videoPlayer(_ videoPlayer: DriveVideoPlayer, playbackStateDidChanged playbackState: DriveVideoPlaybackState)

    func videoPlayer(_ videoPlayer: DriveVideoPlayer, loadStateDidChanged loadState: DriveVideoLoadState)

    func videoPlayer(_ videoPlayer: DriveVideoPlayer, currentPlaybackTime time: TimeInterval, duration: TimeInterval)
}

enum DriveVideoPlaybackState {
    case stopped
    case playing
    case paused
    case error
}

enum DriveVideoLoadState {
    case playable
    case stalled
    case unknown
    case error
}

enum DriveMediaType: String {
    case video
    case audio
    case unknown
}

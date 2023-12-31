//
//  MinutesVideoPlayer+VideoEngine.swift
//  Minutes
//
//  Created by lvdaqian on 2021/4/7.
//

import Foundation
import TTVideoEngine
import MinutesFoundation

extension MinutesVideoPlayer: TTVideoEngineDelegate {
    public func videoEngineUserStopped(_ videoEngine: TTVideoEngine) {
        MinutesLogger.video.info("videoEngineUserStopped")
    }

    public func videoEngineDidFinish(_ videoEngine: TTVideoEngine, error: Error?) {
        let playbackTime = videoEngine.currentPlaybackTime
        MinutesLogger.video.info("videoEngineDidFinish when \(playbackTime) with error: \(error)")
        shouldSavePlayTime = false
        resetPlayTime()
        if error != nil {
            replayFromStopping = { [weak self] in
                self?.videoEngine.setCurrentPlaybackTime(playbackTime) { _ in
                    self?.updateTime()
                }
            }
        }
        mediaInfoConfiguration()
        self.lastError = error
    }

    public func videoEngineDidFinish(_ videoEngine: TTVideoEngine, videoStatusException status: Int) {
        MinutesLogger.video.info("videoEngineUserStopped with status \(status)")
    }

    public func videoEngineCloseAysncFinish(_ videoEngine: TTVideoEngine) {
        MinutesLogger.video.info("videoEngineUserStopped")
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, playbackStateDidChanged playbackState: TTVideoEnginePlaybackState) {
        MinutesLogger.video.info("playbackStateDidChanged \(playbackState)")
        playerStatus = PlayerStatusWrapper(playbackState: playbackState,
                                    loadState: videoEngine.loadState)
        if currentPlayerStatus == .playing {
            _replayFromStopping()
            videoEngine.playbackSpeed = playbackSpeed
            if !hasLockPanel {
                configRemoteCommandCenter()
                hasLockPanel = true
            }
        }
        shouldSavePlayTime = true

        mediaInfoConfiguration()
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, loadStateDidChanged loadState: TTVideoEngineLoadState) {
        MinutesLogger.video.info("loadStateDidChanged \(loadState)")
        playerStatus = PlayerStatusWrapper(playbackState: videoEngine.playbackState,
                                    loadState: loadState)
    }

    public func videoEnginePrepared(_ videoEngine: TTVideoEngine) {
        MinutesLogger.video.info("videoEnginePrepared")
        playerStatus = PlayerStatusWrapper(playbackState: videoEngine.playbackState,
                                    loadState: videoEngine.loadState)
    }

    public func videoEngineReady(toPlay videoEngine: TTVideoEngine) {
        MinutesLogger.video.info("videoEngineReady toPlay")
        playerStatus = PlayerStatusWrapper(playbackState: videoEngine.playbackState,
                                    loadState: videoEngine.loadState)
    }

    public func videoEngineReady(toDisPlay videoEngine: TTVideoEngine) {
        MinutesLogger.video.info("videoEngineReady toDisPlay")
        playerStatus = PlayerStatusWrapper(playbackState: videoEngine.playbackState,
                                    loadState: videoEngine.loadState)
        loadPlayTime()
    }

    private func _replayFromStopping() {
        if let replay = replayFromStopping {
            replay()
            replayFromStopping = nil
        }
    }

}

extension MinutesVideoPlayer: TTVideoEngineDataSource {

}

extension TTVideoEnginePlaybackState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .error:
            return "error"
        case .paused:
            return "paused"
        case .playing:
            return "playing"
        case .stopped:
            return "stopped"
        }
    }
}

extension TTVideoEngineLoadState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .error:
            return "error"
        case .playable:
            return "playable"
        case .stalled:
            return "stalled"
        case .unknown:
            return "unkown"
        }
    }
}

//
//  MinutesVideoPlayer+remotecontrol.swift
//  Minutes
//
//  Created by lvdaqian on 2021/4/7.
//

import Foundation
import MediaPlayer
import MinutesFoundation
import MinutesNetwork

extension MinutesVideoPlayer {
    func configRemoteCommandCenter() {

        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        remoteCommandCenter.playCommand.addTarget(self, action: #selector(playCommand))
        remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(pauseCommand))
        remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(changePlaybackPositionCommand(event:)))

        remoteCommandCenter.skipForwardCommand.addTarget(self, action: #selector(skipForwardCommandHandler))
        // disable-lint: magic number
        remoteCommandCenter.skipForwardCommand.preferredIntervals = [15]
        remoteCommandCenter.skipBackwardCommand.addTarget(self, action: #selector(skipBackwardCommandHandler))
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [15]
        remoteCommandCenter.skipForwardCommand.isEnabled = !MinutesPodcast.shared.isInPodcast
        remoteCommandCenter.skipBackwardCommand.isEnabled = !MinutesPodcast.shared.isInPodcast
        // enable-lint: magic number
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.stopCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
    }

    func removeCommandCenterTarget() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.playCommand.removeTarget(nil)
        remoteCommandCenter.pauseCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(nil)
        remoteCommandCenter.skipBackwardCommand.removeTarget(nil)
        remoteCommandCenter.skipForwardCommand.removeTarget(nil)
    }

    func mediaInfoConfiguration() {

        let infos = minutes.info

        let title = infos.basicInfo?.topic
        let owner = infos.basicInfo?.ownerInfo?.userName
        let image = self.coverView.image

        if self.isAudioOnly {
            audioInfoConfiguration(title: title ?? "", owner: owner ?? "")
            return
        }
        DispatchQueue.main.async {
            var info: [String: Any] = Dictionary()
            info[MPMediaItemPropertyTitle] = title
            info[MPMediaItemPropertyArtist] = owner
            info[MPMediaItemPropertyPlaybackDuration] = self.duration

            info[MPNowPlayingInfoPropertyPlaybackRate] = self.currentPlayerStatus == .playing ? self.playbackSpeed : 0.0

            if  self.shouldSavePlayTime {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentPlaybackTime.time
            } else {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            }
            let artWork = MPMediaItemArtwork(boundsSize: image?.size ?? CGSize(width: 0, height: 0), requestHandler: { (_) -> UIImage in
                return (image ?? UIImage())
            })
            info[MPMediaItemPropertyArtwork] = artWork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    func audioInfoConfiguration(title: String, owner: String) {
        DispatchQueue.main.async {
            var info: [String: Any] = Dictionary()
            info[MPMediaItemPropertyTitle] = title
            info[MPMediaItemPropertyArtist] = owner
            info[MPMediaItemPropertyPlaybackDuration] = self.duration

            info[MPNowPlayingInfoPropertyPlaybackRate] = self.currentPlayerStatus == .playing ? self.playbackSpeed : 0.0

            if  self.shouldSavePlayTime {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentPlaybackTime.time
            } else {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    @objc
    func playCommand() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.video.info("remote command play.")
        play()
        mediaInfoConfiguration()
        return .success
    }

    @objc
    func pauseCommand() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.video.info("remote command pause.")
        pause()
        mediaInfoConfiguration()
        return .success
    }

    @objc
    func changePlaybackPositionCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let seconds = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime ?? 0

        MinutesLogger.video.info("remote command change play back posisiton to \(seconds).")
        seekVideoPlaybackTime(seconds)
        mediaInfoConfiguration()
        return .success
    }

    @objc func skipForwardCommandHandler() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.video.info("remote command skip forward.")
        let curTime = self.currentPlaybackTime.time
        // disable-lint: magic number
        let nextTime = curTime + 15
        if nextTime < self.duration {
            seekVideoPlaybackTime(nextTime)
        } else {
            seekVideoPlaybackTime(self.duration - 0.001)
        }
        // enable-lint: magic number
        mediaInfoConfiguration()
        tracker.tracker(name: .detailClick, params: ["click": "fifteen_secs_forward", "page_name": "background_mode"])
        return .success
    }

    @objc func skipBackwardCommandHandler() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.video.info("remote command skip backward.")
        let curTime = self.currentPlaybackTime.time
        // disable-lint: magic number
        let nextTime = curTime - 15
        if nextTime > 0 {
            seekVideoPlaybackTime(nextTime)
        } else {
            seekVideoPlaybackTime(0)
        }
        // enable-lint: magic number
        mediaInfoConfiguration()
        tracker.tracker(name: .detailClick, params: ["click": "fifteen_secs_back", "page_name": "background_mode"])
        return .success
    }
}

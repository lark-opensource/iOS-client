//
//  FavoriteAudioMessageViewModel.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import RxSwift
import LarkCore
import LKCommonsLogging
import LarkAudio
import LarkMessengerInterface
import EENavigator

enum FavoriteAudioStatus {
    case ready
    case pause(TimeInterval)
    case playing(TimeInterval)
}

final class FavoriteAudioMessageViewModel: FavoriteMessageViewModel {

    enum DownloadState {
        case none
        case loading
        case finish
    }

    static let logger: Log = Logger.log(FavoriteAudioMessageViewModel.self, category: "favorite.list.cell.view.model")

    override var identifier: String {
        return FavoriteAudioMessageViewModel.defaultIdentifier
    }

    class var defaultIdentifier: String {
        return String(describing: FavoriteAudioMessageViewModel.self)
    }

    var time: TimeInterval = 0

    var messageContent: AudioContent? {
        return self.message.content as? AudioContent
    }

    private(set) var audioWaves: [AudioProcessWave]?
    private(set) var downloadState: DownloadState = .none

    public override func updateContent(_ content: FavoriteContent) {
        super.updateContent(content)
        self.time = TimeInterval((self.messageContent?.duration ?? 0) / 1000)
    }

    func playOrPauseAudio(in from: NavigatorFrom?) {
        let audioPlayer = self.dataProvider.audioPlayer
        guard let audioKey = self.messageContent?.key,
            !audioKey.isEmpty else {
                return
        }

        if audioPlayer.isPlaying(key: audioKey) {
            audioPlayer.pausePlayingAudio()
        } else {
            audioPlayer.playAudioWith(keys: [.init(audioKey, self.messageContent?.authToken)], downloadFileScene: .favorite, from: from)
        }
    }

    func audioPlayStatus() -> FavoriteAudioStatus {
        let audioPlayer = self.dataProvider.audioPlayer
        guard let audioKey = self.messageContent?.key,
            !audioKey.isEmpty else {
                return .ready
        }

        var status: FavoriteAudioStatus = .ready

        switch audioPlayer.status {
        case .default:
            break
        case let .pause(progress):
            if progress.key == audioKey {
                status = .pause(progress.key == audioKey ? progress.current : 0)
            }
        case let .playing(progress):
            if progress.key == audioKey {
                status = .playing(progress.key == audioKey ? progress.current : 0)
            }
        case .loading:
            break
        @unknown default:
            assert(false, "new value")
            break
        }

        return status
    }

    func audioPlayStatusSignal() -> Observable<FavoriteAudioStatus> {
        let audioPlayer = self.dataProvider.audioPlayer
        guard (self.messageContent?.key) != nil else { return Observable<FavoriteAudioStatus>.empty() }
        return Observable.merge(
            audioPlayer.statusSignal
                .map({ [weak self] (_) -> FavoriteAudioStatus in
                    if let status = self?.audioPlayStatus() {
                        return status
                    }
                    return .ready
                })
        )
    }

    func updateStatus(_ status: AudioPlayMediatorStatus) {
        let audioPlayer = self.dataProvider.audioPlayer
        audioPlayer.updateStatus(status)
    }

    // nolint: duplicated_code
    public func downloadAudioIfNeeded() {
        guard let content = self.messageContent else { return }
        if self.downloadState != .none { return }
        self.downloadState = .loading
        let duration = content.duration
        self.dataProvider.audioResourceService.fetch(key: content.key, authToken: content.authToken, downloadFileScene: .favorite) { [weak self] (error, audioResource) in
            guard let `self` = self else { return }
            if audioResource == nil || error != nil {
                FavoriteAudioMessageViewModel.logger.error("download audio failed", additionalData: ["key": content.key], error: error)
                self.downloadState = .none
            } else {
                self.downloadState = .finish
                if let audio = audioResource {
                    self.audioWaves = AudioProcessView.waves(
                        data: audio.data,
                        duration: TimeInterval(duration / 1000)
                    )
                }
            }
        }
    }
    // enable-lint: duplicated_code

    override public var needAuthority: Bool {
        return false
    }
}

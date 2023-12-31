//
//  FlagAudioMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel
import RxSwift
import LarkCore
import LKCommonsLogging
import LarkAudio
import LarkMessengerInterface
import EENavigator

enum FlagAudioStatus {
    case ready
    case pause(TimeInterval)
    case playing(TimeInterval)
}

final class FlagAudioMessageViewModel: FlagMessageCellViewModel {

    enum DownloadState {
        case none
        case loading
        case finish
    }

    static let logger: Log = Logger.log(FlagAudioMessageViewModel.self, category: "flag.list.cell.view.model")

    override var identifier: String {
        return FlagAudioMessageViewModel.defaultIdentifier
    }

    class var defaultIdentifier: String {
        return String(describing: FlagAudioMessageViewModel.self)
    }

    var time: TimeInterval = 0

    var messageContent: AudioContent? {
        return self.message.content as? AudioContent
    }

    private(set) var audioWaves: [AudioProcessWave]?
    private(set) var downloadState: DownloadState = .none

    public override func updateContent(_ content: FlagContent) {
        super.updateContent(content)
        self.time = TimeInterval((self.messageContent?.duration ?? 0) / 1000)
    }

    func playOrPauseAudio(in from: NavigatorFrom?) {
        guard let audioPlayer = self.dataDependency.audioPlayer,
              let audioKey = self.messageContent?.key,
              !audioKey.isEmpty else {
                return
        }

        if audioPlayer.isPlaying(key: audioKey) {
            audioPlayer.pausePlayingAudio()
        } else {
            audioPlayer.playAudioWith(keys: [.init(audioKey, self.messageContent?.authToken)], downloadFileScene: .favorite, from: from)
        }
    }

    func audioPlayStatus() -> FlagAudioStatus {

        guard let audioPlayer = self.dataDependency.audioPlayer,
              let audioKey = self.messageContent?.key,
              !audioKey.isEmpty else {
                return .ready
        }

        var status: FlagAudioStatus = .ready

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

    func audioPlayStatusSignal() -> Observable<FlagAudioStatus> {
        guard let audioPlayer = self.dataDependency.audioPlayer, (self.messageContent?.key) != nil else { return Observable<FlagAudioStatus>.empty() }
        return Observable.merge(
            audioPlayer.statusSignal
                .map({ [weak self] (_) -> FlagAudioStatus in
                    if let status = self?.audioPlayStatus() {
                        return status
                    }
                    return .ready
                })
        )
    }

    func updateStatus(_ status: AudioPlayMediatorStatus) {
        let audioPlayer = self.dataDependency.audioPlayer
        audioPlayer?.updateStatus(status)
    }

    public func downloadAudioIfNeeded() {
        guard let content = self.messageContent else { return }
        if self.downloadState != .none { return }
        self.downloadState = .loading
        let duration = content.duration
        self.dataDependency.audioResourceService?.fetch(key: content.key, authToken: content.authToken, downloadFileScene: .favorite) { [weak self] (error, audioResource) in
            guard let `self` = self else { return }
            if audioResource == nil || error != nil {
                FlagAudioMessageViewModel.logger.error("download audio failed", additionalData: ["key": content.key], error: error)
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

    override public var needAuthority: Bool {
        return false
    }
}

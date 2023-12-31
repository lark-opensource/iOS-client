//
//  AudioResourceManager.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/15.
//

import Foundation
import LarkAudio
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import RustPB

// 音频资源管理
final class AudioResourceManager {

    enum DownloadState {
        case none
        case loading
        case finish
    }

    private let audioService: AudioResourceService
    private let content: AudioContent?

    // data
    private(set) var audioWaves: [AudioProcessWave] = []

    private(set) var downloadState: DownloadState = .none

    init(message: Message, audioService: AudioResourceService) {
        self.content = message.content as? AudioContent
        self.audioService = audioService
    }

    func downloadAudioIfNeeded(downloadFileScene: RustPB.Media_V1_DownloadFileScene?, _ finished: (([AudioProcessWave]) -> Void)?) {
        guard let content = content else { return }
        if self.downloadState != .none { return }
        self.downloadState = .loading
        self.audioService.fetch(key: content.key, authToken: content.authToken, downloadFileScene: downloadFileScene) { [weak self] (_, audioResource) in
            guard let `self` = self else { return }
            if let audio = audioResource {
                self.audioWaves = AudioProcessView.waves(
                    data: audio.data,
                    duration: TimeInterval(content.duration) / 1000
                ) ?? []
                self.downloadState = .finish
                DispatchQueue.main.async {
                    finished?(self.audioWaves)
                }
            } else {
                self.downloadState = .none
            }
        }
    }
}

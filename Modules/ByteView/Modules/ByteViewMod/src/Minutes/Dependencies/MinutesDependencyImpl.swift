//
//  MinutesDependencyImpl.swift
//  LarkByteView
//
//  Created by kiri on 2021/6/30.
//

import Foundation
import ByteView
import ByteViewCommon
import MinutesInterface
import LarkContainer

final class MinutesDependencyImpl: MinutesDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private var audioRecordService: MinutesAudioRecordService? {
        do {
            return try userResolver.resolve(assert: MinutesAudioRecordService.self)
        } catch {
            Logger.dependency.error("resolve MinutesAudioRecordService failed, \(error)")
            return nil
        }
    }

    private var podcastService: MinutesPodcastService? {
        do {
            return try userResolver.resolve(assert: MinutesPodcastService.self)
        } catch {
            Logger.dependency.error("resolve MinutesPodcastService failed, \(error)")
            return nil
        }
    }

    var isAudioRecording: Bool {
        audioRecordService?.isRecording() ?? false
    }

    var isPodcastMode: Bool {
        podcastService?.isPodcast ?? false
    }

    func stopAudioRecording() {
        audioRecordService?.stopRecording()
    }

    func stopPodcast() {
        podcastService?.stopPodcast()
    }
}

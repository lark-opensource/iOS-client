//
//  MediaResourceOccupancyChecker.swift
//  ByteView
//
//  Created by lutingting on 2023/8/17.
//

import Foundation
import ByteViewUI

extension PrecheckBuilder {
    @discardableResult
    func checkMediaResourceOccupancy(isJoinMeeting: Bool) -> Self {
        checker(MediaResourceOccupancyChecker(isJoin: isJoinMeeting))
        return self
    }
}

final class MediaResourceOccupancyChecker: MeetingPrecheckable {

    let isJoin: Bool
    var nextChecker: MeetingPrecheckable?

    init(isJoin: Bool) {
        self.isJoin = isJoin
    }

    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        let minutes = context.service.minutes
        if minutes.isPodcastMode {
            Logger.precheck.info("current minutes is podcast, stop podcast")
            minutes.stopPodcast()
        }

        if minutes.isAudioRecording {
            Logger.precheck.info("current minutes is recording")

            ByteViewDialog.Builder()
                .colorTheme(.followSystem)
                .title(I18n.View_G_RecordingWillStopIfStartCall)
                .message(nil)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    completion(.failure(VCError.userCancelOperation))
                })
                .rightTitle(isJoin ? I18n.View_G_Join : I18n.View_G_StartMeeting)
                .rightHandler({ [weak self] _ in
                    minutes.stopAudioRecording()
                    Toast.show(I18n.View_G_AudioRecordingStopped)
                    if let self = self {
                        self.checkLive(context, completion: completion)
                    } else {
                        completion(.failure(VCError.unknown))
                    }
                })
                .show()
        } else {
            checkNextIfNeeded(context, completion: completion)
        }
    }

    private func checkLive(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        if context.service.live.isLiving {
            let liveService = context.service.live
            // 发起二次确认弹窗
            let title: String = I18n.View_G_WatchingLivestream
            let message: String = I18n.View_G_WatchingLivestreamInfo

            ByteViewDialog.Builder()
                .colorTheme(.followSystem)
                .title(title)
                .message(message)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    liveService.trackFloatWindow(isConfirm: false)
                    completion(.failure(VCError.userCancelOperation))
                })
                .rightTitle(I18n.View_G_ConfirmButton)
                .rightHandler({ [weak self] _ in
                    liveService.trackFloatWindow(isConfirm: true)
                    liveService.stopLive()
                    if let self = self {
                        self.checkNextIfNeeded(context, completion: completion)
                    } else {
                        completion(.failure(VCError.unknown))
                    }
                })
                .show()
        } else {
            checkNextIfNeeded(context, completion: completion)
        }
    }
}

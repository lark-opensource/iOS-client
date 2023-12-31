//
//  PushHandler.swift
//  LarkMinutes
//
//  Created by lvdaqian on 2021/2/3.
//

import Foundation
import LarkRustClient
import Swinject
import ServerPB
import LKCommonsLogging
import MinutesFoundation
import MinutesNetwork
import SwiftProtobuf
import Minutes

public final class MinutesCCMCommentPushHandler: UserPushHandler {

    static let logger = Logger.log(MinutesCCMCommentPushHandler.self, category: "Minutes")
    public func process(push message: ServerPB_Meeting_object_MeetingObjectV2) throws {
        Self.logger.info("recived message \(message.baseInfo.objectToken.suffix(6))")
        let token = message.baseInfo.objectToken

        if let minutes = MinutesInstanceRegistry.shared.findMinutes(for: token) {
            let reaction = message.reaction
            let commentsInfo = reaction.comments.mapValues({ ParagraphCommentsInfoV2($0) })
            let subtitles = reaction.subtitles.mapValues({ Paragraph($0) })
            let info = CommonCommentResponseV2(comments: commentsInfo, subtitles: subtitles)
            minutes.data.updateNewCommentsInfo(info)
        }
    }
}

public final class MinutesOnlinePushHandler: UserPushHandler {

    static let logger = Logger.log(MinutesOnlinePushHandler.self, category: "Minutes")

    public func process(push message: ServerPB_Meeting_object_MeetingObject) throws {
        Self.logger.info("recived message \(message.baseInfo.objectToken.suffix(6))")

        let token = message.baseInfo.objectToken

        if let minutes = MinutesInstanceRegistry.shared.findMinutes(for: token) {
            let reaction = message.reaction
            let commentsInfo = reaction.comments.mapValues({ ParagraphCommentsInfo($0) })
            let subtitles = reaction.subtitles.mapValues({ Paragraph($0) })
            let info = CommonCommentResponse(comments: commentsInfo, subtitles: subtitles)
            let reactionInfo = reaction.timeline.map { ReactionInfo($0) }
            minutes.data.updateCommentsInfo(info)
            minutes.data.updateReactionInfo(reactionInfo)
        }
    }

}

public final class MinutesSummaryPushHandler: UserPushHandler {
    static let logger = Logger.log(MinutesSummaryPushHandler.self, category: "Minutes")

    public func process(push message: ServerPB_Meeting_object_MeetingObject) throws {
        Self.logger.info("recived message \(message.baseInfo.objectToken.suffix(6))")

        let token = message.baseInfo.objectToken
        NotificationCenter.default.post(name: Notification.minutesSummaryContentUpdated,
                                        object: nil,
                                        userInfo: [Notification.MinutesSummary.objectToken: token])
    }
}

public final class MinutesRealTimePushHandler: UserPushHandler {

    static let logger = Logger.log(MinutesRealTimePushHandler.self, category: "Minutes")

    public func process(push message: ServerPB_Meeting_object_RealTimeSubtitleSentence) throws {
        Self.logger.info("real time push \(message.baseInfo.objectToken.suffix(6)),lang: \(message.language), pid: \(message.pid), sid: \(message.sid), isFinal: \(message.isFinal) ")

        let token = message.baseInfo.objectToken
        if let minutes = MinutesInstanceRegistry.shared.findMinutes(for: token) {
            let contents = message.contents.map { Content($0) }
            if let data = minutes.translateData {
                data.updateParagraphData(pid: message.pid, sid: message.sid, language: message.language, startTime: message.startTime, stopTime: message.stopTime, contents: contents, isFinal: message.isFinal, filterSpeaker: false)
            }

            minutes.data.updateParagraphData(pid: message.pid, sid: message.sid, language: message.language, startTime: message.startTime, stopTime: message.stopTime, contents: contents, isFinal: message.isFinal, filterSpeaker: false)
        }
    }

}

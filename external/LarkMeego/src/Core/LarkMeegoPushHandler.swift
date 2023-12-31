//
//  LarkMeegoPushHandler.swift
//  MeegoMod
//
//  Created by ByteDance on 2022/7/23.
//

import Foundation
import SwiftProtobuf
import LKCommonsTracker
import LarkRustClient
import LarkMeegoPush
import LarkContainer
import LarkMeegoLogger

final class LarkMeegoPushHandler: UserPushHandler {
    func process(push payload: Data) throws {
        // 默认不分发推送信息，FG控制灰度范围。
        let shouldDispatchPushMessage = FeatureGating.get(by: FeatureGating.enableDispatchPushMessage, userResolver: userResolver)

        MeegoLogger.info("LarkMeegoPushHandler recv push msg to process.")

        guard shouldDispatchPushMessage else {
            MeegoLogger.warn("LarkMeegoPushHandler processMessage returned for FG lark.meego.push_data is false.")
            return
        }

        if let message = decode(payload: payload) {
            MeegoPushNativeService.dispatchPush(meegoPushMsg: message, payload: payload)
            trackPushMessageArrive(with: message)
        }
    }

    func decode(payload: Data) -> Meego_MeegoPushMessage? {
        do {
            return try Meego_MeegoPushMessage(serializedData: payload, options: self.discardUnknownFieldsOption)
        } catch {
            SimpleRustClient.logger.warn("[Meego Native]Rust push decode fafil-LarkMeegoPushHandler", error: error)
            trackMeegoPushMessageDecodeFail(error)
        }
        return nil
    }

    var discardUnknownFieldsOption: BinaryDecodingOptions = {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        return options
    }()
}

private extension LarkMeegoPushHandler {
    func trackPushMessageArrive(with message: Meego_MeegoPushMessage) {
        let arriveTimestamp = Date().timeIntervalSince1970
        let slardarEvent = SlardarEvent(
            name: "meego_push_message_arrive",
            metric: ["cost": arriveTimestamp - Double(message.timestamp)],
            category: ["topic_type": message.topicType],
            extra: ["trace_id": message.traceID,
                    "timestamp": message.timestamp,
                    "arrive_time": arriveTimestamp,
                    "topic_name": message.topicName
                   ]
        )
        Tracker.post(slardarEvent)
    }

    func trackMeegoPushMessageDecodeFail(_ error: Error) {
        let slardarEvent = SlardarEvent(
            name: "meego_push_pb_error",
            metric: [:],
            category: [:],
            extra: ["meego_push_pb_error": error.localizedDescription]
        )
        Tracker.post(slardarEvent)
    }
}

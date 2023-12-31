//
//  LarkSendMessageTracker.swift
//  LarkSendMessage
//
//  Created by Bytedance on 2022/10/18.
//

import Foundation
import LarkModel // Message
import LKCommonsTracker // Tracker
import Homeric // MESSAGE_SENT
import RustPB // Basic_V1_RichText

final class LarkSendMessageTracker {
    enum State: Int {
        case success = 1, failure
    }

    static func trackEndSendMessage(message: LarkModel.Message) {
        var length: Int64 = 0
        if let textContent = message.content as? TextContent {
            length = Int64(textContent.text.count)
        } else if let postContent = message.content as? PostContent {
            length = Int64(postContent.text.count)
        }
        guard let duration = Tracker.end(token: message.cid) else {
            return
        }
        Tracker.post(TeaEvent(
            "perf_send_msg",
            category: "performance",
            params: ["send_start_time": Int64(duration.start),
                     "send_end_time": Int64(duration.end),
                     "send_state": getMessageState(message).rawValue,
                     "msg_type": message.type.rawValue,
                     "msg_length": length
            ])
        )
    }

    private static func getMessageState(_ message: LarkModel.Message) -> State {
        var state: State = .success
        switch message.localStatus {
        case .success:
            state = .success
        case .fail:
            state = .failure
        default:
            break
        }
        return state
    }

    //发送单个文件结束
    static func trackAttachedFileSendFinish(isSuccess: Bool, fileType: String, fileSize: Int) {
        let statusString = isSuccess ? "success" : "fail"
        Tracker.post(TeaEvent(
            "send_attach_file_finish",
             category: "driver",
             params: [
                "status": statusString,
                "file_type": fileType,
                "file_size": fileSize
            ])
        )
    }

    /// track send message
    ///
    /// - Parameter token: message's cid
    static func trackStartSendMessage(token: String) {
        Tracker.start(token: token)
    }

    static func trackSendMessage(
        _ message: LarkModel.Message,
        chat: LarkModel.Chat,
        messageSummerize: (Message) -> String,
        isSupportURLType: (URL) -> (Bool, type: String, token: String),
        chatFromWhere: String?) {
        var params: [String: Any] = [
            "chatid": chat.id,
            "message_type": message.type.rawValue,
            "cid": message.cid,
            "chat_type": chat.type.rawValue,
            "notice": message.trackAtType
        ]
        params.merge(chat.trackTypeInfo, uniquingKeysWith: { (first, _) in first })

        if message.type == .text {
            params["message_length"] = messageSummerize(message).count
        } else if message.type == .post {
            params["message_length"] = messageSummerize(message).count
        }

        params["is_has_docslink"] = "false"
        var richText: RustPB.Basic_V1_RichText?
        if message.type == .text,
            let content = message.content as? TextContent {
            richText = content.richText
        } else if message.type == .post,
            let content = message.content as? PostContent {
            richText = content.richText
        }
        if let richText = richText {
            params["richtext_image_count"] = richText.imageIds.count
            let emotions = richText.elements.values.filter({ $0.tag == .emotion })
            params["emoji_type"] = emotions.map { $0.property.emotion.key }
            params["emoji_count"] = emotions.count

            var docsCount = 0
            for element in richText.elements.values {
                guard element.tag == .a else { continue }
                let text = element.property.anchor.content
                guard let url = URL(string: text) else { continue }
                let result = isSupportURLType(url)
                if !result.0 { continue }
                params["is_has_docslink"] = "true"
                if docsCount == 0 {
                    params["file_type"] = result.type
                    params["file_id"] = result.token
                }
                docsCount += 1
            }
            params["doc_link_count"] = docsCount
        }

        if chat.chatMode == Chat.ChatMode.threadV2 {
            params["group_id"] = chat.id
        }
        Tracker.post(TeaEvent(Homeric.MESSAGE_SENT, category: "message", params: params, md5AllowList: ["file_id"]))
    }
}

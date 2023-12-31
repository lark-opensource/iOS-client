//
//  File.swift
//  LarkMessageCore
//
//  Created by zoujiayi on 2019/10/12.
//

import Foundation
import LarkCore
import LKCommonsTracker
import LarkModel

final class PostTracker {
    enum ChatType: String {
        case group
        case single
        case single_bot
        case mail
        case meeting
    }

    enum TypingLocation: String {
        case message_input
        case richtext_input
        case richtext_separate_input
        case mail_new
        case mail_reply
    }

    static func typingInputActive(isFirst: Bool, chatType: PostTracker.ChatType, location: TypingLocation) {
           Tracker.post(TeaEvent("message_typing", params: [
               "is_first": isFirst,
               "chat_type": chatType.rawValue,
               "location": location.rawValue
               ])
           )
       }

    static func trackSelectFace(chat: LarkModel.Chat, face: String) {
        let range = face.index(after: face.startIndex)..<face.index(before: face.endIndex)
        Tracker.post(TeaEvent("face_select", category: "face", params: [
            "chat_type": chat.trackType,
            "face_tag": "\(face[range])"
            ])
        )
    }
}

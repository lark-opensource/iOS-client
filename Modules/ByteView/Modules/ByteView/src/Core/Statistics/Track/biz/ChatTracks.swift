//
//  ChatTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class ChatTracks {

    private static let meetingChatBox = TrackEventName.vc_meeting_chat_box

    static func trackSendMessage() {
        VCTracker.post(name: meetingChatBox, params: [.action_name: "send_message"])
    }

    static func trackReaction(key: String, comboCount: Int = -1) {
        var params: TrackParams = [.action_name: "reaction", "reaction_type": key]
        if comboCount != -1 {
            params["reaction_times"] = comboCount
        }
        VCTracker.post(name: meetingChatBox, params: params)
    }
}

final class ChatTracksV2 {

    private static let reactionView = TrackEventName.vc_meeting_chat_reaction_view

    static func trackShowReactionView() {
        VCTracker.post(name: reactionView)
    }

}

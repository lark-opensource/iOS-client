//
//  Track.swift
//  ByteView
//
//  Created by kiri on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

extension MeetingType {
    var trackName: TrackEventName {
        switch self {
        case .call:
            return .vc_call_page_onthecall
        case .meet:
            return .vc_meeting_page_onthecall
        default:
            Logger.tracker.warn("MeetingType is \(self)!!! return none by default")
            return .none
        }
    }
}

enum TrackFromSource: String {
    case userList = "user_list"
    case toolBar = "tool_bar"
}

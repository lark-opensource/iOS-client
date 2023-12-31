//
//  CallOutBody.swift
//  ByteView
//
//  Created by zfpan on 2020/9/24.
//

import Foundation
import ByteViewMeeting

struct CallOutBody: RouteBody {
    static let pattern = "//client/videoconference/callout"
    let session: MeetingSession
}

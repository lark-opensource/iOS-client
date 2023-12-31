//
//  PreviewBody.swift
//
//
//  Created by yangyao on 2020/9/25.
//

import Foundation
import ByteViewMeeting

struct PreviewBody: RouteBody {
    static let pattern = "//client/videoconference/preview"

    let session: MeetingSession
    let joinParams: PreviewViewParams

    init(session: MeetingSession, params: PreviewViewParams) {
        self.session = session
        self.joinParams = params
    }
}

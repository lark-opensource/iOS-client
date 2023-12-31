//
//  CallInBody.swift
//  ByteView
//
//  Created by liuning.cn on 2020/9/27.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting

struct CallInBody: RouteBody {
    static let pattern = "//client/videoconference/callin"

    let session: MeetingSession
    let callInType: CallInType

    // 只有老的ringing和新的全屏才会用到，卡片直接走主端接口
    init(session: MeetingSession, callInType: CallInType) {
        self.session = session
        self.callInType = callInType
    }
}

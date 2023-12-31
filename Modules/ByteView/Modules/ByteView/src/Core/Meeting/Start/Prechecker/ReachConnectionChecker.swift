//
//  ReachConnectionChecker.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/7/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewMeeting

final class ReachConnectionChecker: MeetingPrecheckable {
    var nextChecker: MeetingPrecheckable?

    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        if ReachabilityUtil.isConnected {
            checkNextIfNeeded(context, completion: completion)
        } else {
            Toast.show(I18n.View_G_NoConnection)
            completion(.failure(VCError.badNetwork))
        }
    }
}

extension PrecheckBuilder {
    @discardableResult
    func checkReachConnection() -> Self {
        checker(ReachConnectionChecker())
        return self
    }
}

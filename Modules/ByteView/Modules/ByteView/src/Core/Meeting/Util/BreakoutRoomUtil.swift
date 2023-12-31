//
//  BreakoutRoomUtil.swift
//  ByteView
//
//  Created by kiri on 2021/4/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

struct BreakoutRoom {
    static let mainID = "1" // 服务端打包数据时将主会场的id都设为1，但不保证不遗漏，可能出现主会场id为空的情况，端上需要兜底
}

struct BreakoutRoomUtil {

    static func isMainRoom(_ breakoutRoomId: String) -> Bool {
        return breakoutRoomId.isEmpty || breakoutRoomId == BreakoutRoom.mainID
    }
}

extension Participant {
    var isInMainBreakoutRoom: Bool {
        BreakoutRoomUtil.isMainRoom(self.breakoutRoomId)
    }

    func isInBreakoutRoom(_ breakoutRoomId: String) -> Bool {
        if BreakoutRoomUtil.isMainRoom(breakoutRoomId) {
            return isInMainBreakoutRoom
        } else {
            return self.breakoutRoomId == breakoutRoomId
        }
    }
}

extension Array where Element == Participant {
    func breakoutRoomParticipants(_ breakoutRoomId: String) -> [Participant] {
        if BreakoutRoomUtil.isMainRoom(breakoutRoomId) {
            return filter { BreakoutRoomUtil.isMainRoom($0.breakoutRoomId) }
        } else {
            return filter { $0.breakoutRoomId == breakoutRoomId }
        }
    }

    func hasBreakoutRoomParticipants(_ breakoutRoomId: String) -> Bool {
        if BreakoutRoomUtil.isMainRoom(breakoutRoomId) {
            return contains { BreakoutRoomUtil.isMainRoom($0.breakoutRoomId) }
        } else {
            return contains { $0.breakoutRoomId == breakoutRoomId }
        }
    }
}

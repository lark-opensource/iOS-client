//
//  MeetingState.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/5/31.
//

import Foundation

public enum MeetingState: Int, Hashable, CaseIterable, Comparable {
    /// 起始状态
    case start
    /// 会前
    case preparing
    /// 拨号（createVideoChat)
    case dialing
    /// 拨号成功后呼叫
    case calling
    /// 响铃
    case ringing
    /// 会前等候室
    case prelobby
    /// 会中等候室
    case lobby
    /// 会中
    case onTheCall
    /// 结束
    case end

    public static func < (lhs: MeetingState, rhs: MeetingState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension MeetingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .start:
            return "start"
        case .preparing:
            return "preparing"
        case .dialing:
            return "dialing"
        case .calling:
            return "calling"
        case .ringing:
            return "ringing"
        case .prelobby:
            return "prelobby"
        case .lobby:
            return "lobby"
        case .onTheCall:
            return "onTheCall"
        case .end:
            return "end"
        }
    }
}

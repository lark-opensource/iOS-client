//
//  MeetingHeartbeatType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum MeetingHeartbeatType: Int, Hashable {
    case unknown // = 0
    case voip // = 1
    case vc // = 2
    case vclobby // = 3
    case sharebox // = 4
}

extension MeetingHeartbeatType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .voip:
            return "voip"
        case .vc:
            return "vc"
        case .vclobby:
            return "vclobby"
        case .sharebox:
            return "sharebox"
        }
    }
}

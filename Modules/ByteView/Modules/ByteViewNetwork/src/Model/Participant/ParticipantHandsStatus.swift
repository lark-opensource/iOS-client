//
//  ParticipantHandsStatus.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum ParticipantHandsStatus: Int, Hashable {
    /// 未知状态，向后兼容
    case unknown // = 0
    case putUp // = 1
    case putDown // = 2
    case approved // = 3
    case reject // = 4
    case noNeedPutUp // = 5
}

extension ParticipantHandsStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .putUp:
            return "putUp"
        case .putDown:
            return "putDown"
        case .approved:
            return "approved"
        case .reject:
            return "reject"
        case .noNeedPutUp:
            return "noNeedPutUp"
        }
    }
}

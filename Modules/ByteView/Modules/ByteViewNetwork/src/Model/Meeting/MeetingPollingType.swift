//
//  MeetingPollingType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_StartByteviewPollingRequest.ServiceType
public enum MeetingPollingType: Int {
    case calling = 1
    case ringing // = 2
}

extension MeetingPollingType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .calling:
            return "calling"
        case .ringing:
            return "ringing"
        }
    }
}

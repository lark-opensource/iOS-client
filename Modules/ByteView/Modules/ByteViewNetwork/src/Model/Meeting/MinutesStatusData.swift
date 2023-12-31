//
//  MinutesStatusData.swift
//  ByteViewNetwork
//
//  Created by wulv on 2021/12/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// - Videoconference_V1_MinutesStatusData
public struct MinutesStatusData: Equatable {

    public init(status: Status, seq: Int64) {
        self.status = status
        self.seq = seq
    }

    public enum Status: Int, Hashable {
        case unknown // = 0
        case `open` // = 1
        case close // = 2
    }

    public var status: Status

    public var seq: Int64
}

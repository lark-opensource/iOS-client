//
//  AudienceInfo.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/10/26.
//

import Foundation
import RustPB

/// Videoconference_V1_AudienceInfo
public struct AudienceInfo: Equatable {

    public init(audienceNum: Int32) {
        self.audienceNum = audienceNum
    }

    /// 网络研讨会观众人数
    public var audienceNum: Int32
}

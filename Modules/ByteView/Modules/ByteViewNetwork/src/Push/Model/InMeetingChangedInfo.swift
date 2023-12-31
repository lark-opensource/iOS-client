//
//  InMeetingChangedInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 会议变化通知
/// - PUSH_MEETING_CHANGED_INFO = 87104
/// - Videoconference_V1_InMeetingChangedInfo
public struct InMeetingChangedInfo {

    public var changes: [InMeetingData]
}

extension InMeetingChangedInfo: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_InMeetingChangedInfo
    init(pb: Videoconference_V1_InMeetingChangedInfo) {
        self.changes = pb.changes.compactMap({ try? InMeetingData(pb: $0) })
    }
}

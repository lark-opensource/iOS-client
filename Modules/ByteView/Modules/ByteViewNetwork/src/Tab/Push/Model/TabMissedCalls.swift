//
//  TabTotalMissedCallInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// VC-Tab红点数据推送
/// - NOTIFY_VC_TAB_MISSED_CALLS = 89211
/// - ServerPB_Videochat_tab_v2_VCTabTotalMissedCallInfo
public struct TabMissedCallInfo {

    public var totalMissedCalls: Int64

    public var confirmedMissedCalls: Int64
}

extension TabMissedCallInfo: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_VCTabTotalMissedCallInfo

    init(pb: ServerPB_Videochat_tab_v2_VCTabTotalMissedCallInfo) {
        self.totalMissedCalls = pb.totalMissedCalls
        self.confirmedMissedCalls = pb.confirmedMissedCalls
    }
}

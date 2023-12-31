//
//  TabMissedCallConfirmRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 独立tab上报未接来电已读计数
/// - VC_TAB_MISSED_CALL_CONFIRM = 89207
/// - ServerPB_Videochat_tab_v2_VCTabMissedCallConfirmRequest
public struct TabMissedCallConfirmRequest {
    public static let command: NetworkCommand = .server(.vcTabMissedCallConfirm)

    public init(confirmedMissedCalls: Int64) {
        self.confirmedMissedCalls = confirmedMissedCalls
    }

    public var confirmedMissedCalls: Int64
}

extension TabMissedCallConfirmRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_VCTabMissedCallConfirmRequest
    func toProtobuf() throws -> ServerPB_Videochat_tab_v2_VCTabMissedCallConfirmRequest {
        var request = ProtobufType()
        request.confirmedMissedCalls = confirmedMissedCalls
        return request
    }
}

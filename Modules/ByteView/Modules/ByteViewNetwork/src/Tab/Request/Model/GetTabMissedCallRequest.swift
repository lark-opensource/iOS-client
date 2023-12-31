//
//  GetTabTotalMissedCallRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// App 启动，以及长连断开后恢复时主动获取独立tab整体未接计数
/// - GET_VC_TAB_TOTAL_MISSED_CALL = 89206
/// - ServerPB_Videochat_tab_v2_GetVCTabTotalMissedCallRequest
public struct GetTabMissedCallRequest {
    public static let command: NetworkCommand = .server(.getVcTabTotalMissedCall)
    public typealias Response = GetTabMissedCallResponse

    public init() {}
}

/// - ServerPB_Videochat_tab_v2_GetVCTabTotalMissedCallResponse
public struct GetTabMissedCallResponse {
    public var info: TabMissedCallInfo
}

extension GetTabMissedCallRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_GetVCTabTotalMissedCallRequest
    func toProtobuf() throws -> ServerPB_Videochat_tab_v2_GetVCTabTotalMissedCallRequest {
        ProtobufType()
    }
}

extension GetTabMissedCallResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_GetVCTabTotalMissedCallResponse
    init(pb: ServerPB_Videochat_tab_v2_GetVCTabTotalMissedCallResponse) throws {
        self.info = TabMissedCallInfo(pb: pb.info)
    }
}

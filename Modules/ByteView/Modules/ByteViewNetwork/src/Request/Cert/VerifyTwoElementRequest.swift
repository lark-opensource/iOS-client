//
//  VerifyTwoElementRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 二要素认证
/// - LIVE_MEETING_VERIFY_TWO_ELEMENT
/// - ServerPB_Videochat_VerifyTwoElementRequest
public struct VerifyTwoElementRequest {
    public static let command: NetworkCommand = .server(.liveMeetingVerifyTwoElement)

    public init(appId: Int32, scene: String, identityCode: String, identityName: String) {
        self.appId = appId
        self.scene = scene
        self.identityCode = identityCode
        self.identityName = identityName
    }

    public var appId: Int32

    public var scene: String

    public var identityCode: String

    public var identityName: String

    public let identityType: Int32 = IdentityType.identityCard

    private enum IdentityType {
        static let identityCard: Int32 = 1
    }
}

extension VerifyTwoElementRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_VerifyTwoElementRequest
    func toProtobuf() throws -> ServerPB_Videochat_VerifyTwoElementRequest {
        var request = ProtobufType()
        request.appID = appId
        request.scene = scene
        request.identityCode = identityCode
        request.identityName = identityName
        request.identityType = identityType
        return request
    }
}

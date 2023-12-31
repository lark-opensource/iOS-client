//
//  GetAuthChattersResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Contact_V2_GetAuthChattersRequest
public struct GetAuthChattersRequest {
    public static let command: NetworkCommand = .rust(.getAuthChatters)
    public typealias Response = GetAuthChattersResponse

    public init(authInfo: [String: String]) {
        self.authInfo = authInfo
    }

    ///key:userID 客体userID, value:当前用户与客体user所在的单聊的chatID (用于安全校验)
    public var authInfo: [String: String]
}

/// Contact_V2_GetAuthChattersResponse
public struct GetAuthChattersResponse {

    public var authResult: ChattersAuthResult

    /// Basic_V1_Auth_ChattersAuthResult
    public struct ChattersAuthResult {

        /// key: chatterID(被选择方), value: 取值 Reason 代表没有通过权限校验的原因
        public var deniedReasons: [String: AuthDeniedReason]
    }

    /// 没有通过权限的原因
    /// - Basic_V1_Auth_DeniedReason
    public enum AuthDeniedReason: Int, Hashable {
        case unknown // = 0
        case beBlocked // = 1
        case crossTenantDeny // = 2
        case sameTenantDeny // = 3
        case cryptoChatDeny // = 4
        case blocked // = 5
        case noFriendship // = 6
        case privacySetting // = 7
        case targetPrivacySetting // = 8

        ///私密日历
        case privateCalendar // = 9

        ///主体被外部协作管控
        case externalCoordinateCtl // = 10

        ///客体被外部协作管控
        case targetExternalCoordinateCtl // = 11
    }
}

extension GetAuthChattersRequest: RustRequestWithResponse {
    typealias ProtobufType = Contact_V2_GetAuthChattersRequest
    func toProtobuf() throws -> Contact_V2_GetAuthChattersRequest {
        var request = ProtobufType()
        request.actionType = .shareMessageSelectUser
        request.chattersAuthInfo = authInfo
        return request
    }
}

extension GetAuthChattersResponse: RustResponse {
    typealias ProtobufType = Contact_V2_GetAuthChattersResponse
    init(pb: Contact_V2_GetAuthChattersResponse) throws {
        let reasons = pb.authResult.deniedReasons.mapValues {
            AuthDeniedReason(rawValue: $0.rawValue) ?? .unknown
        }
        self.authResult = ChattersAuthResult(deniedReasons: reasons)
    }
}

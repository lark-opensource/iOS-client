//   
//   GetLiveProviderInfoRequest.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/2/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import Foundation
import ServerPB

/// 获取直播供应商信息
/// - GET_LIVE_PROVIDER_INFO = 200047
/// - ServerPB_Videochat_live_GetLiveProviderInfoRequest
public struct GetLiveProviderInfoRequest {
    public static var command: NetworkCommand = .server(.getLiveProviderInfo)
    public typealias Response = GetLiveProviderInfoResponse
    public init(meetingId: String) {
        self.meetingId = meetingId
    }
    public var meetingId: String
}

extension GetLiveProviderInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_live_GetLiveProviderInfoRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}

/// ServerPB_Videochat_live_GetLiveProviderInfoResponse
public struct GetLiveProviderInfoResponse {
    public var hasLarkLive: Bool
    public var byteLiveInfo: ByteLiveInfo
    public var userInfo: UserInfo
    public var liveSettings: LiveSettings
    public var isOversea: Bool

    /// ServerPB_Videochat_live_ByteLiveInfo
    public struct ByteLiveInfo: Equatable {
        public var hasByteLive: Bool
        public var isVersionExpired: Bool
        public var isPackageExpired: Bool
        public var hasByteLiveAppPermission: Bool
        public var unionId: String
        public var tenantKey: String
        public var byteLiveAccountId: String
        public var byteLiveSubAccountId: String
        public var consoleUrl: String
        public var byteLivePrivacyPolicyUrl: String
        /// 应用市场-企业直播页面链接
        public var byteLiveAppURL: String
        public var needApplyCreateSubAccount: Bool
        /// 机器人链接 https://applink.feishu.cn/client/bot/open?appId=cli_9e44bc233da9500d
        public var byteLiveBotApplink: String

        init(pb: ServerPB_Videochat_live_ByteLiveInfo) {
            hasByteLive = pb.hasByteLive_p
            isVersionExpired = pb.isVersionExpired
            isPackageExpired = pb.isPackageExpired
            hasByteLiveAppPermission = pb.hasByteLiveAppPermission_p
            unionId = pb.unionID
            tenantKey = pb.tenantKey
            byteLiveAccountId = pb.byteLiveAccountID
            byteLiveSubAccountId = pb.byteLiveSubAccountID
            consoleUrl = pb.consoleURL
            byteLivePrivacyPolicyUrl = pb.byteLivePrivacyPolicyURL
            byteLiveAppURL = pb.byteLiveAppURL
            needApplyCreateSubAccount = pb.needApplyCreateSubAccount
            byteLiveBotApplink = pb.byteLiveBotApplink
        }
    }

    /// ServerPB_Videochat_live_GetLiveProviderInfoResponse.UserInfo
    public struct UserInfo: Equatable {
        public var role: ByteLiveUserRole
        public var isByteLiveCreatorSameWithUser: Bool

        init(pb: ServerPB_Videochat_live_GetLiveProviderInfoResponse.UserInfo) {
            role = ByteLiveUserRole(rawValue: pb.role.rawValue) ?? .unknow
            isByteLiveCreatorSameWithUser = pb.isByteLiveCreatorSameWithUser
        }
    }

    /// ServerPB_Videochat_live_GetLiveProviderInfoResponse.LiveSettings
    public struct LiveSettings: Equatable {
        public var liveBrand: LiveBrand
        public var liveHistory: LiveHistory
        public var isLiving: Bool

        init(pb: ServerPB_Videochat_live_GetLiveProviderInfoResponse.LiveSettings) {
            liveBrand = LiveBrand(rawValue: pb.liveBrand.rawValue) ?? .unknow
            liveHistory = LiveHistory(rawValue: pb.liveHistory.rawValue) ?? .unknow
            isLiving = pb.isLiving
        }
    }

    /// ServerPB_Videochat_live_LiveHistory
    public enum LiveHistory: Int, Hashable {
        case unknow // = 0
        case notCreated // = 1
        case notStarted // = 2
        case createAndHasStarted // = 3
    }

    /// ServerPB_Videochat_live_ByteLiveUserRole
    public enum ByteLiveUserRole: Int, Hashable {
        case unknow // = 0
        case normal // = 1
        case admin // = 2
    }
}

extension GetLiveProviderInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_live_GetLiveProviderInfoResponse
    init(pb: ProtobufType) throws {
        hasLarkLive = pb.hasLarkLive_p
        byteLiveInfo = ByteLiveInfo(pb: pb.byteLiveInfo)
        userInfo = UserInfo(pb: pb.userInfo)
        liveSettings = LiveSettings(pb: pb.liveSettings)
        isOversea = pb.isOversea
    }
}

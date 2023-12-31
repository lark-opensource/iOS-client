//   
//   ByteLiveConfigForMeeting.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/2/27.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import Foundation
import ServerPB

/// ServerPB_Videochat_live_ByteLiveConfigForMeeting
public struct ByteLiveConfigForMeeting: Equatable {

    public var livePermission: LivePermissionByteLive
    public var layoutTypeSetting: LiveLayout
    public var liveUrl: String
    public var enableLiveComment: Bool
    public var activityId: Int64
    public var unionId: String
    public var tenantKey: String
    public var accountId: String
    public var subAccountId: String
    public var isLiving: Bool

    init(pb: ServerPB_Videochat_live_ByteLiveConfigForMeeting) {
        livePermission = LivePermissionByteLive(rawValue: pb.livePermission.rawValue) ?? .unknow
        layoutTypeSetting = LiveLayout(rawValue: pb.layoutTypeSetting.rawValue) ?? .unknown
        liveUrl = pb.liveURL
        enableLiveComment = pb.enableLiveComment
        activityId = pb.activityID
        unionId = pb.unionID
        tenantKey = pb.tenantKey
        accountId = pb.accountID
        subAccountId = pb.subAccountID
        isLiving = pb.isLiving
    }
}
